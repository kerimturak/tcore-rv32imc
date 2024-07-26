// This file includes code snippets taken from https://projectf.io/posts/division-in-verilog/
// This code snippet has been included and changed in the TCORE project.
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
// Design Name:    divu_int                                                   //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Slow division with changing op cycle (cycle <= 32          //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`include "tcore_defines.svh"
module divu_int #(
    parameter WIDTH = 32
) (
    input  logic             clk_i,
    input  logic             rst_ni,
    input  logic             start_i,     // start calculation
    input  logic [WIDTH-1:0] dividend_i,  // dividend (numerator)
    input  logic [WIDTH-1:0] divisor_i,   // divisor (denominator)
    output logic             busy_o,      // calculation in progress
    output logic             done_o,      // calculation is complete (high for one tick)
    output logic             valid_o,     // result is valid_o
    output logic             dbz_o,       // divide by zero
    output logic [WIDTH-1:0] quotient_o,  // result value: quotient
    output logic [WIDTH-1:0] reminder_o   // result: remainder
);


  logic [WIDTH-1:0] divisor_q;  // copy of divisor
  logic [WIDTH-1:0] quo, quo_next;  // intermediate quotient
  logic [WIDTH:0] acc, acc_next;  // accumulator (1 bit wider)
  logic [$clog2(WIDTH)-1:0] num_step;  // iteration counter

  always_comb begin
    if (acc >= {1'b0, divisor_q}) begin
      acc_next = acc - divisor_q;
      {acc_next, quo_next} = {acc_next[WIDTH-1:0], quo, 1'b1};
    end else begin
      {acc_next, quo_next} = {acc, quo} << 1;
    end
  end

  always_ff @(posedge clk_i) begin
    if (rst_ni) begin
      busy_o     <= 1'b0;
      done_o     <= 1'b0;
      valid_o    <= 1'b0;
      dbz_o      <= 1'b0;
      quotient_o <= 0;
      reminder_o <= 0;
      divisor_q  <= 0;
      acc        <= 0;
      quo        <= 0;
      num_step   <= WIDTH;
    end else begin
      if (start_i) begin
        valid_o  <= 1'b0;
        num_step <= WIDTH;
        if (divisor_i == 0) begin
          busy_o <= 1'b0;
          done_o <= 1'b1;
          dbz_o  <= 1'b1;
        end else begin
          busy_o <= 1'b1;
          done_o <= 1'b0;
          dbz_o <= 1'b0;
          divisor_q <= divisor_i;
          {acc, quo} <= {{WIDTH{1'b0}}, dividend_i, 1'b0};
        end
      end else if (busy_o) begin
        if (num_step == 1 || quo == '0) begin
          busy_o <= 1'b0;
          done_o <= 1'b1;
          valid_o <= 1'b1;
          quotient_o <= quo == '0 ? quo_next << num_step : quo_next;
          reminder_o <= quo == '0 ? acc_next[WIDTH:1] << num_step : acc_next[WIDTH:1];
        end else begin
          busy_o   <= 1'b1;
          done_o   <= 1'b0;
          valid_o  <= 1'b0;
          num_step <= num_step - 1;
          acc      <= acc_next;
          quo      <= quo_next;
        end
      end
    end
  end

endmodule
