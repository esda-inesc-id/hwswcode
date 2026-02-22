`timescale 1ns / 1ps
`include "iob_uut_conf.vh"

module iob_uut #(
   parameter DATA_W = `IOB_UUT_DATA_W
) (
   // clk_en_rst_s: Clock, clock enable and reset
   input           clk_i,
   input           cke_i,
   input           arst_i,
   // axil_macc_s: Testbench axil_macc csrs interface
   input           iob_valid_i,
   input  [ 4-1:0] iob_addr_i,
   input  [32-1:0] iob_wdata_i,
   input  [ 4-1:0] iob_wstrb_i,
   output          iob_rvalid_o,
   output [32-1:0] iob_rdata_o,
   output          iob_ready_o,
   input           iob_rready_i
);

   // Testbench axil_macc csrs bus
   wire [ 2-1:0] internal_axil_araddr;
   wire          internal_axil_arvalid;
   wire          internal_axil_arready;
   wire [32-1:0] internal_axil_rdata;
   wire [ 2-1:0] internal_axil_rresp;
   wire          internal_axil_rvalid;
   wire          internal_axil_rready;
   wire [ 2-1:0] internal_axil_awaddr;
   wire          internal_axil_awvalid;
   wire          internal_axil_awready;
   wire [32-1:0] internal_axil_wdata;
   wire [ 4-1:0] internal_axil_wstrb;
   wire          internal_axil_wvalid;
   wire          internal_axil_wready;
   wire [ 2-1:0] internal_axil_bresp;
   wire          internal_axil_bvalid;
   wire          internal_axil_bready;




   // Unit Under Test (UUT) AXIL_MACC instance with 'axil' interface.
   iob_axil_macc axil_macc_inst (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i                  (clk_i),
      .cke_i                  (cke_i),
      .arst_i                 (arst_i),
      // iob_csrs_cbus_s port: Control and Status Registers interface (auto-generated)
      .iob_csrs_axil_araddr_i (internal_axil_araddr),
      .iob_csrs_axil_arvalid_i(internal_axil_arvalid),
      .iob_csrs_axil_arready_o(internal_axil_arready),
      .iob_csrs_axil_rdata_o  (internal_axil_rdata),
      .iob_csrs_axil_rresp_o  (internal_axil_rresp),
      .iob_csrs_axil_rvalid_o (internal_axil_rvalid),
      .iob_csrs_axil_rready_i (internal_axil_rready),
      .iob_csrs_axil_awaddr_i (internal_axil_awaddr),
      .iob_csrs_axil_awvalid_i(internal_axil_awvalid),
      .iob_csrs_axil_awready_o(internal_axil_awready),
      .iob_csrs_axil_wdata_i  (internal_axil_wdata),
      .iob_csrs_axil_wstrb_i  (internal_axil_wstrb),
      .iob_csrs_axil_wvalid_i (internal_axil_wvalid),
      .iob_csrs_axil_wready_o (internal_axil_wready),
      .iob_csrs_axil_bresp_o  (internal_axil_bresp),
      .iob_csrs_axil_bvalid_o (internal_axil_bvalid),
      .iob_csrs_axil_bready_i (internal_axil_bready)
   );

   // Convert IOb port from testbench into AXI-Lite interface for AXIL_MACC CSRs bus
   iob_iob2axil #(
      .AXIL_ADDR_W(2),
      .AXIL_DATA_W(DATA_W)
   ) iob_iob2axil_coverter (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i         (clk_i),
      .cke_i         (cke_i),
      .arst_i        (arst_i),
      // iob_s port: Subordinate IOb interface
      .iob_valid_i   (iob_valid_i),
      .iob_addr_i    (iob_addr_i[3:2]),
      .iob_wdata_i   (iob_wdata_i),
      .iob_wstrb_i   (iob_wstrb_i),
      .iob_rvalid_o  (iob_rvalid_o),
      .iob_rdata_o   (iob_rdata_o),
      .iob_ready_o   (iob_ready_o),
      .iob_rready_i  (iob_rready_i),
      // axil_m port: Manager AXI Lite interface
      .axil_araddr_o (internal_axil_araddr),
      .axil_arvalid_o(internal_axil_arvalid),
      .axil_arready_i(internal_axil_arready),
      .axil_rdata_i  (internal_axil_rdata),
      .axil_rresp_i  (internal_axil_rresp),
      .axil_rvalid_i (internal_axil_rvalid),
      .axil_rready_o (internal_axil_rready),
      .axil_awaddr_o (internal_axil_awaddr),
      .axil_awvalid_o(internal_axil_awvalid),
      .axil_awready_i(internal_axil_awready),
      .axil_wdata_o  (internal_axil_wdata),
      .axil_wstrb_o  (internal_axil_wstrb),
      .axil_wvalid_o (internal_axil_wvalid),
      .axil_wready_i (internal_axil_wready),
      .axil_bresp_i  (internal_axil_bresp),
      .axil_bvalid_i (internal_axil_bvalid),
      .axil_bready_o (internal_axil_bready)
   );


endmodule
