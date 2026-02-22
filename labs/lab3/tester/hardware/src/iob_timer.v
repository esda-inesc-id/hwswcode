`timescale 1ns / 1ps
`include "iob_timer_conf.vh"

module iob_timer #(
   parameter DATA_W  = `IOB_TIMER_DATA_W,
   parameter WDATA_W = `IOB_TIMER_WDATA_W
) (
   // clk_en_rst_s: Clock, clock enable and reset
   input                 clk_i,
   input                 cke_i,
   input                 arst_i,
   // iob_csrs_cbus_s: Control and Status Registers interface (auto-generated)
   input                 iob_csrs_iob_valid_i,
   input  [       2-1:0] iob_csrs_iob_addr_i,
   input  [  DATA_W-1:0] iob_csrs_iob_wdata_i,
   input  [DATA_W/8-1:0] iob_csrs_iob_wstrb_i,
   output                iob_csrs_iob_rvalid_o,
   output [  DATA_W-1:0] iob_csrs_iob_rdata_o,
   output                iob_csrs_iob_ready_o,
   input                 iob_csrs_iob_rready_i
);

   wire          reset_wr;
   wire          enable_wr;
   wire          sample_wr;
   wire [32-1:0] data_low_rd;
   wire [32-1:0] data_high_rd;
   wire [64-1:0] time_now;


   assign data_low_rd  = time_now[DATA_W-1:0];
   assign data_high_rd = time_now[2*DATA_W-1:DATA_W];


   // Control/Status Registers
   iob_timer_csrs iob_csrs (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i       (clk_i),
      .cke_i       (cke_i),
      .arst_i      (arst_i),
      // control_if_s port: CSR control interface. Interface type defined by `csr_if` parameter.
      .iob_valid_i (iob_csrs_iob_valid_i),
      .iob_addr_i  (iob_csrs_iob_addr_i),
      .iob_wdata_i (iob_csrs_iob_wdata_i),
      .iob_wstrb_i (iob_csrs_iob_wstrb_i),
      .iob_rvalid_o(iob_csrs_iob_rvalid_o),
      .iob_rdata_o (iob_csrs_iob_rdata_o),
      .iob_ready_o (iob_csrs_iob_ready_o),
      .iob_rready_i(iob_csrs_iob_rready_i),
      // reset_o port: reset register interface
      .reset_o     (reset_wr),
      // enable_o port: enable register interface
      .enable_o    (enable_wr),
      // sample_o port: sample register interface
      .sample_o    (sample_wr),
      // data_low_i port: data_low register interface
      .data_low_i  (data_low_rd),
      // data_high_i port: data_high register interface
      .data_high_i (data_high_rd)
   );

   // Timer core driver
   iob_timer_core iob_timer_core_inst (
      // clk_en_rst_s port: Clock and reset
      .clk_i  (clk_i),
      .cke_i  (cke_i),
      .arst_i (arst_i),
      .en_i   (enable_wr),
      .rst_i  (reset_wr),
      .rstrb_i(sample_wr),
      .time_o (time_now)
   );


endmodule
