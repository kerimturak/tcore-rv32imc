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
// Design Name:    uart_tx                                                    //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    uart_tx                                                    //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
module uart_tx
  import tcore_param::*;
(
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic [15:0] baud_div_i,  // uart sample point
    input  logic        tx_we_i,     // transmitter buffer write enable
    input  logic        tx_en_i,     // transmitter enable
    input  logic [ 7:0] din_i,       // 8-bit data to transmit serially
    output logic        full_o,      // buffer full_o
    output logic        empty_o,     // buffer empty_o
    output logic        tx_bit_o     // transmitted bit
);

  localparam DEPTH = 32;

  logic [$clog2(DEPTH):0] rd_ptr;  // buffer read pointer
  logic [$clog2(DEPTH):0] wr_ptr;  // buffer write pointer
  logic [            7:0] tx_buffer                                                      [0:DEPTH-1];  // 32x8 buffer
  logic [            7:0] data;  // 1-byte data
  logic [            9:0] frame;  // 1-start_bit + data + 1-stop_bit = uart frame
  logic [            3:0] bit_counter;  // counter for transmiting data bit
  logic [       XLEN-1:0] baud_counter;  // clock tick counter until baud_div is achieved
  logic                   baud_clk;  // baud clock tick indicator

  enum logic {
    IDLE,
    SENDING
  }
      c_state, n_state;  // state machine

  always_ff @(posedge clk_i) begin  // asyn reset is necessary for this uart, baud clk controlled by tx_en
    if (rst_i) c_state <= IDLE;  // we wait in IDLE with asyn reset
    else if (baud_clk) c_state <= n_state;  // tx_en and baud clock hit pass to next state
  end

  always_comb begin
    full_o = (wr_ptr[$clog2(DEPTH)] != rd_ptr[$clog2(DEPTH)]) && (wr_ptr[$clog2(DEPTH)-1:0] == rd_ptr[$clog2(DEPTH)-1:0]);
    empty_o = (wr_ptr == rd_ptr);
    data    = tx_buffer[rd_ptr[$clog2(DEPTH)-1:0]];  // data comes from tx_buffer
    frame   = {1'b1, data, 1'b0};  // frame is generated here 1 start + 8 bit data + 1 stop = 10 bits
    case (c_state)
      IDLE:                                       // Initial state
        begin
        n_state  = (!empty_o && tx_en_i) ? SENDING : IDLE;  // If buffer is not empty and tx_en so we can go sending state
        tx_bit_o = 1'b1;  // In idle tx channel active high
      end
      SENDING: begin
        tx_bit_o = frame[bit_counter];  // In sending state we pass through the frame to channel
        n_state  = bit_counter == 9 ? IDLE : SENDING;  // we dont count till 10 because if we could check 9 so means already goes 10
      end
    endcase
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      wr_ptr       <= '0;
      rd_ptr       <= '0;  // read pointer shows start point
      baud_clk     <= '0;
      bit_counter  <= '0;  // no bit processed
      baud_counter <= '0;
    end else begin

      if (baud_clk) begin
        //c_state     <= n_state;
        bit_counter <= (c_state == SENDING && n_state != IDLE) ? bit_counter + 1'b1 : 1'b0;  // If we in sending and still there is bit which will be sent(next_state not idle)
        rd_ptr      <= bit_counter == 9 ? rd_ptr + 1 : rd_ptr;
      end

      if (tx_we_i && !full_o) begin  // If tx_we_i and buffer is not full_o write operation is active
        tx_buffer[wr_ptr[$clog2(DEPTH)-1:0]] <= din_i;
        wr_ptr                               <= wr_ptr + 1'b1;
      end

      if (tx_en_i) begin
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

endmodule
