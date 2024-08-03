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
// Design Name:    uart_rx                                                    //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    uart_rx                                                    //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
module uart_rx
  import tcore_param::*;
(
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic [15:0] baud_div_i,
    input  logic        rx_re_i,
    input  logic        rx_en_i,
    output logic [ 7:0] dout_o,
    output logic        full_o,
    output logic        empty_o,
    input  logic        rx_bit_i
);

  logic [     7:0] rx_buffer    [0:31];
  logic [     4:0] rd_ptr;
  logic [     4:0] wr_ptr;
  logic [     4:0] limit;
  logic            rx_bit_new;
  logic            rx_bit_old;
  logic [XLEN-1:0] baud_counter;
  logic            baud_clk;
  logic [     3:0] bit_counter;

  enum logic {
    IDLE,
    SAMPLING
  }
      c_state, n_state;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      rd_ptr       <= '0;
      baud_counter <= '0;
      baud_clk     <= '0;
      dout_o       <= '0;
    end else begin
      if (rx_re_i && !empty_o) begin
        rd_ptr <= rd_ptr + 1'b1;
        dout_o <= rx_buffer[rd_ptr];
      end
      if (rx_en_i) begin
        if (baud_counter == baud_div_i - 1) begin
          baud_counter <= '0;
          baud_clk     <= 1'b1;
        end else begin
          baud_counter <= baud_counter + 1'b1;
          baud_clk     <= 1'b0;
        end
      end
    end
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      c_state     <= IDLE;
      wr_ptr      <= '0;
      bit_counter <= '0;
      rx_bit_old  <= '1;
      rx_bit_new  <= '1;
    end else begin
      if (baud_clk) begin
        if (c_state == SAMPLING) begin
          rx_buffer[wr_ptr][bit_counter] <= rx_bit_i;
          wr_ptr                         <= bit_counter == 7 ? wr_ptr + 1'b1 : wr_ptr;
          bit_counter                    <= bit_counter != 8 ? bit_counter + 1'b1 : '0;
        end else begin
          bit_counter <= '0;
        end
        if (rx_en_i) begin
          rx_bit_old <= rx_bit_new;
          rx_bit_new <= rx_bit_i;
        end
      end
      c_state <= n_state;
    end
  end

  always_comb begin
    limit   = rd_ptr - 1;
    full_o  = (limit == wr_ptr);
    empty_o = (rd_ptr == wr_ptr);
    case (c_state)
      IDLE:     n_state = (rx_bit_old && !rx_bit_new && !full_o) ? SAMPLING : IDLE;
      SAMPLING: n_state = bit_counter == 8 ? IDLE : SAMPLING;
    endcase
  end

endmodule
