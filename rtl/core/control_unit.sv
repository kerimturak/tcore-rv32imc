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
// Design Name:    control_unit                                               //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Manages and directs the operation of the processor by      //
//                 interpreting and executing instructions. It generates      //
//                 control signals to coordinate the activities of other      //
//                 components.                                                //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`include "tcore_defines.svh"
module control_unit
  import tcore_param::*;
(
    input  logic  [6:0] op_i,
    input  logic  [2:0] funct3_i,
    input  logic  [6:0] funct7_i,
    output ctrl_t       ctrl_o
);

  //----rv32
  logic r_add;
  logic r_sub;
  logic r_sll;
  logic r_slt;
  logic r_sltu;
  logic r_xor;
  logic r_srl;
  logic r_sra;
  logic r_or;
  logic r_and;
  //----rv32i
  logic i_addi;
  logic i_slti;
  logic i_sltiu;
  logic i_xori;
  logic i_ori;
  logic i_andi;
  logic i_slli;
  logic i_srli;
  logic i_srai;
  // ---- rv32m:
  logic r_mul;
  logic r_mulh;
  logic r_mulhsu;
  logic r_mulhu;
  logic r_rem;
  logic r_remu;
  logic r_div;
  logic r_divu;
  //----load
  logic i_lb;
  logic i_lh;
  logic i_lw;
  logic i_lbu;
  logic i_lhu;
  //----store
  logic s_sb;
  logic s_sh;
  logic s_sw;
  //----branch
  logic b_beq;
  logic b_bne;
  logic b_blt;
  logic b_bge;
  logic b_bltu;
  logic b_bgeu;
  // -- upper immediate types (u-type)
  logic u_lui;
  logic u_auipc;
  logic u_jal;
  // ---- jump
  logic i_jalr;

  always_comb begin
    r_add  = (op_i == op_r_type) && (funct3_i == 3'd0) && (funct7_i[5] == 1'b0) && (funct7_i[0] == 1'b0);
    r_sub  = (op_i == op_r_type) && (funct3_i == 3'd0) && (funct7_i[5] == 1'b1) && (funct7_i[0] == 1'b0);
    r_sll  = (op_i == op_r_type) && (funct3_i == 3'd1) && (funct7_i[5] == 1'b0) && (funct7_i[0] == 1'b0);
    r_slt  = (op_i == op_r_type) && (funct3_i == 3'd2) && (funct7_i[5] == 1'b0) && (funct7_i[0] == 1'b0);
    r_sltu = (op_i == op_r_type) && (funct3_i == 3'd3) && (funct7_i[5] == 1'b0) && (funct7_i[0] == 1'b0);
    r_xor  = (op_i == op_r_type) && (funct3_i == 3'd4) && (funct7_i[5] == 1'b0) && (funct7_i[0] == 1'b0);
    r_srl  = (op_i == op_r_type) && (funct3_i == 3'd5) && (funct7_i[5] == 1'b0) && (funct7_i[0] == 1'b0);
    r_sra  = (op_i == op_r_type) && (funct3_i == 3'd5) && (funct7_i[5] == 1'b1) && (funct7_i[0] == 1'b0);
    r_or   = (op_i == op_r_type) && (funct3_i == 3'd6) && (funct7_i[5] == 1'b0) && (funct7_i[0] == 1'b0);
    r_and  = (op_i == op_r_type) && (funct3_i == 3'd7) && (funct7_i[5] == 1'b0) && (funct7_i[0] == 1'b0);

    i_addi   = (op_i == op_i_type) && (funct3_i == 3'd0);
    i_slti   = (op_i == op_i_type) && (funct3_i == 3'd2);
    i_sltiu  = (op_i == op_i_type) && (funct3_i == 3'd3);
    i_xori   = (op_i == op_i_type) && (funct3_i == 3'd4);
    i_ori    = (op_i == op_i_type) && (funct3_i == 3'd6);
    i_andi   = (op_i == op_i_type) && (funct3_i == 3'd7);
    i_slli   = (op_i == op_i_type) && (funct3_i == 3'd1);
    i_srli   = (op_i == op_i_type) && (funct3_i == 3'd5) && (funct7_i[5] == 1'b0);
    i_srai   = (op_i == op_i_type) && (funct3_i == 3'd5) && (funct7_i[5] == 1'b1);

    r_mul    = (op_i == op_r_type) && (funct3_i == 3'd0) && (funct7_i[5] == 1'b0) && (funct7_i[0] == 1'b1);
    r_mulh   = (op_i == op_r_type) && (funct3_i == 3'd1) && (funct7_i[5] == 1'b0) && (funct7_i[0] == 1'b1);
    r_mulhsu = (op_i == op_r_type) && (funct3_i == 3'd2) && (funct7_i[5] == 1'b0) && (funct7_i[0] == 1'b1);
    r_mulhu  = (op_i == op_r_type) && (funct3_i == 3'd3) && (funct7_i[5] == 1'b0) && (funct7_i[0] == 1'b1);
    r_rem    = (op_i == op_r_type) && (funct3_i == 3'd6) && (funct7_i[5] == 1'b0) && (funct7_i[0] == 1'b1);
    r_remu   = (op_i == op_r_type) && (funct3_i == 3'd7) && (funct7_i[5] == 1'b0) && (funct7_i[0] == 1'b1);
    r_div    = (op_i == op_r_type) && (funct3_i == 3'd4) && (funct7_i[5] == 1'b0) && (funct7_i[0] == 1'b1);
    r_divu   = (op_i == op_r_type) && (funct3_i == 3'd5) && (funct7_i[5] == 1'b0) && (funct7_i[0] == 1'b1);

    i_lb   = (op_i == op_i_type_load) && (funct3_i == 3'd0);
    i_lh   = (op_i == op_i_type_load) && (funct3_i == 3'd1);
    i_lw   = (op_i == op_i_type_load) && (funct3_i == 3'd2);
    i_lbu  = (op_i == op_i_type_load) && (funct3_i == 3'd4);
    i_lhu  = (op_i == op_i_type_load) && (funct3_i == 3'd5);

    s_sb  = (op_i == op_s_type) && (funct3_i == 3'd0);
    s_sh  = (op_i == op_s_type) && (funct3_i == 3'd1);
    s_sw  = (op_i == op_s_type) && (funct3_i == 3'd2);

    b_beq   = (op_i == op_b_type) && (funct3_i == 3'd0);
    b_bne   = (op_i == op_b_type) && (funct3_i == 3'd1);
    b_blt   = (op_i == op_b_type) && (funct3_i == 3'd4);
    b_bge   = (op_i == op_b_type) && (funct3_i == 3'd5);
    b_bltu  = (op_i == op_b_type) && (funct3_i == 3'd6);
    b_bgeu  = (op_i == op_b_type) && (funct3_i == 3'd7);

    u_lui   = (op_i == op_u_type_load);
    u_auipc = (op_i == op_u_type_auipc);
    u_jal   = (op_i == op_u_type_jump);

    i_jalr  = (op_i == op_i_type_jump);

    ctrl_o.alu_in1_sel = u_auipc ? 2'd2 : (i_jalr  ? 2'b1 : 2'b0);
    ctrl_o.ld_op_size  = {i_lhu, i_lbu, i_lw, i_lh, i_lb};

    case (1'b1)
      r_add, i_lb, i_lh, i_lw, i_lbu, i_lhu, i_addi, s_sb, s_sh, s_sw, b_beq, b_bne, b_blt, b_bge, b_bltu, b_bgeu, u_jal, i_jalr: ctrl_o.alu_ctrl = 5'd0;
      r_sub:                                                                                                                      ctrl_o.alu_ctrl = 5'd1;
      r_sll, i_slli:                                                                                                              ctrl_o.alu_ctrl = 5'd2;
      r_slt, i_slti:                                                                                                              ctrl_o.alu_ctrl = 5'd3;
      r_sltu, i_sltiu:                                                                                                            ctrl_o.alu_ctrl = 5'd4;
      r_xor, i_xori:                                                                                                              ctrl_o.alu_ctrl = 5'd5;
      r_srl, i_srli:                                                                                                              ctrl_o.alu_ctrl = 5'd6;
      r_sra, i_srai:                                                                                                              ctrl_o.alu_ctrl = 5'd7;
      r_or, i_ori:                                                                                                                ctrl_o.alu_ctrl = 5'd8;
      r_and, i_andi:                                                                                                              ctrl_o.alu_ctrl = 5'd9;
      r_mul:                                                                                                                      ctrl_o.alu_ctrl = 5'd10;
      r_mulh:                                                                                                                     ctrl_o.alu_ctrl = 5'd11;
      r_mulhsu:                                                                                                                   ctrl_o.alu_ctrl = 5'd12;
      r_mulhu:                                                                                                                    ctrl_o.alu_ctrl = 5'd13;
      r_div:                                                                                                                      ctrl_o.alu_ctrl = 5'd14;
      r_divu:                                                                                                                     ctrl_o.alu_ctrl = 5'd15;  // rounding toward zero
      r_rem:                                                                                                                      ctrl_o.alu_ctrl = 5'd16;
      r_remu:                                                                                                                     ctrl_o.alu_ctrl = 5'd17;
      u_lui:                                                                                                                      ctrl_o.alu_ctrl = 5'd18;
      default:                                                                                                                    ctrl_o.alu_ctrl = 5'd0;
    endcase

    ctrl_o.pc_sel[0] = b_beq;
    ctrl_o.pc_sel[1] = b_bne;
    ctrl_o.pc_sel[2] = b_blt;
    ctrl_o.pc_sel[3] = b_bge;
    ctrl_o.pc_sel[4] = b_bltu;
    ctrl_o.pc_sel[5] = b_bgeu;
    ctrl_o.pc_sel[6] = i_jalr;
    ctrl_o.pc_sel[7] = u_jal;

    case (op_i)
      op_r_type: begin
        ctrl_o.rf_rw_en    = 1'b1;
        ctrl_o.imm_sel     = 3'b000;
        ctrl_o.alu_in2_sel = 1'b0;
        ctrl_o.wr_en       = 1'b0;
        ctrl_o.result_src  = 2'b00;
        ctrl_o.rw_type     = 2'b00;
      end
      op_i_type: begin
        ctrl_o.rf_rw_en = 1'b1;
        if (i_slli || i_srli || i_srai) begin
          ctrl_o.imm_sel = 3'b101;
        end else begin
          ctrl_o.imm_sel = 3'b000;
        end
        ctrl_o.alu_in2_sel = 1'b1;
        ctrl_o.wr_en       = 1'b0;
        ctrl_o.result_src  = 2'b00;
        ctrl_o.rw_type     = 2'b00;
      end
      op_i_type_load: begin
        ctrl_o.rf_rw_en    = 1'b1;
        ctrl_o.imm_sel     = 3'b000;
        ctrl_o.alu_in2_sel = 1'b1;
        ctrl_o.wr_en       = 1'b0;
        ctrl_o.result_src  = 2'b01;
        case ({
          i_lw, i_lhu | i_lh, i_lbu | i_lb
        })  // uniqeu case
          3'b001:  ctrl_o.rw_type = 2'b01;
          3'b010:  ctrl_o.rw_type = 2'b10;
          3'b100:  ctrl_o.rw_type = 2'b11;
          default: ctrl_o.rw_type = 2'b00;
        endcase
      end
      op_s_type: begin
        ctrl_o.rf_rw_en    = 1'b0;
        ctrl_o.imm_sel     = 3'b001;
        ctrl_o.alu_in2_sel = 1'b1;
        ctrl_o.wr_en       = 1'b1;
        case ({
          s_sw, s_sh, s_sb
        })  // uniqeu case
          3'b001:  ctrl_o.rw_type = 2'b01;
          3'b010:  ctrl_o.rw_type = 2'b10;
          3'b100:  ctrl_o.rw_type = 2'b11;
          default: ctrl_o.rw_type = 2'b00;
        endcase
        ctrl_o.result_src = 2'b00;
      end
      op_b_type: begin
        ctrl_o.rf_rw_en    = 1'b0;
        ctrl_o.imm_sel     = 3'b010;
        ctrl_o.alu_in2_sel = 1'b0;
        ctrl_o.wr_en       = 1'b0;
        ctrl_o.result_src  = 2'b00;
        ctrl_o.rw_type     = 2'b00;
      end
      op_i_type_jump      : //i_jalr
        begin
        ctrl_o.rf_rw_en    = 1'b1;
        ctrl_o.imm_sel     = 3'b000;
        ctrl_o.alu_in2_sel = 1'b1;
        ctrl_o.wr_en       = 1'b0;
        ctrl_o.result_src  = 2'b10;
        ctrl_o.rw_type     = 2'b00;
      end
      op_u_type_jump      : //u_jal
        begin
        ctrl_o.rf_rw_en    = 1'b1;
        ctrl_o.imm_sel     = 3'b011;
        ctrl_o.alu_in2_sel = 1'b0;
        ctrl_o.wr_en       = 1'b0;
        ctrl_o.result_src  = 2'b10;
        ctrl_o.rw_type     = 2'b00;
      end
      op_u_type_auipc: begin
        ctrl_o.rf_rw_en    = 1'b1;
        ctrl_o.imm_sel     = 3'b100;
        ctrl_o.alu_in2_sel = 1'b1;
        ctrl_o.wr_en       = 1'b0;
        ctrl_o.result_src  = 2'b00;
        ctrl_o.rw_type     = 2'b00;
      end
      op_u_type_load: begin
        ctrl_o.rf_rw_en    = 1'b1;
        ctrl_o.imm_sel     = 3'b100;
        ctrl_o.alu_in2_sel = 1'b1;
        ctrl_o.wr_en       = 1'b0;
        ctrl_o.result_src  = 2'b00;
        ctrl_o.rw_type     = 2'b00;
      end
      default: begin
        ctrl_o.rf_rw_en    = 1'b0;
        ctrl_o.imm_sel     = 3'b000;
        ctrl_o.alu_in2_sel = 1'b0;
        ctrl_o.wr_en       = 1'b0;
        ctrl_o.result_src  = 2'b00;
        ctrl_o.rw_type     = 2'b00;
      end
    endcase
  end

endmodule
