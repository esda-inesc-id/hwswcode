`timescale 1ns / 1ps
`include "iob_bootrom_csrs_conf.vh"

module iob_bootrom_csrs #(
   parameter ADDR_W    = `IOB_BOOTROM_CSRS_ADDR_W,    // Don't change this parameter value!
   parameter DATA_W    = `IOB_BOOTROM_CSRS_DATA_W,    // Don't change this parameter value!
   parameter AXI_ID_W  = `IOB_BOOTROM_CSRS_AXI_ID_W,
   parameter AXI_LEN_W = `IOB_BOOTROM_CSRS_AXI_LEN_W
) (
   // clk_en_rst_s: Clock, clock enable and reset
   input                                    clk_i,
   input                                    cke_i,
   input                                    arst_i,
   // control_if_s: CSR control interface. Interface type defined by `csr_if` parameter.
   input  [                         11-1:0] axi_araddr_i,
   input                                    axi_arvalid_i,
   output                                   axi_arready_o,
   output [                     DATA_W-1:0] axi_rdata_o,
   output [                          2-1:0] axi_rresp_o,
   output                                   axi_rvalid_o,
   input                                    axi_rready_i,
   input  [                   AXI_ID_W-1:0] axi_arid_i,
   input  [                  AXI_LEN_W-1:0] axi_arlen_i,
   input  [                          3-1:0] axi_arsize_i,
   input  [                          2-1:0] axi_arburst_i,
   input  [                          2-1:0] axi_arlock_i,
   input  [                          4-1:0] axi_arcache_i,
   input  [                          4-1:0] axi_arqos_i,
   output [                   AXI_ID_W-1:0] axi_rid_o,
   output                                   axi_rlast_o,
   input  [                         11-1:0] axi_awaddr_i,
   input                                    axi_awvalid_i,
   output                                   axi_awready_o,
   input  [                     DATA_W-1:0] axi_wdata_i,
   input  [                   DATA_W/8-1:0] axi_wstrb_i,
   input                                    axi_wvalid_i,
   output                                   axi_wready_o,
   output [                          2-1:0] axi_bresp_o,
   output                                   axi_bvalid_o,
   input                                    axi_bready_i,
   input  [                   AXI_ID_W-1:0] axi_awid_i,
   input  [                  AXI_LEN_W-1:0] axi_awlen_i,
   input  [                          3-1:0] axi_awsize_i,
   input  [                          2-1:0] axi_awburst_i,
   input  [                          2-1:0] axi_awlock_i,
   input  [                          4-1:0] axi_awcache_i,
   input  [                          4-1:0] axi_awqos_i,
   input                                    axi_wlast_i,
   output [                   AXI_ID_W-1:0] axi_bid_o,
   // rom_io: rom register interface
   output [                         10-1:0] rom_raddr_o,
   input  [((DATA_W > 1) ? DATA_W : 1)-1:0] rom_rdata_i,
   input                                    rom_rvalid_i,
   output                                   rom_rready_o,
   output                                   rom_ren_o,
   input                                    rom_ready_i
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
   wire                iob_rvalid_out;
   reg                 iob_rvalid_nxt;
   wire [      32-1:0] iob_rdata_out;
   reg  [      32-1:0] iob_rdata_nxt;
   wire                iob_ready_out;
   reg                 iob_ready_nxt;
   reg                 rvalid_int;
   reg                 ready_int;
   reg                 iob_addr_i_0_0;
   reg                 iob_addr_i_4096_0;


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


   //NAME: rom;
   //TYPE: R; WIDTH: DATA_W; RST_VAL: 0; ADDR: 0; SPACE (bytes): 4096 (max); AUTO: False

   wire rom_addressed_r;
   assign rom_addressed_r = (internal_iob_addr_stable >= 0) && (internal_iob_addr_stable < (0+(2**(12))));
   assign rom_ren_o = rom_addressed_r & (internal_iob_valid & internal_iob_ready) & (~write_en);
   assign rom_rready_o = rom_addressed_r & rready_int;


   //NAME: version;
   //TYPE: R; WIDTH: 16; RST_VAL: 0081; ADDR: 4096; SPACE (bytes): 2 (max); AUTO: True



   //RESPONSE SWITCH


   assign internal_iob_rvalid = iob_rvalid_out;
   assign internal_iob_rdata = iob_rdata_out;
   assign internal_iob_ready = iob_ready_out;

   wire [31:0] byte_aligned_rom_rdata_i;
   assign byte_aligned_rom_rdata_i = rom_rdata_i;

   always @* begin
      iob_rdata_nxt = 32'd0;

      rvalid_int = 1'b1;
      ready_int = 1'b1;
      iob_addr_i_0_0 = ((
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      >= 0) && (
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      < 4096));
      if (iob_addr_i_0_0) begin

         iob_rdata_nxt[0+:32] = byte_aligned_rom_rdata_i | 32'd0;
         rvalid_int           = rom_rvalid_i;
         ready_int            = rom_ready_i;
      end

      iob_addr_i_4096_0 = (`IOB_WORD_ADDR(internal_iob_addr_stable) == 4096);
      if (iob_addr_i_4096_0) begin
         iob_rdata_nxt[0+:16] = 16'h0081 | 16'd0;
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


   assign rom_raddr_o = internal_iob_addr_stable[ADDR_W-1:2] - 0;


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

   // Convert AXI port into internal IOb interface
   iob_axi2iob #(
      .ADDR_WIDTH   (ADDR_W),
      .DATA_WIDTH   (DATA_W),
      .AXI_ID_WIDTH (AXI_ID_W),
      .AXI_LEN_WIDTH(AXI_LEN_W)
   ) iob_axi2iob_coverter (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i          (clk_i),
      .cke_i          (cke_i),
      .arst_i         (arst_i),
      // axi_s port: Subordinate AXI interface
      .s_axi_araddr_i ({axi_araddr_i, 2'b0}),
      .s_axi_arvalid_i(axi_arvalid_i),
      .s_axi_arready_o(axi_arready_o),
      .s_axi_rdata_o  (axi_rdata_o),
      .s_axi_rresp_o  (axi_rresp_o),
      .s_axi_rvalid_o (axi_rvalid_o),
      .s_axi_rready_i (axi_rready_i),
      .s_axi_arid_i   (axi_arid_i),
      .s_axi_arlen_i  (axi_arlen_i),
      .s_axi_arsize_i (axi_arsize_i),
      .s_axi_arburst_i(axi_arburst_i),
      .s_axi_arlock_i (axi_arlock_i[0]),
      .s_axi_arcache_i(axi_arcache_i),
      .s_axi_arqos_i  (axi_arqos_i),
      .s_axi_rid_o    (axi_rid_o),
      .s_axi_rlast_o  (axi_rlast_o),
      .s_axi_awaddr_i ({axi_awaddr_i, 2'b0}),
      .s_axi_awvalid_i(axi_awvalid_i),
      .s_axi_awready_o(axi_awready_o),
      .s_axi_wdata_i  (axi_wdata_i),
      .s_axi_wstrb_i  (axi_wstrb_i),
      .s_axi_wvalid_i (axi_wvalid_i),
      .s_axi_wready_o (axi_wready_o),
      .s_axi_bresp_o  (axi_bresp_o),
      .s_axi_bvalid_o (axi_bvalid_o),
      .s_axi_bready_i (axi_bready_i),
      .s_axi_awid_i   (axi_awid_i),
      .s_axi_awlen_i  (axi_awlen_i),
      .s_axi_awsize_i (axi_awsize_i),
      .s_axi_awburst_i(axi_awburst_i),
      .s_axi_awlock_i (axi_awlock_i[0]),
      .s_axi_awcache_i(axi_awcache_i),
      .s_axi_awqos_i  (axi_awqos_i),
      .s_axi_wlast_i  (axi_wlast_i),
      .s_axi_bid_o    (axi_bid_o),
      // iob_m port: Manager IOb interface
      .iob_valid_o    (internal_iob_valid),
      .iob_addr_o     (internal_iob_addr),
      .iob_wdata_o    (internal_iob_wdata),
      .iob_wstrb_o    (internal_iob_wstrb),
      .iob_rvalid_i   (internal_iob_rvalid),
      .iob_rdata_i    (internal_iob_rdata),
      .iob_ready_i    (internal_iob_ready),
      .iob_rready_o   (internal_iob_rready)
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
