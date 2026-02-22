`timescale 1ns / 1ps
`include "iob_timer_csrs_conf.vh"

module iob_timer_csrs #(
   parameter ADDR_W  = `IOB_TIMER_CSRS_ADDR_W,  // Don't change this parameter value!
   parameter DATA_W  = `IOB_TIMER_CSRS_DATA_W,
   parameter WDATA_W = `IOB_TIMER_CSRS_WDATA_W
) (
   // clk_en_rst_s: Clock, clock enable and reset
   input                 clk_i,
   input                 cke_i,
   input                 arst_i,
   // control_if_s: CSR control interface. Interface type defined by `csr_if` parameter.
   input                 iob_valid_i,
   input  [       2-1:0] iob_addr_i,
   input  [  DATA_W-1:0] iob_wdata_i,
   input  [DATA_W/8-1:0] iob_wstrb_i,
   output                iob_rvalid_o,
   output [  DATA_W-1:0] iob_rdata_o,
   output                iob_ready_o,
   input                 iob_rready_i,
   // reset_o: reset register interface
   output                reset_o,
   // enable_o: enable register interface
   output                enable_o,
   // sample_o: sample register interface
   output                sample_o,
   // data_low_i: data_low register interface
   input  [      32-1:0] data_low_i,
   // data_high_i: data_high register interface
   input  [      32-1:0] data_high_i
);

   // Internal iob interface
   wire                internal_iob_valid;
   wire [  ADDR_W-1:0] internal_iob_addr;
   wire [  DATA_W-1:0] internal_iob_wdata;
   wire [DATA_W/8-1:0] internal_iob_wstrb;
   wire                internal_iob_rvalid;
   wire [  DATA_W-1:0] internal_iob_rdata;
   wire                internal_iob_ready;
   wire                internal_iob_rready;
   wire                state;
   reg                 state_nxt;
   wire                write_en;
   wire [  ADDR_W-1:0] internal_iob_addr_stable;
   wire [  ADDR_W-1:0] internal_iob_addr_reg;
   wire                internal_iob_addr_reg_en;
   wire                reset_wdata;
   wire                reset_wen;
   wire                enable_wdata;
   wire                enable_wen;
   wire                sample_wdata;
   wire                sample_wen;
   wire                iob_rvalid_out;
   reg                 iob_rvalid_nxt;
   wire [      32-1:0] iob_rdata_out;
   reg  [      32-1:0] iob_rdata_nxt;
   wire                iob_ready_out;
   reg                 iob_ready_nxt;
   reg                 iob_addr_i_4_0;
   reg                 iob_addr_i_8_0;
   reg                 iob_addr_i_12_0;


   // Include iob_functions for use in parameters
   // SPDX-FileCopyrightText: 2025 IObundle
   //
   // SPDX-License-Identifier: MIT

   function [31:0] iob_max;
      input [31:0] a;
      input [31:0] b;
      begin
         if (a > b) iob_max = a;
         else iob_max = b;
      end
   endfunction

   function [31:0] iob_min;
      input [31:0] a;
      input [31:0] b;
      begin
         if (a < b) iob_min = a;
         else iob_min = b;
      end
   endfunction

   function [31:0] iob_cshift_left;
      input [31:0] DATA;
      input integer DATA_W;
      input integer SHIFT;
      begin
         iob_cshift_left = (DATA << SHIFT) | (DATA >> (DATA_W - SHIFT));
      end
   endfunction

   function [31:0] iob_cshift_right;
      input [31:0] DATA;
      input integer DATA_W;
      input integer SHIFT;
      begin
         iob_cshift_right = (DATA >> SHIFT) | (DATA << (DATA_W - SHIFT));
      end
   endfunction
   `define IOB_NBYTES (DATA_W/8)
   `define IOB_NBYTES_W $clog2(`IOB_NBYTES)
   `define IOB_WORD_ADDR(ADDR) ((ADDR>>`IOB_NBYTES_W)<<`IOB_NBYTES_W)


   localparam WSTRB_W = DATA_W / 8;

   //FSM states
   localparam WAIT_REQ = 1'd0;
   localparam WAIT_RVALID = 1'd1;

   assign internal_iob_addr_reg_en = (state == WAIT_REQ);
   assign internal_iob_addr_stable = (state == WAIT_RVALID) ? internal_iob_addr_reg : internal_iob_addr;

   assign write_en = |internal_iob_wstrb;

   assign internal_iob_valid = iob_valid_i;
   assign internal_iob_addr = {iob_addr_i, 2'b0};
   assign internal_iob_wdata = iob_wdata_i;
   assign internal_iob_wstrb = iob_wstrb_i;
   assign internal_iob_rready = iob_rready_i;
   assign iob_rvalid_o = internal_iob_rvalid;
   assign iob_rdata_o = internal_iob_rdata;
   assign iob_ready_o = internal_iob_ready;

   //write address
   wire [($clog2(WSTRB_W)+1)-1:0] byte_offset;
   iob_ctls #(
      .W     (WSTRB_W),
      .MODE  (0),
      .SYMBOL(0)
   ) bo_inst (
      .data_i (internal_iob_wstrb),
      .count_o(byte_offset)
   );
   wire [ADDR_W-1:0] waddr;
   assign waddr       = `IOB_WORD_ADDR(internal_iob_addr_stable) + byte_offset;


   //NAME: reset;
   //TYPE: W; WIDTH: 1; RST_VAL: 0; ADDR: 0; SPACE (bytes): 1 (max); AUTO: True

   assign reset_wdata = internal_iob_wdata[0+:1];
   wire reset_addressed_w;
   assign reset_addressed_w = (waddr >= 0) && (waddr < 1);
   assign reset_wen         = internal_iob_valid & (write_en & reset_addressed_w);
   iob_reg_cae #(
      .DATA_W (1),
      .RST_VAL(1'd0)
   ) reset_datareg (
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      .en_i  (reset_wen),
      .data_i(reset_wdata),
      .data_o(reset_o)
   );



   //NAME: enable;
   //TYPE: W; WIDTH: 1; RST_VAL: 0; ADDR: 1; SPACE (bytes): 1 (max); AUTO: True

   assign enable_wdata = internal_iob_wdata[8+:1];
   wire enable_addressed_w;
   assign enable_addressed_w = (waddr >= 1) && (waddr < 2);
   assign enable_wen         = internal_iob_valid & (write_en & enable_addressed_w);
   iob_reg_cae #(
      .DATA_W (1),
      .RST_VAL(1'd0)
   ) enable_datareg (
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      .en_i  (enable_wen),
      .data_i(enable_wdata),
      .data_o(enable_o)
   );



   //NAME: sample;
   //TYPE: W; WIDTH: 1; RST_VAL: 0; ADDR: 2; SPACE (bytes): 1 (max); AUTO: True

   assign sample_wdata = internal_iob_wdata[16+:1];
   wire sample_addressed_w;
   assign sample_addressed_w = (waddr >= 2) && (waddr < 3);
   assign sample_wen         = internal_iob_valid & (write_en & sample_addressed_w);
   iob_reg_cae #(
      .DATA_W (1),
      .RST_VAL(1'd0)
   ) sample_datareg (
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      .en_i  (sample_wen),
      .data_i(sample_wdata),
      .data_o(sample_o)
   );



   //NAME: data_low;
   //TYPE: R; WIDTH: 32; RST_VAL: 0; ADDR: 4; SPACE (bytes): 4 (max); AUTO: True



   //NAME: data_high;
   //TYPE: R; WIDTH: 32; RST_VAL: 0; ADDR: 8; SPACE (bytes): 4 (max); AUTO: True



   //NAME: version;
   //TYPE: R; WIDTH: 16; RST_VAL: 0081; ADDR: 12; SPACE (bytes): 2 (max); AUTO: True



   //RESPONSE SWITCH


   assign internal_iob_rvalid = iob_rvalid_out;
   assign internal_iob_rdata  = iob_rdata_out;
   assign internal_iob_ready  = iob_ready_out;

   wire [31:0] byte_aligned_data_low_i;
   assign byte_aligned_data_low_i = data_low_i;
   wire [31:0] byte_aligned_data_high_i;
   assign byte_aligned_data_high_i = data_high_i;

   always @* begin
      iob_rdata_nxt = 32'd0;
      iob_addr_i_4_0 = ((
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      >= 4) && (
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      < 8));
      if (iob_addr_i_4_0) begin
         iob_rdata_nxt[0+:32] = byte_aligned_data_low_i | 32'd0;
      end

      iob_addr_i_8_0 = ((
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      >= 8) && (
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      < 12));
      if (iob_addr_i_8_0) begin
         iob_rdata_nxt[0+:32] = byte_aligned_data_high_i | 32'd0;
      end

      iob_addr_i_12_0 = (`IOB_WORD_ADDR(internal_iob_addr_stable) == 12);
      if (iob_addr_i_12_0) begin
         iob_rdata_nxt[0+:16] = 16'h0081 | 16'd0;
      end



      // ######  FSM  #############

      //FSM default values
      iob_ready_nxt  = 1'b0;
      iob_rvalid_nxt = 1'b0;
      state_nxt      = state;


      //FSM state machine
      case (state)
         WAIT_REQ: begin
            if (internal_iob_valid & (!internal_iob_ready)) begin  // Wait for a valid request

               iob_ready_nxt = 1'b1;

               // If is read and ready, go to WAIT_RVALID
               if (iob_ready_nxt && (!write_en)) begin
                  state_nxt = WAIT_RVALID;
               end
            end
         end

         default: begin  // WAIT_RVALID
            if (internal_iob_rready & internal_iob_rvalid) begin  // Transfer done

               iob_rvalid_nxt = 1'b0;
               state_nxt      = WAIT_REQ;
            end else begin

               iob_rvalid_nxt = 1'b1;

            end
         end
      endcase

   end  //always @*



        // store iob addr
   iob_reg_cae #(
      .DATA_W (ADDR_W),
      .RST_VAL({ADDR_W{1'b0}})
   ) internal_addr_reg (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      .en_i  (internal_iob_addr_reg_en),
      // data_i port: Data input
      .data_i(internal_iob_addr),
      // data_o port: Data output
      .data_o(internal_iob_addr_reg)
   );

   // state register
   iob_reg_ca #(
      .DATA_W (1),
      .RST_VAL(1'b0)
   ) state_reg (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      // data_i port: Data input
      .data_i(state_nxt),
      // data_o port: Data output
      .data_o(state)
   );

   // rvalid register
   iob_reg_ca #(
      .DATA_W (1),
      .RST_VAL(1'b0)
   ) rvalid_reg (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      // data_i port: Data input
      .data_i(iob_rvalid_nxt),
      // data_o port: Data output
      .data_o(iob_rvalid_out)
   );

   // rdata register
   iob_reg_ca #(
      .DATA_W (32),
      .RST_VAL(32'b0)
   ) rdata_reg (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      // data_i port: Data input
      .data_i(iob_rdata_nxt),
      // data_o port: Data output
      .data_o(iob_rdata_out)
   );

   // ready register
   iob_reg_ca #(
      .DATA_W (1),
      .RST_VAL(1'b0)
   ) ready_reg (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      // data_i port: Data input
      .data_i(iob_ready_nxt),
      // data_o port: Data output
      .data_o(iob_ready_out)
   );


endmodule
