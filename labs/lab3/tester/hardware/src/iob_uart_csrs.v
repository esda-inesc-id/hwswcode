`timescale 1ns / 1ps
`include "iob_uart_csrs_conf.vh"

module iob_uart_csrs #(
   parameter ADDR_W = `IOB_UART_CSRS_ADDR_W,  // Don't change this parameter value!
   parameter DATA_W = `IOB_UART_CSRS_DATA_W
) (
   // clk_en_rst_s: Clock, clock enable and reset
   input                 clk_i,
   input                 cke_i,
   input                 arst_i,
   // control_if_s: CSR control interface. Interface type defined by `csr_if` parameter.
   input                 iob_valid_i,
   input                 iob_addr_i,
   input  [  DATA_W-1:0] iob_wdata_i,
   input  [DATA_W/8-1:0] iob_wstrb_i,
   output                iob_rvalid_o,
   output [  DATA_W-1:0] iob_rdata_o,
   output                iob_ready_o,
   input                 iob_rready_i,
   // softreset_o: softreset register interface
   output                softreset_o,
   // div_o: div register interface
   output [      16-1:0] div_o,
   // txdata_io: txdata register interface
   output [       8-1:0] txdata_wdata_o,
   output                txdata_wen_o,
   input                 txdata_ready_i,
   // txen_o: txen register interface
   output                txen_o,
   // rxen_o: rxen register interface
   output                rxen_o,
   // txready_i: txready register interface
   input                 txready_i,
   // rxready_i: rxready register interface
   input                 rxready_i,
   // rxdata_io: rxdata register interface
   input  [       8-1:0] rxdata_rdata_i,
   input                 rxdata_rvalid_i,
   output                rxdata_rready_o,
   output                rxdata_ren_o,
   input                 rxdata_ready_i
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
   reg                 rready_int;
   wire                softreset_wdata;
   wire                softreset_wen;
   wire [      16-1:0] div_wdata;
   wire                div_wen;
   wire [       8-1:0] txdata_wdata;
   wire                txen_wdata;
   wire                txen_wen;
   wire                rxen_wdata;
   wire                rxen_wen;
   wire                iob_rvalid_out;
   reg                 iob_rvalid_nxt;
   wire [      32-1:0] iob_rdata_out;
   reg  [      32-1:0] iob_rdata_nxt;
   wire                iob_ready_out;
   reg                 iob_ready_nxt;
   reg                 rvalid_int;
   reg                 ready_int;
   reg                 iob_addr_i_0_0;
   reg                 iob_addr_i_0_8;
   reg                 iob_addr_i_4_0;
   reg                 iob_addr_i_4_16;


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
   assign waddr           = `IOB_WORD_ADDR(internal_iob_addr_stable) + byte_offset;


   //NAME: softreset;
   //TYPE: W; WIDTH: 1; RST_VAL: 0; ADDR: 0; SPACE (bytes): 1 (max); AUTO: True

   assign softreset_wdata = internal_iob_wdata[0+:1];
   wire softreset_addressed_w;
   assign softreset_addressed_w = (waddr >= 0) && (waddr < 1);
   assign softreset_wen         = internal_iob_valid & (write_en & softreset_addressed_w);
   iob_reg_cae #(
      .DATA_W (1),
      .RST_VAL(1'd0)
   ) softreset_datareg (
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      .en_i  (softreset_wen),
      .data_i(softreset_wdata),
      .data_o(softreset_o)
   );



   //NAME: div;
   //TYPE: W; WIDTH: 16; RST_VAL: 0; ADDR: 2; SPACE (bytes): 2 (max); AUTO: True

   assign div_wdata = internal_iob_wdata[16+:16];
   wire div_addressed_w;
   assign div_addressed_w = (waddr >= 2) && (waddr < 4);
   assign div_wen         = internal_iob_valid & (write_en & div_addressed_w);
   iob_reg_cae #(
      .DATA_W (16),
      .RST_VAL(16'd0)
   ) div_datareg (
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      .en_i  (div_wen),
      .data_i(div_wdata),
      .data_o(div_o)
   );



   //NAME: txdata;
   //TYPE: W; WIDTH: 8; RST_VAL: 0; ADDR: 4; SPACE (bytes): 1 (max); AUTO: False

   assign txdata_wdata = internal_iob_wdata[0+:8];
   wire txdata_addressed_w;
   assign txdata_addressed_w = (waddr >= 4) && (waddr < 5);
   assign txdata_wen_o = (internal_iob_valid & internal_iob_ready) & (write_en & txdata_addressed_w);
   assign txdata_wdata_o = txdata_wdata;


   //NAME: txen;
   //TYPE: W; WIDTH: 1; RST_VAL: 0; ADDR: 5; SPACE (bytes): 1 (max); AUTO: True

   assign txen_wdata = internal_iob_wdata[8+:1];
   wire txen_addressed_w;
   assign txen_addressed_w = (waddr >= 5) && (waddr < 6);
   assign txen_wen         = internal_iob_valid & (write_en & txen_addressed_w);
   iob_reg_cae #(
      .DATA_W (1),
      .RST_VAL(1'd0)
   ) txen_datareg (
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      .en_i  (txen_wen),
      .data_i(txen_wdata),
      .data_o(txen_o)
   );



   //NAME: rxen;
   //TYPE: W; WIDTH: 1; RST_VAL: 0; ADDR: 6; SPACE (bytes): 1 (max); AUTO: True

   assign rxen_wdata = internal_iob_wdata[16+:1];
   wire rxen_addressed_w;
   assign rxen_addressed_w = (waddr >= 6) && (waddr < 7);
   assign rxen_wen         = internal_iob_valid & (write_en & rxen_addressed_w);
   iob_reg_cae #(
      .DATA_W (1),
      .RST_VAL(1'd0)
   ) rxen_datareg (
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      .en_i  (rxen_wen),
      .data_i(rxen_wdata),
      .data_o(rxen_o)
   );



   //NAME: txready;
   //TYPE: R; WIDTH: 1; RST_VAL: 0; ADDR: 0; SPACE (bytes): 1 (max); AUTO: True



   //NAME: rxready;
   //TYPE: R; WIDTH: 1; RST_VAL: 0; ADDR: 1; SPACE (bytes): 1 (max); AUTO: True



   //NAME: rxdata;
   //TYPE: R; WIDTH: 8; RST_VAL: 0; ADDR: 4; SPACE (bytes): 1 (max); AUTO: False

   wire rxdata_addressed_r;
   assign rxdata_addressed_r = (internal_iob_addr_stable >= 4) && (internal_iob_addr_stable < (4+(2**(0))));
   assign rxdata_ren_o = rxdata_addressed_r & (internal_iob_valid & internal_iob_ready) & (~write_en);
   assign rxdata_rready_o = rxdata_addressed_r & rready_int;


   //NAME: version;
   //TYPE: R; WIDTH: 16; RST_VAL: 0081; ADDR: 6; SPACE (bytes): 2 (max); AUTO: True



   //RESPONSE SWITCH


   assign internal_iob_rvalid = iob_rvalid_out;
   assign internal_iob_rdata = iob_rdata_out;
   assign internal_iob_ready = iob_ready_out;

   wire [7:0] byte_aligned_txready_i;
   assign byte_aligned_txready_i = txready_i;
   wire [7:0] byte_aligned_rxready_i;
   assign byte_aligned_rxready_i = rxready_i;
   wire [7:0] byte_aligned_rxdata_rdata_i;
   assign byte_aligned_rxdata_rdata_i = rxdata_rdata_i;

   always @* begin
      iob_rdata_nxt  = 32'd0;

      rvalid_int     = 1'b1;
      ready_int      = 1'b1;
      iob_addr_i_0_0 = (`IOB_WORD_ADDR(internal_iob_addr_stable) == 0);
      if (iob_addr_i_0_0) begin
         iob_rdata_nxt[0+:8] = byte_aligned_txready_i | 8'd0;
      end

      iob_addr_i_0_8 = (`IOB_WORD_ADDR(internal_iob_addr_stable) == 0);
      if (iob_addr_i_0_8) begin
         iob_rdata_nxt[8+:8] = byte_aligned_rxready_i | 8'd0;
      end

      iob_addr_i_4_0 = (`IOB_WORD_ADDR(internal_iob_addr_stable) == 4);
      if (iob_addr_i_4_0) begin

         iob_rdata_nxt[0+:8] = byte_aligned_rxdata_rdata_i | 8'd0;
         rvalid_int          = rxdata_rvalid_i;
         ready_int           = rxdata_ready_i;
      end

      iob_addr_i_4_16 = ((
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      >= 4) && (
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      < 8));
      if (iob_addr_i_4_16) begin
         iob_rdata_nxt[16+:16] = 16'h0081 | 16'd0;
      end

      if ((waddr >= 4) && (waddr < 5)) begin
         ready_int = txdata_ready_i;
      end


      // ######  FSM  #############

      //FSM default values
      iob_ready_nxt  = 1'b0;
      iob_rvalid_nxt = 1'b0;
      state_nxt      = state;

      rready_int     = 1'b0;


      //FSM state machine
      case (state)
         WAIT_REQ: begin
            if (internal_iob_valid & (!internal_iob_ready)) begin  // Wait for a valid request

               iob_ready_nxt = ready_int;

               // If is read and ready, go to WAIT_RVALID
               if (iob_ready_nxt && (!write_en)) begin
                  state_nxt = WAIT_RVALID;
               end
            end
         end

         default: begin  // WAIT_RVALID
            if (internal_iob_rready & internal_iob_rvalid) begin  // Transfer done

               rready_int     = 1'b1;

               iob_rvalid_nxt = 1'b0;
               state_nxt      = WAIT_REQ;
            end else begin

               iob_rvalid_nxt = rvalid_int;

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
