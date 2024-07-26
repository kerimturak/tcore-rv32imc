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
// Design Name:    stage3_execution                                           //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    stage3_execution                                           //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`include "tcore_defines.svh"
module stage3_execution
  import tcore_param::*;
(
    input  logic            clk_i,
    input  logic            rst_ni,
    input  logic [     1:0] fwd_a_i,
    input  logic [     1:0] fwd_b_i,
    input  logic [XLEN-1:0] alu_result_i,
    input  logic [XLEN-1:0] wb_data_i,
    input  logic [XLEN-1:0] r1_data_i,
    input  logic [XLEN-1:0] r2_data_i,
    input  logic [     1:0] alu_in1_sel_i,
    input  logic            alu_in2_sel_i,
    input  logic            is_comp_i,
    input  logic [XLEN-1:0] pc_i,
    input  logic [XLEN-1:0] pc2_i,
    input  logic [XLEN-1:0] pc4_i,
    input  logic [XLEN-1:0] imm_i,
    input  logic [     7:0] pc_sel_i,
    input  logic [     4:0] alu_ctrl_i,
    output logic [XLEN-1:0] write_data_o,
    output logic [XLEN-1:0] pc_target_o,
    output logic [XLEN-1:0] alu_result_o,
    output logic            pc_sel_o,
    output logic            alu_stall_o
);

  logic        [XLEN-1:0] data_a;
  logic        [XLEN-1:0] operant_a;
  logic        [XLEN-1:0] operant_b;
  logic signed [XLEN-1:0] signed_imm;
  logic                   ex_zero;
  logic                   ex_slt;
  logic                   ex_sltu;

  always_comb begin
    data_a = fwd_a_i[1] ? alu_result_i : (fwd_a_i[0] ? wb_data_i : r1_data_i);
    case (alu_in1_sel_i)
      2'b00: operant_a = data_a;
      2'b01: operant_a = is_comp_i ? pc2_i : pc4_i;
      2'b10: operant_a = pc_i;
      2'b11: operant_a = data_a;
    endcase

    write_data_o = fwd_b_i[1] ? alu_result_i : (fwd_b_i[0] ? wb_data_i : r2_data_i);
    operant_b = alu_in2_sel_i ? imm_i : write_data_o;
    signed_imm = imm_i;
    pc_target_o = pc_sel_i[6] ? (data_a + imm_i) & ~1 : pc_i + signed_imm;

    // b_beq, b_bne, b_blt, b_bge, b_bltu, b_bgeu, i_jalr, u_jal
    pc_sel_o = (pc_sel_i[0] && ex_zero);
    pc_sel_o |= (pc_sel_i[1] && !ex_zero);
    pc_sel_o |= (pc_sel_i[2] && ex_slt);
    pc_sel_o |= (pc_sel_i[3] && (!ex_slt || ex_zero));
    pc_sel_o |= (pc_sel_i[4] && ex_sltu);
    pc_sel_o |= (pc_sel_i[5] && (!ex_sltu || ex_zero));
    pc_sel_o |= pc_sel_i[6];
    pc_sel_o |= pc_sel_i[7];
  end

  alu alu (
      .clk_i      (clk_i),
      .rst_i      (rst_ni),
      .alu_a_i    (operant_a),
      .alu_b_i    (operant_b),
      .op_sel_i   (alu_ctrl_i),
      .alu_stall_o(alu_stall_o),
      .zero_o     (ex_zero),
      .slt_o      (ex_slt),
      .sltu_o     (ex_sltu),
      .alu_o      (alu_result_o)
  );

endmodule
