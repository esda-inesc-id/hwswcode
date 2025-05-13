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
   wire          internal_iob_valid;
   wire [ 2-1:0] internal_iob_addr;
   wire [32-1:0] internal_iob_wdata;
   wire [ 4-1:0] internal_iob_wstrb;
   wire          internal_iob_rvalid;
   wire [32-1:0] internal_iob_rdata;
   wire          internal_iob_ready;
   wire          internal_iob_rready;



   // Directly connect cbus IOb port to internal IOb wires
   assign internal_iob_valid  = iob_valid_i;
   assign internal_iob_addr   = iob_addr_i[3:2];  // Ignore 2 LSBs
   assign internal_iob_wdata  = iob_wdata_i;
   assign internal_iob_wstrb  = iob_wstrb_i;
   assign internal_iob_rready = iob_rready_i;
   assign iob_rvalid_o        = internal_iob_rvalid;
   assign iob_rdata_o         = internal_iob_rdata;
   assign iob_ready_o         = internal_iob_ready;


   // Unit Under Test (UUT) AXIL_MACC instance with 'iob' interface.
   iob_axil_macc axil_macc_inst (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i                (clk_i),
      .cke_i                (cke_i),
      .arst_i               (arst_i),
      // iob_csrs_cbus_s port: Control and Status Registers interface (auto-generated)
      .iob_csrs_iob_valid_i (internal_iob_valid),
      .iob_csrs_iob_addr_i  (internal_iob_addr),
      .iob_csrs_iob_wdata_i (internal_iob_wdata),
      .iob_csrs_iob_wstrb_i (internal_iob_wstrb),
      .iob_csrs_iob_rvalid_o(internal_iob_rvalid),
      .iob_csrs_iob_rdata_o (internal_iob_rdata),
      .iob_csrs_iob_ready_o (internal_iob_ready),
      .iob_csrs_iob_rready_i(internal_iob_rready)
   );


endmodule
