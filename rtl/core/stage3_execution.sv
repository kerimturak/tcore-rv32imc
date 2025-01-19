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
    input  logic               clk_i,
    input  logic               rst_ni,
    input  logic    [     1:0] fwd_a_i,
    input  logic    [     1:0] fwd_b_i,
    input  logic    [XLEN-1:0] alu_result_i,
    input  logic    [XLEN-1:0] wb_data_i,
    input  logic    [XLEN-1:0] r1_data_i,
    input  logic    [XLEN-1:0] r2_data_i,
    input  logic    [     1:0] alu_in1_sel_i,
    input  logic               alu_in2_sel_i,
    input  logic               rd_csr_i,
    input  logic               wr_csr_i,
    input  logic    [    11:0] csr_idx_i,
    input  logic               csr_or_data_i,
    input  logic               is_comp_i,
    input  logic    [XLEN-1:0] pc_i,
    input  logic    [XLEN-1:0] pc2_i,
    input  logic    [XLEN-1:0] pc4_i,
    input  logic    [XLEN-1:0] imm_i,
    input  pc_sel_e            pc_sel_i,
    input  alu_op_e            alu_ctrl_i,
    input exc_type_e         exc_type_i,
    output logic    [XLEN-1:0] write_data_o,
    output logic    [XLEN-1:0] pc_target_o,
    output logic    [XLEN-1:0] alu_result_o,
    output logic               pc_sel_o,
    output logic               alu_stall_o,
    output exc_type_e          exc_type_o
);

  logic        [XLEN-1:0] data_a;
  logic        [XLEN-1:0] operant_a;
  logic        [XLEN-1:0] operant_b;
  logic signed [XLEN-1:0] signed_imm;
  logic                   ex_zero;
  logic                   ex_slt;
  logic                   ex_sltu;
  logic        [XLEN-1:0] alu_result;
  logic        [XLEN-1:0] csr_rdata;

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
    /*
    Eğer exception desteği yoksa burası
    pc_target_o = pc_sel_i == JALR ? (data_a + imm_i) & ~1 : pc_i + signed_imm;
    */
    pc_target_o = pc_sel_i == JALR ? (data_a + imm_i) : pc_i + signed_imm;

    pc_sel_o = (pc_sel_i == BEQ) && ex_zero;
    pc_sel_o |= (pc_sel_i == BNE) && !ex_zero;
    pc_sel_o |= (pc_sel_i == BLT) && ex_slt;
    pc_sel_o |= (pc_sel_i == BGE) && (!ex_slt || ex_zero);
    pc_sel_o |= (pc_sel_i == BLTU) && ex_sltu;
    pc_sel_o |= (pc_sel_i == BGEU) && (!ex_sltu || ex_zero);
    pc_sel_o |= (pc_sel_i == JALR);
    pc_sel_o |= (pc_sel_i == JAL);

    exc_type_o = pc_sel_o && pc_target_o[0] ? INSTR_MISALIGNED : (exc_type_i != NO_EXCEPTION ? exc_type_i : NO_EXCEPTION);
  end

  alu alu (
      .clk_i      (clk_i),
      .rst_ni     (rst_ni),
      .alu_a_i    (operant_a),
      .csr_rdata_i(csr_rdata),
      .alu_b_i    (operant_b),
      .op_sel_i   (alu_ctrl_i),
      .alu_stall_o(alu_stall_o),
      .zero_o     (ex_zero),
      .slt_o      (ex_slt),
      .sltu_o     (ex_sltu),
      .alu_o      (alu_result)
  );

  assign alu_result_o = csr_or_data_i ? csr_rdata : alu_result;

  cs_reg_file u_cs_reg_file (
      .clk_i      (clk_i),
      .rst_ni     (rst_ni),
      .rd_en_i    (rd_csr_i),
      .wr_en_i    (wr_csr_i),
      .csr_idx_i  (csr_idx_i),
      .csr_wdata_i(alu_result),
      .csr_rdata_o(csr_rdata)
  );
endmodule
