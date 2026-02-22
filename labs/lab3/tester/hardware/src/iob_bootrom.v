`timescale 1ns / 1ps
`include "iob_bootrom_conf.vh"

module iob_bootrom #(
   parameter DATA_W    = `IOB_BOOTROM_DATA_W,    // Don't change this parameter value!
   parameter ADDR_W    = `IOB_BOOTROM_ADDR_W,    // Don't change this parameter value!
   parameter AXI_ID_W  = `IOB_BOOTROM_AXI_ID_W,
   parameter AXI_LEN_W = `IOB_BOOTROM_AXI_LEN_W
) (
   // clk_en_rst_s: Clock and reset
   input                  clk_i,
   input                  cke_i,
   input                  arst_i,
   // ext_rom_bus_m: External ROM signals
   output                 ext_rom_clk_o,
   output [   ADDR_W-1:0] ext_rom_addr_o,
   output                 ext_rom_en_o,
   input  [   DATA_W-1:0] ext_rom_r_data_i,
   // iob_csrs_cbus_s: Control and Status Registers interface (auto-generated)
   input  [       11-1:0] iob_csrs_axi_araddr_i,
   input                  iob_csrs_axi_arvalid_i,
   output                 iob_csrs_axi_arready_o,
   output [   DATA_W-1:0] iob_csrs_axi_rdata_o,
   output [        2-1:0] iob_csrs_axi_rresp_o,
   output                 iob_csrs_axi_rvalid_o,
   input                  iob_csrs_axi_rready_i,
   input  [ AXI_ID_W-1:0] iob_csrs_axi_arid_i,
   input  [AXI_LEN_W-1:0] iob_csrs_axi_arlen_i,
   input  [        3-1:0] iob_csrs_axi_arsize_i,
   input  [        2-1:0] iob_csrs_axi_arburst_i,
   input  [        2-1:0] iob_csrs_axi_arlock_i,
   input  [        4-1:0] iob_csrs_axi_arcache_i,
   input  [        4-1:0] iob_csrs_axi_arqos_i,
   output [ AXI_ID_W-1:0] iob_csrs_axi_rid_o,
   output                 iob_csrs_axi_rlast_o,
   input  [       11-1:0] iob_csrs_axi_awaddr_i,
   input                  iob_csrs_axi_awvalid_i,
   output                 iob_csrs_axi_awready_o,
   input  [   DATA_W-1:0] iob_csrs_axi_wdata_i,
   input  [ DATA_W/8-1:0] iob_csrs_axi_wstrb_i,
   input                  iob_csrs_axi_wvalid_i,
   output                 iob_csrs_axi_wready_o,
   output [        2-1:0] iob_csrs_axi_bresp_o,
   output                 iob_csrs_axi_bvalid_o,
   input                  iob_csrs_axi_bready_i,
   input  [ AXI_ID_W-1:0] iob_csrs_axi_awid_i,
   input  [AXI_LEN_W-1:0] iob_csrs_axi_awlen_i,
   input  [        3-1:0] iob_csrs_axi_awsize_i,
   input  [        2-1:0] iob_csrs_axi_awburst_i,
   input  [        2-1:0] iob_csrs_axi_awlock_i,
   input  [        4-1:0] iob_csrs_axi_awcache_i,
   input  [        4-1:0] iob_csrs_axi_awqos_i,
   input                  iob_csrs_axi_wlast_i,
   output [ AXI_ID_W-1:0] iob_csrs_axi_bid_o
);

   // 'rom' register interface
   wire [    10-1:0] rom_raddr_rd;
   wire [DATA_W-1:0] rom_rdata_rd;
   wire              rom_rvalid_rd;
   wire              rom_rready_rd;
   wire              rom_ren_rd;
   wire              rom_ready_rd;


   assign ext_rom_clk_o  = clk_i;
   assign ext_rom_en_o   = rom_ren_rd;
   assign ext_rom_addr_o = rom_raddr_rd;
   assign rom_rdata_rd   = ext_rom_r_data_i;
   assign rom_ready_rd   = 1'b1;  // ROM is always ready


   // Default description
   iob_bootrom_csrs #(
      .AXI_ID_W (AXI_ID_W),
      .AXI_LEN_W(AXI_LEN_W)
   ) iob_csrs (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i        (clk_i),
      .cke_i        (cke_i),
      .arst_i       (arst_i),
      // control_if_s port: CSR control interface. Interface type defined by `csr_if` parameter.
      .axi_araddr_i (iob_csrs_axi_araddr_i),
      .axi_arvalid_i(iob_csrs_axi_arvalid_i),
      .axi_arready_o(iob_csrs_axi_arready_o),
      .axi_rdata_o  (iob_csrs_axi_rdata_o),
      .axi_rresp_o  (iob_csrs_axi_rresp_o),
      .axi_rvalid_o (iob_csrs_axi_rvalid_o),
      .axi_rready_i (iob_csrs_axi_rready_i),
      .axi_arid_i   (iob_csrs_axi_arid_i),
      .axi_arlen_i  (iob_csrs_axi_arlen_i),
      .axi_arsize_i (iob_csrs_axi_arsize_i),
      .axi_arburst_i(iob_csrs_axi_arburst_i),
      .axi_arlock_i (iob_csrs_axi_arlock_i),
      .axi_arcache_i(iob_csrs_axi_arcache_i),
      .axi_arqos_i  (iob_csrs_axi_arqos_i),
      .axi_rid_o    (iob_csrs_axi_rid_o),
      .axi_rlast_o  (iob_csrs_axi_rlast_o),
      .axi_awaddr_i (iob_csrs_axi_awaddr_i),
      .axi_awvalid_i(iob_csrs_axi_awvalid_i),
      .axi_awready_o(iob_csrs_axi_awready_o),
      .axi_wdata_i  (iob_csrs_axi_wdata_i),
      .axi_wstrb_i  (iob_csrs_axi_wstrb_i),
      .axi_wvalid_i (iob_csrs_axi_wvalid_i),
      .axi_wready_o (iob_csrs_axi_wready_o),
      .axi_bresp_o  (iob_csrs_axi_bresp_o),
      .axi_bvalid_o (iob_csrs_axi_bvalid_o),
      .axi_bready_i (iob_csrs_axi_bready_i),
      .axi_awid_i   (iob_csrs_axi_awid_i),
      .axi_awlen_i  (iob_csrs_axi_awlen_i),
      .axi_awsize_i (iob_csrs_axi_awsize_i),
      .axi_awburst_i(iob_csrs_axi_awburst_i),
      .axi_awlock_i (iob_csrs_axi_awlock_i),
      .axi_awcache_i(iob_csrs_axi_awcache_i),
      .axi_awqos_i  (iob_csrs_axi_awqos_i),
      .axi_wlast_i  (iob_csrs_axi_wlast_i),
      .axi_bid_o    (iob_csrs_axi_bid_o),
      // rom_io port: rom register interface
      .rom_raddr_o  (rom_raddr_rd),
      .rom_rdata_i  (rom_rdata_rd),
      .rom_rvalid_i (rom_rvalid_rd),
      .rom_rready_o (rom_rready_rd),
      .rom_ren_o    (rom_ren_rd),
      .rom_ready_i  (rom_ready_rd)
   );

   // ROM rvalid register
   iob_reg_ca #(
      .DATA_W (1),
      .RST_VAL(1'b0)
   ) rom_rvalid_r (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      // data_i port: Data input
      .data_i(rom_ren_rd),
      // data_o port: Data output
      .data_o(rom_rvalid_rd)
   );


endmodule
