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
// Design Name:    reg_file                                                   //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Core integer registers                                     //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`include "tcore_defines.svh"
module reg_file
  import tcore_param::*;
(
    input  logic            clk_i,
    input  logic            rst_i,
    input  logic            rw_en_i,
    input  logic [     4:0] r1_addr_i,
    input  logic [     4:0] r2_addr_i,
    input  logic [     4:0] waddr_i,
    input  logic [XLEN-1:0] wdata_i,
    output logic [XLEN-1:0] r1_data_o,
    output logic [XLEN-1:0] r2_data_o
);

  logic [XLEN-1:0] registers[31:0];

  always_comb begin : register_read
    r1_data_o = registers[r1_addr_i];
    r2_data_o = registers[r2_addr_i];
  end

  always_ff @(posedge clk_i) begin : register_write
    if (rst_i) begin
      registers <= '{default: 0};
    end else if (rw_en_i == 1'b1 && waddr_i != 5'b0) begin
      registers[waddr_i] <= wdata_i;
    end
  end

endmodule
