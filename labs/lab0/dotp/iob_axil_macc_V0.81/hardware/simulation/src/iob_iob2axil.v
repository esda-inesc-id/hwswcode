// SPDX-FileCopyrightText: 2025 IObundle
//
// SPDX-License-Identifier: MIT

`timescale 1ns / 1ps
`include "iob_iob2axil_conf.vh"

module iob_iob2axil #(
   parameter AXIL_ADDR_W = `IOB_IOB2AXIL_AXIL_ADDR_W,
   parameter AXIL_DATA_W = `IOB_IOB2AXIL_AXIL_DATA_W,
   parameter ADDR_W      = `IOB_IOB2AXIL_ADDR_W,
   parameter DATA_W      = `IOB_IOB2AXIL_DATA_W
) (
   // clk_en_rst_s: Clock, clock enable and reset
   input                      clk_i,
   input                      cke_i,
   input                      arst_i,
   // iob_s: Subordinate IOb interface
   input                      iob_valid_i,
   input  [       ADDR_W-1:0] iob_addr_i,
   input  [       DATA_W-1:0] iob_wdata_i,
   input  [     DATA_W/8-1:0] iob_wstrb_i,
   output                     iob_rvalid_o,
   output [       DATA_W-1:0] iob_rdata_o,
   output                     iob_ready_o,
   input                      iob_rready_i,
   // axil_m: Manager AXI Lite interface
   output [  AXIL_ADDR_W-1:0] axil_araddr_o,
   output                     axil_arvalid_o,
   input                      axil_arready_i,
   input  [  AXIL_DATA_W-1:0] axil_rdata_i,
   input  [            2-1:0] axil_rresp_i,
   input                      axil_rvalid_i,
   output                     axil_rready_o,
   output [  AXIL_ADDR_W-1:0] axil_awaddr_o,
   output                     axil_awvalid_o,
   input                      axil_awready_i,
   output [  AXIL_DATA_W-1:0] axil_wdata_o,
   output [AXIL_DATA_W/8-1:0] axil_wstrb_o,
   output                     axil_wvalid_o,
   input                      axil_wready_i,
   input  [            2-1:0] axil_bresp_i,
   input                      axil_bvalid_i,
   output                     axil_bready_o
);

   localparam WAIT_AVALID = 3'd0;
   localparam WAIT_AWREADY = 3'd1;
   localparam WAIT_WREADY = 3'd2;
   localparam WAIT_BVALID = 3'd3;
   localparam WAIT_RVALID = 3'd4;

   reg  axil_awvalid_int;
   reg  axil_arvalid_int;
   reg  axil_wvalid_int;
   reg  axil_bready_int;
   reg  iob_ready_int;

   wire wen;
   assign wen            = |iob_wstrb_i;

   //
   // COMPUTE IOb OUTPUTS
   //
   assign iob_rvalid_o   = axil_rvalid_i;
   assign iob_rdata_o    = axil_rdata_i;
   assign iob_ready_o    = iob_ready_int;

   //
   // COMPUTE AXIL OUTPUTS
   //

   // write address
   assign axil_awvalid_o = axil_awvalid_int;
   assign axil_awaddr_o  = iob_addr_i;

   // write
   assign axil_wvalid_o  = axil_wvalid_int;
   assign axil_wdata_o   = iob_wdata_i;
   assign axil_wstrb_o   = iob_wstrb_i;

   // write response
   assign axil_bready_o  = axil_bready_int;

   // read address
   assign axil_arvalid_o = axil_arvalid_int;
   assign axil_araddr_o  = iob_addr_i;

   // read
   assign axil_rready_o  = iob_rready_i;

   //program counter
   wire [2:0] pc_cnt;
   reg  [2:0] pc_cnt_nxt;
   iob_reg_ca #(
      .DATA_W (3),
      .RST_VAL(3'd0)
   ) pc_reg (
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      .data_i(pc_cnt_nxt),
      .data_o(pc_cnt)
   );

   always @* begin

      pc_cnt_nxt       = pc_cnt;
      axil_awvalid_int = 1'b0;
      axil_arvalid_int = 1'b0;
      axil_wvalid_int  = 1'b0;
      axil_bready_int  = 1'b0;
      iob_ready_int    = 1'b0;

      case (pc_cnt)
         WAIT_AVALID: begin
            if (iob_valid_i) begin
               if (wen) begin
                  axil_awvalid_int = 1'b1;
                  axil_wvalid_int  = 1'b1;
                  axil_bready_int  = 1'b1;
                  pc_cnt_nxt       = WAIT_AWREADY;
               end else begin
                  axil_arvalid_int = 1'b1;
                  if (axil_arready_i) begin
                     iob_ready_int = 1'b1;
                     pc_cnt_nxt    = WAIT_RVALID;
                  end
               end
            end
         end
         WAIT_AWREADY: begin
            axil_awvalid_int = 1'b1;
            axil_wvalid_int  = 1'b1;
            axil_bready_int  = 1'b1;
            if (axil_awready_i & axil_wready_i) begin
               pc_cnt_nxt = WAIT_BVALID;
            end else if (axil_awready_i) begin
               pc_cnt_nxt = WAIT_WREADY;
            end
         end
         WAIT_WREADY: begin
            axil_wvalid_int = 1'b1;
            axil_bready_int = 1'b1;
            if (axil_wready_i) begin
               pc_cnt_nxt = WAIT_BVALID;
            end
         end
         WAIT_BVALID: begin
            axil_bready_int = 1'b1;
            if (axil_bvalid_i) begin
               pc_cnt_nxt    = WAIT_AVALID;
               iob_ready_int = 1'b1;
            end
         end
         WAIT_RVALID: begin
            if (axil_rvalid_i & iob_rready_i) begin
               pc_cnt_nxt = WAIT_AVALID;
            end
         end
         default: begin
            pc_cnt_nxt = WAIT_AVALID;
         end
      endcase
   end  // always @ *

endmodule
