`timescale 1ns / 1ps
`include "iob_uut_conf.vh"

module iob_uut #(
   parameter AXI_ID_W   = `IOB_UUT_AXI_ID_W,    // Don't change this parameter value!
   parameter AXI_LEN_W  = `IOB_UUT_AXI_LEN_W,   // Don't change this parameter value!
   parameter AXI_ADDR_W = `IOB_UUT_AXI_ADDR_W,  // Don't change this parameter value!
   parameter AXI_DATA_W = `IOB_UUT_AXI_DATA_W,  // Don't change this parameter value!
   parameter BAUD       = `IOB_UUT_BAUD,        // Don't change this parameter value!
   parameter FREQ       = `IOB_UUT_FREQ,        // Don't change this parameter value!
   parameter SIMULATION = `IOB_UUT_SIMULATION   // Don't change this parameter value!
) (
   // clk_en_rst_s: Clock, clock enable and reset
   input           clk_i,
   input           cke_i,
   input           arst_i,
   // uart_s: Testbench uart csrs interface
   input           iob_valid_i,
   input  [ 3-1:0] iob_addr_i,
   input  [32-1:0] iob_wdata_i,
   input  [ 4-1:0] iob_wstrb_i,
   output          iob_rvalid_o,
   output [32-1:0] iob_rdata_o,
   output          iob_ready_o,
   input           iob_rready_i
);

   // rs232 bus
   wire rs232_rxd;
   wire rs232_txd;
   wire rs232_rts;
   wire rs232_cts;

   // IOb-SoC memory wrapper
   iob_axil_macc_tester_mwrap #(
      .AXI_ID_W  (AXI_ID_W),
      .AXI_LEN_W (AXI_LEN_W),
      .AXI_ADDR_W(AXI_ADDR_W),
      .AXI_DATA_W(AXI_DATA_W)
   ) iob_memwrapper (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i      (clk_i),
      .cke_i      (cke_i),
      .arst_i     (arst_i),
      // rs232_m port: iob-system uart interface
      .rs232_rxd_i(rs232_rxd),
      .rs232_txd_o(rs232_txd),
      .rs232_rts_o(rs232_rts),
      .rs232_cts_i(rs232_cts)
   );

   // Testbench uart core
   iob_uart uart_tb (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i                (clk_i),
      .cke_i                (cke_i),
      .arst_i               (arst_i),
      // rs232_m port: RS232 interface
      .rs232_rxd_i          (rs232_txd),
      .rs232_txd_o          (rs232_rxd),
      .rs232_rts_o          (rs232_cts),
      .rs232_cts_i          (rs232_rts),
      // iob_csrs_cbus_s port: Control and Status Registers interface (auto-generated)
      .iob_csrs_iob_valid_i (iob_valid_i),
      .iob_csrs_iob_addr_i  (iob_addr_i[3-1:2]),
      .iob_csrs_iob_wdata_i (iob_wdata_i),
      .iob_csrs_iob_wstrb_i (iob_wstrb_i),
      .iob_csrs_iob_rvalid_o(iob_rvalid_o),
      .iob_csrs_iob_rdata_o (iob_rdata_o),
      .iob_csrs_iob_ready_o (iob_ready_o),
      .iob_csrs_iob_rready_i(iob_rready_i)
   );


endmodule
