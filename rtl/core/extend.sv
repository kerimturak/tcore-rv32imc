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
    input logic [XLEN-1:7] imm_i,
    input imm_e sel_i,
    output logic [XLEN-1:0] imm_o
);

  always_comb begin : immediate_generator
    case (sel_i)
      I_IMM:   imm_o = {{20{imm_i[31]}}, imm_i[31:20]};  // i 12-bit signed immediate
      I_USIMM: imm_o = {{20{1'b0}}, imm_i[31:20]};  // i 12-bit unsigned immediate
      S_IMM:   imm_o = {{20{imm_i[31]}}, imm_i[31:25], imm_i[11:7]};  // s 12-bit signed immediate
      B_IMM:   imm_o = {{20{imm_i[31]}}, imm_i[7], imm_i[30:25], imm_i[11:8], 1'b0};  // b 13-bit signed immediate
      U_IMM:   imm_o = {{imm_i[31:12]}, 12'b0};  // u 20-bit signed immediate
      J_IMM:   imm_o = {{12{imm_i[31]}}, imm_i[19:12], imm_i[20], imm_i[30:21], 1'b0};  // j 20-bit signed immediate
      CSR_IMM: imm_o = {27'b0, imm_i[19:15]};
      default: imm_o = '0;
    endcase
  end

endmodule
