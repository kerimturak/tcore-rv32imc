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
// Design Name:    extend                                                     //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Immediate extracter frım instruction                       //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`include "tcore_defines.svh"
module extend
  import tcore_param::*;
(
    input  logic [XLEN-1:7] imm_i,  //! extracted immediate value from instruction
    input  logic [     2:0] sel_i,  //! type of instruction
    output logic [XLEN-1:0] imm_o   //! generated immediate value according to riscv unprivilege spec.
);

  always_comb begin : immediate_generator
    case (sel_i)
      0:       imm_o = {{20{imm_i[31]}}, imm_i[31:20]};  // i 12-bit signed immediate
      1:       imm_o = {{20{imm_i[31]}}, imm_i[31:25], imm_i[11:7]};  // s 12-bit signed immediate
      2:       imm_o = {{20{imm_i[31]}}, imm_i[7], imm_i[30:25], imm_i[11:8], 1'b0};  // b 13-bit signed immediate
      3:       imm_o = {{12{imm_i[31]}}, imm_i[19:12], imm_i[20], imm_i[30:21], 1'b0};  // j 21-bit signed immediate
      4:       imm_o = {{imm_i[31:12]}, 12'b0};  // u 20-bit signed immediate
      5:       imm_o = {{20{1'b0}}, imm_i[31:20]};  // i 12-bit unsigned immediate
      6:       imm_o = {27'b0, imm_i[24:20]};  // shift amount (shamt)
      default: imm_o = '0;
    endcase
  end

endmodule
