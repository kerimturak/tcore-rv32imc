// TCORE RISC-V Processor
// Copyright (c) 2024 Kerim TURAK
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
// and associated documentation files (the "Software"), to deal in the Software without restriction,
// including without limitation the rights to use, copy, modify, merge, publish, distribute,
// sublicense, and/or sell copies of the Software, and to permit persons to whom the Software
// is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.

////////////////////////////////////////////////////////////////////////////////
// Engineer:       Kerim TURAK - kerimturak@hotmail.com                       //
//                                                                            //
// Additional contributions by:                                               //
//                 --                                                         //
//                                                                            //
// Design Name:    uart                                                       //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    uart                                                       //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
module uart
  import tcore_param::*;
(
    input  logic            clk_i,
    input  logic            rst_i,
    input  logic            stb_i,
    input  logic [     1:0] adr_i,
    input  logic [     3:0] byte_sel_i,
    input  logic            we_i,
    input  logic [XLEN-1:0] dat_i,
    output logic [XLEN-1:0] dat_o,
    input  logic            uart_rx_i,
    output logic            uart_tx_o
);

  logic [15:0] baud_div;
  logic        tx_en;
  logic        tx_full;
  logic        tx_empty;
  logic        tx_we;
  logic        rx_en;
  logic [ 7:0] dout;
  logic        rx_full;
  logic        rx_empty;
  logic        rx_re;

  uart_tx uart_tx (
      .clk_i     (clk_i),
      .rst_i     (rst_i),
      .baud_div_i(baud_div),
      .tx_we_i   (tx_we),
      .tx_en_i   (tx_en),
      .din_i     (dat_i[7:0]),
      .full_o    (tx_full),
      .empty_o   (tx_empty),
      .tx_bit_o  (uart_tx_o)
  );

  uart_rx uart_rx (
      .clk_i     (clk_i),
      .rst_i     (rst_i),
      .baud_div_i(baud_div),
      .rx_re_i   (rx_re),
      .rx_en_i   (rx_en),
      .dout_o    (dout),
      .full_o    (rx_full),
      .empty_o   (rx_empty),
      .rx_bit_i  (uart_rx_i)
  );

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      tx_en    <= 1'b0;
      rx_en    <= 1'b0;
      baud_div <= 16'b0;
    end else if (stb_i && we_i && adr_i == '0) begin
      tx_en    <= byte_sel_i[0] ? dat_i[0] : tx_en;
      rx_en    <= byte_sel_i[0] ? dat_i[1] : rx_en;
      baud_div <= (&byte_sel_i[3:2]) ? dat_i[31:16] : baud_div;
    end
  end

  always_comb begin
    tx_we = 0;
    rx_re = 0;
    case (adr_i)
      2'b00: dat_o = {baud_div, 14'b0, rx_en, tx_en};
      2'b01: dat_o = {28'b0, rx_empty, rx_full, tx_empty, tx_full};
      2'b10: begin
        dat_o = {24'b0, dout};
        rx_re = stb_i && ~rx_empty && byte_sel_i[0];
      end
      2'b11: begin
        dat_o = {28'b0, rx_empty, rx_full, tx_empty, tx_full};
        tx_we = stb_i && ~tx_full && we_i && byte_sel_i[0];
      end
    endcase
  end

endmodule
