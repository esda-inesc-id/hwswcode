`timescale 1ns / 1ps
`include "iob_counter_conf.vh"

module iob_counter #(
   parameter DATA_W  = `IOB_COUNTER_DATA_W,
   parameter RST_VAL = `IOB_COUNTER_RST_VAL
) (
   // clk_en_rst_s: Clock, clock enable and reset
   input               clk_i,
   input               cke_i,
   input               arst_i,
   // en_rst_i: Enable and Synchronous reset interface
   input               en_i,
   input               rst_i,
   // data_o: Output port
   output [DATA_W-1:0] data_o
);

   // data_int wire
   wire [DATA_W-1:0] data_int;


   assign data_int = data_o + 1'b1;


   // Default description
   iob_reg_care #(
      .DATA_W (DATA_W),
      .RST_VAL(RST_VAL)
   ) reg0 (
      // clk_en_rst_s port: Clock, clock enable and reset
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      .rst_i (rst_i),
      .en_i  (en_i),
      // data_i port: Data input
      .data_i(data_int),
      // data_o port: Data output
      .data_o(data_o)
   );


endmodule
