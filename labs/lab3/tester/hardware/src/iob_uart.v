`timescale 1ns / 1ps
`include "iob_uart_conf.vh"

module iob_uart #(
   parameter DATA_W = `IOB_UART_DATA_W
) (
   // clk_en_rst_s: Clock, clock enable and reset
   input                 clk_i,
   input                 cke_i,
   input                 arst_i,
   // rs232_m: RS232 interface
   input                 rs232_rxd_i,
   output                rs232_txd_o,
   output                rs232_rts_o,
   input                 rs232_cts_i,
   // iob_csrs_cbus_s: Control and Status Registers interface (auto-generated)
   input                 iob_csrs_iob_valid_i,
   input                 iob_csrs_iob_addr_i,
   input  [  DATA_W-1:0] iob_csrs_iob_wdata_i,
   input  [DATA_W/8-1:0] iob_csrs_iob_wstrb_i,
   output                iob_csrs_iob_rvalid_o,
   output [  DATA_W-1:0] iob_csrs_iob_rdata_o,
   output                iob_csrs_iob_ready_o,
   input                 iob_csrs_iob_rready_i
);

   wire          softreset_wr;
   wire [16-1:0] div_wr;
   wire [ 8-1:0] txdata_wdata_wr;
   wire          txdata_wen_wr;
   wire          txdata_ready_wr;
   wire          txen_wr;
   wire          rxen_wr;
   wire          txready_rd;
   wire          rxready_rd;
   wire [ 8-1:0] rxdata_rdata_rd;
   wire          rxdata_rvalid_rd;
   wire          rxdata_rready_rd;
   wire          rxdata_ren_rd;
   wire          rxdata_ready_rd;
   wire          rxdata_rvalid_en;
   wire          rxdata_rvalid_rst;
   wire          rxdata_rvalid_nxt;


   // txdata Manual logic
   assign txdata_ready_wr   = 1'b1;

   // rxdata Manual logic
   assign rxdata_ready_rd   = 1'b1;

   // set rxdata on read enable, reset on (rready and rvalid)
   assign rxdata_rvalid_en  = rxdata_ren_rd;
   assign rxdata_rvalid_rst = rxdata_rvalid_rd & rxdata_rready_rd;
   assign rxdata_rvalid_nxt = rxdata_ren_rd;


   // Control/Status Registers
   iob_uart_csrs iob_csrs (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i          (clk_i),
      .cke_i          (cke_i),
      .arst_i         (arst_i),
      // control_if_s port: CSR control interface. Interface type defined by `csr_if` parameter.
      .iob_valid_i    (iob_csrs_iob_valid_i),
      .iob_addr_i     (iob_csrs_iob_addr_i),
      .iob_wdata_i    (iob_csrs_iob_wdata_i),
      .iob_wstrb_i    (iob_csrs_iob_wstrb_i),
      .iob_rvalid_o   (iob_csrs_iob_rvalid_o),
      .iob_rdata_o    (iob_csrs_iob_rdata_o),
      .iob_ready_o    (iob_csrs_iob_ready_o),
      .iob_rready_i   (iob_csrs_iob_rready_i),
      // softreset_o port: softreset register interface
      .softreset_o    (softreset_wr),
      // div_o port: div register interface
      .div_o          (div_wr),
      // txdata_io port: txdata register interface
      .txdata_wdata_o (txdata_wdata_wr),
      .txdata_wen_o   (txdata_wen_wr),
      .txdata_ready_i (txdata_ready_wr),
      // txen_o port: txen register interface
      .txen_o         (txen_wr),
      // rxen_o port: rxen register interface
      .rxen_o         (rxen_wr),
      // txready_i port: txready register interface
      .txready_i      (txready_rd),
      // rxready_i port: rxready register interface
      .rxready_i      (rxready_rd),
      // rxdata_io port: rxdata register interface
      .rxdata_rdata_i (rxdata_rdata_rd),
      .rxdata_rvalid_i(rxdata_rvalid_rd),
      .rxdata_rready_o(rxdata_rready_rd),
      .rxdata_ren_o   (rxdata_ren_rd),
      .rxdata_ready_i (rxdata_ready_rd)
   );

   // Register for rxdata rvalid
   iob_reg_care #(
      .DATA_W (1),
      .RST_VAL(1'b0)
   ) iob_reg_rvalid (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      .rst_i (rxdata_rvalid_rst),
      .en_i  (rxdata_rvalid_en),
      // data_i port: Data input
      .data_i(rxdata_rvalid_nxt),
      // data_o port: Data output
      .data_o(rxdata_rvalid_rd)
   );

   // UART core driver
   iob_uart_core iob_uart_core_inst (
      // clk_rst_s port: Clock and reset
      .clk_i          (clk_i),
      .arst_i         (arst_i),
      .rst_soft_i     (softreset_wr),
      .tx_en_i        (txen_wr),
      .rx_en_i        (rxen_wr),
      .tx_ready_o     (txready_rd),
      .rx_ready_o     (rxready_rd),
      .tx_data_i      (txdata_wdata_wr),
      .rx_data_o      (rxdata_rdata_rd),
      .data_write_en_i(txdata_wen_wr),
      .data_read_en_i (rxdata_ren_rd),
      .bit_duration_i (div_wr),
      // rs232_m port: RS232 interface
      .rs232_rxd_i    (rs232_rxd_i),
      .rs232_txd_o    (rs232_txd_o),
      .rs232_rts_o    (rs232_rts_o),
      .rs232_cts_i    (rs232_cts_i)
   );


endmodule
