`timescale 1ns / 1ps
`include "iob_axil_macc_csrs_conf.vh"

module iob_axil_macc_csrs #(
   parameter ADDR_W = `IOB_AXIL_MACC_CSRS_ADDR_W,  // Don't change this parameter value!
   parameter DATA_W = `IOB_AXIL_MACC_CSRS_DATA_W
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
   // en_o: en register interface
   output                en_o,
   // done_i: done register interface
   input                 done_i,
   // load_o: load register interface
   output                load_o,
   // a_o: a register interface
   output [       8-1:0] a_o,
   // b_o: b register interface
   output [       8-1:0] b_o,
   // c_i: c register interface
   input  [      16-1:0] c_i
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
   wire                en_wdata;
   wire                en_wen;
   wire                load_wdata;
   wire                load_wen;
   wire [       8-1:0] a_wdata;
   wire                a_wen;
   wire [       8-1:0] b_wdata;
   wire                b_wen;
   wire                iob_rvalid_out;
   reg                 iob_rvalid_nxt;
   wire [      32-1:0] iob_rdata_out;
   reg  [      32-1:0] iob_rdata_nxt;
   wire                iob_ready_out;
   reg                 iob_ready_nxt;
   reg                 iob_addr_i_0_8;
   reg                 iob_addr_i_4_16;
   reg                 iob_addr_i_8_0;


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
   assign waddr    = `IOB_WORD_ADDR(internal_iob_addr_stable) + byte_offset;


   //NAME: en;
   //TYPE: W; WIDTH: 1; RST_VAL: 0; ADDR: 0; SPACE (bytes): 1 (max); AUTO: True

   assign en_wdata = internal_iob_wdata[0+:1];
   wire en_addressed_w;
   assign en_addressed_w = (waddr >= 0) && (waddr < 1);
   assign en_wen         = internal_iob_valid & (write_en & en_addressed_w);
   iob_reg_cae #(
      .DATA_W (1),
      .RST_VAL(1'd0)
   ) en_datareg (
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      .en_i  (en_wen),
      .data_i(en_wdata),
      .data_o(en_o)
   );



   //NAME: load;
   //TYPE: W; WIDTH: 1; RST_VAL: 0; ADDR: 2; SPACE (bytes): 1 (max); AUTO: True

   assign load_wdata = internal_iob_wdata[16+:1];
   wire load_addressed_w;
   assign load_addressed_w = (waddr >= 2) && (waddr < 3);
   assign load_wen         = internal_iob_valid & (write_en & load_addressed_w);
   iob_reg_cae #(
      .DATA_W (1),
      .RST_VAL(1'd0)
   ) load_datareg (
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      .en_i  (load_wen),
      .data_i(load_wdata),
      .data_o(load_o)
   );



   //NAME: a;
   //TYPE: W; WIDTH: 8; RST_VAL: 0; ADDR: 3; SPACE (bytes): 1 (max); AUTO: True

   assign a_wdata = internal_iob_wdata[24+:8];
   wire a_addressed_w;
   assign a_addressed_w = (waddr >= 3) && (waddr < 4);
   assign a_wen         = internal_iob_valid & (write_en & a_addressed_w);
   iob_reg_cae #(
      .DATA_W (8),
      .RST_VAL(8'd0)
   ) a_datareg (
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      .en_i  (a_wen),
      .data_i(a_wdata),
      .data_o(a_o)
   );



   //NAME: b;
   //TYPE: W; WIDTH: 8; RST_VAL: 0; ADDR: 4; SPACE (bytes): 1 (max); AUTO: True

   assign b_wdata = internal_iob_wdata[0+:8];
   wire b_addressed_w;
   assign b_addressed_w = (waddr >= 4) && (waddr < 5);
   assign b_wen         = internal_iob_valid & (write_en & b_addressed_w);
   iob_reg_cae #(
      .DATA_W (8),
      .RST_VAL(8'd0)
   ) b_datareg (
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      .en_i  (b_wen),
      .data_i(b_wdata),
      .data_o(b_o)
   );



   //NAME: done;
   //TYPE: R; WIDTH: 1; RST_VAL: 0; ADDR: 1; SPACE (bytes): 1 (max); AUTO: True



   //NAME: c;
   //TYPE: R; WIDTH: 16; RST_VAL: 0; ADDR: 6; SPACE (bytes): 2 (max); AUTO: True



   //NAME: version;
   //TYPE: R; WIDTH: 16; RST_VAL: 0081; ADDR: 8; SPACE (bytes): 2 (max); AUTO: True



   //RESPONSE SWITCH


   assign internal_iob_rvalid = iob_rvalid_out;
   assign internal_iob_rdata  = iob_rdata_out;
   assign internal_iob_ready  = iob_ready_out;

   wire [7:0] byte_aligned_done_i;
   assign byte_aligned_done_i = done_i;
   wire [15:0] byte_aligned_c_i;
   assign byte_aligned_c_i = c_i;

   always @* begin
      iob_rdata_nxt  = 32'd0;
      iob_addr_i_0_8 = (`IOB_WORD_ADDR(internal_iob_addr_stable) == 0);
      if (iob_addr_i_0_8) begin
         iob_rdata_nxt[8+:8] = byte_aligned_done_i | 8'd0;
      end

      iob_addr_i_4_16 = ((
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      >= 4) && (
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      < 8));
      if (iob_addr_i_4_16) begin
         iob_rdata_nxt[16+:16] = byte_aligned_c_i | 16'd0;
      end

      iob_addr_i_8_0 = (`IOB_WORD_ADDR(internal_iob_addr_stable) == 8);
      if (iob_addr_i_8_0) begin
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
