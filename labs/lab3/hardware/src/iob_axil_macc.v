`timescale 1ns / 1ps
`include "iob_axil_macc_conf.vh"

module iob_axil_macc #(
   parameter DATA_W = `IOB_AXIL_MACC_DATA_W
) (
   // clk_en_rst_s: Clock, clock enable and reset
   input                 clk_i,
   input                 cke_i,
   input                 arst_i,
   // iob_csrs_cbus_s: Control and Status Registers interface (auto-generated)
   input  [       2-1:0] iob_csrs_axil_araddr_i,
   input                 iob_csrs_axil_arvalid_i,
   output                iob_csrs_axil_arready_o,
   output [  DATA_W-1:0] iob_csrs_axil_rdata_o,
   output [       2-1:0] iob_csrs_axil_rresp_o,
   output                iob_csrs_axil_rvalid_o,
   input                 iob_csrs_axil_rready_i,
   input  [       2-1:0] iob_csrs_axil_awaddr_i,
   input                 iob_csrs_axil_awvalid_i,
   output                iob_csrs_axil_awready_o,
   input  [  DATA_W-1:0] iob_csrs_axil_wdata_i,
   input  [DATA_W/8-1:0] iob_csrs_axil_wstrb_i,
   input                 iob_csrs_axil_wvalid_i,
   output                iob_csrs_axil_wready_o,
   output [       2-1:0] iob_csrs_axil_bresp_o,
   output                iob_csrs_axil_bvalid_o,
   input                 iob_csrs_axil_bready_i
);

   // Enable
   wire          en;
   // Enable
   reg           enp;
   // Enable internal
   wire          en_int;
   // Load
   wire          load;
   // operand a
   wire [ 8-1:0] a;
   // operand b
   wire [ 8-1:0] b;
   // Multiplier reg 1
   wire [16-1:0] mul1;
   // Multiplier reg 2
   wire [16-1:0] mul2;
   // Accumulator
   wire [16-1:0] acc;
   // Done
   wire [ 3-1:0] done;
   // Done internal
   wire          done_int;
   reg           en_int_nxt;
   reg  [16-1:0] mul1_nxt;
   reg  [16-1:0] mul2_nxt;
   reg  [16-1:0] acc_nxt;
   reg  [ 3-1:0] done_nxt;
   reg           done_int_nxt;

   always @(*) begin

      mul1_nxt     = a * b;
      mul2_nxt     = mul1;
      en_int_nxt   = en;
      enp          = en & ~en_int;
      acc_nxt      = done[2] ? (load ? mul2 : mul2 + acc) : acc;
      done_nxt     = {done[1], done[0], enp};
      done_int_nxt = enp ? 1'b0 : (done[2] | done_int);

   end

   // Control/Status Registers
   iob_axil_macc_csrs iob_csrs (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i         (clk_i),
      .cke_i         (cke_i),
      .arst_i        (arst_i),
      // control_if_s port: CSR control interface. Interface type defined by `csr_if` parameter.
      .axil_araddr_i (iob_csrs_axil_araddr_i),
      .axil_arvalid_i(iob_csrs_axil_arvalid_i),
      .axil_arready_o(iob_csrs_axil_arready_o),
      .axil_rdata_o  (iob_csrs_axil_rdata_o),
      .axil_rresp_o  (iob_csrs_axil_rresp_o),
      .axil_rvalid_o (iob_csrs_axil_rvalid_o),
      .axil_rready_i (iob_csrs_axil_rready_i),
      .axil_awaddr_i (iob_csrs_axil_awaddr_i),
      .axil_awvalid_i(iob_csrs_axil_awvalid_i),
      .axil_awready_o(iob_csrs_axil_awready_o),
      .axil_wdata_i  (iob_csrs_axil_wdata_i),
      .axil_wstrb_i  (iob_csrs_axil_wstrb_i),
      .axil_wvalid_i (iob_csrs_axil_wvalid_i),
      .axil_wready_o (iob_csrs_axil_wready_o),
      .axil_bresp_o  (iob_csrs_axil_bresp_o),
      .axil_bvalid_o (iob_csrs_axil_bvalid_o),
      .axil_bready_i (iob_csrs_axil_bready_i),
      // en_o port: en register interface
      .en_o          (en),
      // done_i port: done register interface
      .done_i        (done_int),
      // load_o port: load register interface
      .load_o        (load),
      // a_o port: a register interface
      .a_o           (a),
      // b_o port: b register interface
      .b_o           (b),
      // c_i port: c register interface
      .c_i           (acc)
   );

   // en_int register
   iob_reg_ca #(
      .DATA_W (1),
      .RST_VAL(0)
   ) en_int_reg (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      // data_i port: Data input
      .data_i(en_int_nxt),
      // data_o port: Data output
      .data_o(en_int)
   );

   // mul1 register
   iob_reg_ca #(
      .DATA_W (16),
      .RST_VAL(0)
   ) mul1_reg (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      // data_i port: Data input
      .data_i(mul1_nxt),
      // data_o port: Data output
      .data_o(mul1)
   );

   // mul2 register
   iob_reg_ca #(
      .DATA_W (16),
      .RST_VAL(0)
   ) mul2_reg (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      // data_i port: Data input
      .data_i(mul2_nxt),
      // data_o port: Data output
      .data_o(mul2)
   );

   // acc register
   iob_reg_ca #(
      .DATA_W (16),
      .RST_VAL(0)
   ) acc_reg (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      // data_i port: Data input
      .data_i(acc_nxt),
      // data_o port: Data output
      .data_o(acc)
   );

   // done register
   iob_reg_ca #(
      .DATA_W (3),
      .RST_VAL(0)
   ) done_reg (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      // data_i port: Data input
      .data_i(done_nxt),
      // data_o port: Data output
      .data_o(done)
   );

   // done_int register
   iob_reg_ca #(
      .DATA_W (1),
      .RST_VAL(0)
   ) done_int_reg (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      // data_i port: Data input
      .data_i(done_int_nxt),
      // data_o port: Data output
      .data_o(done_int)
   );


endmodule
