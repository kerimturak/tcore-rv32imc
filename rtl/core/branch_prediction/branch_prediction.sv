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
// Design Name:    branch_prediction                                          //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    2-bit dynamic prediction                                   //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`include "tcore_defines.svh"
import tcore_param::*;

module branch_prediction (
    input  logic                 clk_i,
    input  logic                 rst_ni,
    input  logic                 spec_hit_i,
    input  logic                 branch_type_i,
    input  logic          [31:0] fetch_rdata_i,
    input  logic          [31:0] fetch_pc_i,
    input  logic                 fetch_valid_i,
    output predict_info_t        spec_o
);

  logic [31:0] imm_j_type;
  logic [31:0] imm_b_type;
  logic [31:0] imm_cj_type;
  logic [31:0] imm_cb_type;
  logic [31:0] branch_imm;
  logic [31:0] instr;
  logic        instr_j;
  logic        instr_b;
  logic        instr_cj;
  logic        instr_cb;
  logic        instr_b_taken;

  assign instr = fetch_rdata_i;
  assign imm_j_type = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
  assign imm_b_type = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
  assign imm_cj_type = {{21{instr[12]}}, instr[8], instr[10:9], instr[6], instr[7], instr[2], instr[11], instr[5:3], 1'b0};
  assign imm_cb_type = {{24{instr[12]}}, instr[6:5], instr[2], instr[11:10], instr[4:3], 1'b0};

  assign instr_b = instr[6:0] == 7'h63;
  assign instr_j = instr[6:0] == 7'h6f;
  assign instr_cb = (instr[1:0] == 2'b01) & ((instr[15:13] == 3'b110) | (instr[15:13] == 3'b111));
  assign instr_cj = (instr[1:0] == 2'b01) & ((instr[15:13] == 3'b101) | (instr[15:13] == 3'b001));

  always_comb begin
    branch_imm = imm_b_type;
    unique case (1'b1)
      instr_j:  branch_imm = imm_j_type;
      instr_b:  branch_imm = imm_b_type;
      instr_cj: branch_imm = imm_cj_type;
      instr_cb: branch_imm = imm_cb_type;
    endcase
  end

  typedef enum logic [1:0] {
    WEAK_TAKEN,
    STRONG_TAKEN,
    WEAK_NTAKEN,
    STRONG_NTAKEN
  } branch_state_e;
  branch_state_e state_q, state_d;

  assign instr_b_taken = (state_q inside {WEAK_TAKEN, STRONG_TAKEN} && (instr_b || instr_cb));
  assign spec_o.taken = fetch_valid_i && (instr_j || instr_cj || instr_b_taken) && (spec_o.pc < 32'h4000_3D00 );
  assign spec_o.pc    = fetch_pc_i + branch_imm;

  always_ff @(posedge clk_i) begin
    if (rst_ni) state_q <= WEAK_NTAKEN;
    else state_q <= state_d;
  end

  always_comb begin
    state_d = state_q;
    case (state_q)
      WEAK_NTAKEN: begin
        if (fetch_valid_i && branch_type_i) begin
          if (spec_hit_i) state_d = STRONG_NTAKEN;
          else state_d = WEAK_TAKEN;
        end
      end
      WEAK_TAKEN:
      if (fetch_valid_i && branch_type_i) begin
        if (spec_hit_i) state_d = STRONG_TAKEN;
        else state_d = WEAK_NTAKEN;
      end
      STRONG_TAKEN:
      if (fetch_valid_i && branch_type_i) begin
        if (spec_hit_i) state_d = STRONG_TAKEN;
        else state_d = WEAK_TAKEN;
      end
      STRONG_NTAKEN:
      if (fetch_valid_i && branch_type_i) begin
        if (spec_hit_i) state_d = STRONG_NTAKEN;
        else state_d = WEAK_NTAKEN;
      end
    endcase
  end
endmodule
