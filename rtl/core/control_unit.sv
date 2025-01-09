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
    input  inst_t inst_i,
    output ctrl_t ctrl_o
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
  // ---- CSR
  logic CSR_RW;  // rs1 --> zero exteded csr --> rd
  logic CSR_RS;  // set_mask[rs1] --> zero exteded csr --> rd
  logic CSR_RC;  // clear_mask[rs1] --> zero exteded csr --> rd
  logic CSR_RWI;  // 
  logic CSR_RSI;  // 
  logic CSR_RCI;  // 

  logic ecall;
  logic ebreak;
  logic mret;
  logic illegal_shift;

  always_comb begin
    r_add              = (inst_i.opcode == op_r_type) && (inst_i.funct3 == 3'd0) && (inst_i.funct7[5] == 1'b0) && (inst_i.funct7[0] == 1'b0);
    r_sub              = (inst_i.opcode == op_r_type) && (inst_i.funct3 == 3'd0) && (inst_i.funct7[5] == 1'b1) && (inst_i.funct7[0] == 1'b0);
    r_sll              = (inst_i.opcode == op_r_type) && (inst_i.funct3 == 3'd1) && (inst_i.funct7[5] == 1'b0) && (inst_i.funct7[0] == 1'b0);
    r_slt              = (inst_i.opcode == op_r_type) && (inst_i.funct3 == 3'd2) && (inst_i.funct7[5] == 1'b0) && (inst_i.funct7[0] == 1'b0);
    r_sltu             = (inst_i.opcode == op_r_type) && (inst_i.funct3 == 3'd3) && (inst_i.funct7[5] == 1'b0) && (inst_i.funct7[0] == 1'b0);
    r_xor              = (inst_i.opcode == op_r_type) && (inst_i.funct3 == 3'd4) && (inst_i.funct7[5] == 1'b0) && (inst_i.funct7[0] == 1'b0);
    r_srl              = (inst_i.opcode == op_r_type) && (inst_i.funct3 == 3'd5) && (inst_i.funct7[5] == 1'b0) && (inst_i.funct7[0] == 1'b0);
    r_sra              = (inst_i.opcode == op_r_type) && (inst_i.funct3 == 3'd5) && (inst_i.funct7[5] == 1'b1) && (inst_i.funct7[0] == 1'b0);
    r_or               = (inst_i.opcode == op_r_type) && (inst_i.funct3 == 3'd6) && (inst_i.funct7[5] == 1'b0) && (inst_i.funct7[0] == 1'b0);
    r_and              = (inst_i.opcode == op_r_type) && (inst_i.funct3 == 3'd7) && (inst_i.funct7[5] == 1'b0) && (inst_i.funct7[0] == 1'b0);
    i_addi             = (inst_i.opcode == op_i_type) && (inst_i.funct3 == 3'd0);
    i_slti             = (inst_i.opcode == op_i_type) && (inst_i.funct3 == 3'd2);
    i_sltiu            = (inst_i.opcode == op_i_type) && (inst_i.funct3 == 3'd3);
    i_xori             = (inst_i.opcode == op_i_type) && (inst_i.funct3 == 3'd4);
    i_ori              = (inst_i.opcode == op_i_type) && (inst_i.funct3 == 3'd6);
    i_andi             = (inst_i.opcode == op_i_type) && (inst_i.funct3 == 3'd7);
    i_slli             = (inst_i.opcode == op_i_type) && (inst_i.funct3 == 3'd1);
    i_srli             = (inst_i.opcode == op_i_type) && (inst_i.funct3 == 3'd5) && (inst_i.funct7[5] == 1'b0);
    i_srai             = (inst_i.opcode == op_i_type) && (inst_i.funct3 == 3'd5) && (inst_i.funct7[5] == 1'b1);
    r_mul              = (inst_i.opcode == op_r_type) && (inst_i.funct3 == 3'd0) && (inst_i.funct7[5] == 1'b0) && (inst_i.funct7[0] == 1'b1);
    r_mulh             = (inst_i.opcode == op_r_type) && (inst_i.funct3 == 3'd1) && (inst_i.funct7[5] == 1'b0) && (inst_i.funct7[0] == 1'b1);
    r_mulhsu           = (inst_i.opcode == op_r_type) && (inst_i.funct3 == 3'd2) && (inst_i.funct7[5] == 1'b0) && (inst_i.funct7[0] == 1'b1);
    r_mulhu            = (inst_i.opcode == op_r_type) && (inst_i.funct3 == 3'd3) && (inst_i.funct7[5] == 1'b0) && (inst_i.funct7[0] == 1'b1);
    r_rem              = (inst_i.opcode == op_r_type) && (inst_i.funct3 == 3'd6) && (inst_i.funct7[5] == 1'b0) && (inst_i.funct7[0] == 1'b1);
    r_remu             = (inst_i.opcode == op_r_type) && (inst_i.funct3 == 3'd7) && (inst_i.funct7[5] == 1'b0) && (inst_i.funct7[0] == 1'b1);
    r_div              = (inst_i.opcode == op_r_type) && (inst_i.funct3 == 3'd4) && (inst_i.funct7[5] == 1'b0) && (inst_i.funct7[0] == 1'b1);
    r_divu             = (inst_i.opcode == op_r_type) && (inst_i.funct3 == 3'd5) && (inst_i.funct7[5] == 1'b0) && (inst_i.funct7[0] == 1'b1);
    i_lb               = (inst_i.opcode == op_i_type_load) && (inst_i.funct3 == 3'd0);
    i_lh               = (inst_i.opcode == op_i_type_load) && (inst_i.funct3 == 3'd1);
    i_lw               = (inst_i.opcode == op_i_type_load) && (inst_i.funct3 == 3'd2);
    i_lbu              = (inst_i.opcode == op_i_type_load) && (inst_i.funct3 == 3'd4);
    i_lhu              = (inst_i.opcode == op_i_type_load) && (inst_i.funct3 == 3'd5);
    s_sb               = (inst_i.opcode == op_s_type) && (inst_i.funct3 == 3'd0);
    s_sh               = (inst_i.opcode == op_s_type) && (inst_i.funct3 == 3'd1);
    s_sw               = (inst_i.opcode == op_s_type) && (inst_i.funct3 == 3'd2);
    b_beq              = (inst_i.opcode == op_b_type) && (inst_i.funct3 == 3'd0);
    b_bne              = (inst_i.opcode == op_b_type) && (inst_i.funct3 == 3'd1);
    b_blt              = (inst_i.opcode == op_b_type) && (inst_i.funct3 == 3'd4);
    b_bge              = (inst_i.opcode == op_b_type) && (inst_i.funct3 == 3'd5);
    b_bltu             = (inst_i.opcode == op_b_type) && (inst_i.funct3 == 3'd6);
    b_bgeu             = (inst_i.opcode == op_b_type) && (inst_i.funct3 == 3'd7);
    u_lui              = (inst_i.opcode == op_u_type_load);
    u_auipc            = (inst_i.opcode == op_u_type_auipc);
    u_jal              = (inst_i.opcode == op_u_type_jump);
    i_jalr             = (inst_i.opcode == op_i_type_jump);

    CSR_RW             = (inst_i.opcode == system) && inst_i.funct3 == 3'd1;
    CSR_RS             = (inst_i.opcode == system) && inst_i.funct3 == 3'd2;
    CSR_RC             = (inst_i.opcode == system) && inst_i.funct3 == 3'd3;
    CSR_RWI            = (inst_i.opcode == system) && inst_i.funct3 == 3'd5;
    CSR_RSI            = (inst_i.opcode == system) && inst_i.funct3 == 3'd6;
    CSR_RCI            = (inst_i.opcode == system) && inst_i.funct3 == 3'd7;

    ecall              = (inst_i.opcode == system) && inst_i[21:20] == 2'd0;
    ebreak             = (inst_i.opcode == system) && inst_i[21:20] == 2'd1;
    mret               = (inst_i.opcode == system) && inst_i[21:20] == 2'd2;

    illegal_shift = (r_sll || i_srli || r_sra) && inst_i[25];
  
    ctrl_o.exc_type = NO_EXCEPTION;
    case (1'b1)
      ecall         : ctrl_o.exc_type = ECALL; 
      ebreak        : ctrl_o.exc_type = EBREAK; 
      illegal_shift : ctrl_o.exc_type = ILLEGAL_INSTRUCTION;
    endcase

    ctrl_o.alu_in1_sel = u_auipc ? 2'd2 : (i_jalr ? 2'b1 : 2'b0);

    ctrl_o.ld_op_sign  = !(i_lhu || i_lbu) && (i_lh || i_lb);

    case (1'b1)
      r_add, i_lb, i_lh, i_lw, i_lbu, i_lhu, i_addi, s_sb, s_sh, s_sw, b_beq, b_bne, b_blt, b_bge, b_bltu, b_bgeu, u_jal, i_jalr: ctrl_o.alu_ctrl = OP_ADD;
      r_sub:                                                                                                                      ctrl_o.alu_ctrl = OP_SUB;
      r_sll, i_slli:                                                                                                              ctrl_o.alu_ctrl = OP_SLL;
      r_slt, i_slti:                                                                                                              ctrl_o.alu_ctrl = OP_SLT;
      r_sltu, i_sltiu:                                                                                                            ctrl_o.alu_ctrl = OP_SLTU;
      r_xor, i_xori:                                                                                                              ctrl_o.alu_ctrl = OP_XOR;
      r_srl, i_srli:                                                                                                              ctrl_o.alu_ctrl = OP_SRL;
      r_sra, i_srai:                                                                                                              ctrl_o.alu_ctrl = OP_SRA;
      r_or, i_ori:                                                                                                                ctrl_o.alu_ctrl = OP_OR;
      r_and, i_andi:                                                                                                              ctrl_o.alu_ctrl = OP_AND;
      r_mul:                                                                                                                      ctrl_o.alu_ctrl = OP_MUL;
      r_mulh:                                                                                                                     ctrl_o.alu_ctrl = OP_MULH;
      r_mulhsu:                                                                                                                   ctrl_o.alu_ctrl = OP_MULHSU;
      r_mulhu:                                                                                                                    ctrl_o.alu_ctrl = OP_MULHU;
      r_div:                                                                                                                      ctrl_o.alu_ctrl = OP_DIV;
      r_divu:                                                                                                                     ctrl_o.alu_ctrl = OP_DIVU;  // roundin
      r_rem:                                                                                                                      ctrl_o.alu_ctrl = OP_REM;
      r_remu:                                                                                                                     ctrl_o.alu_ctrl = OP_REMU;
      u_lui:                                                                                                                      ctrl_o.alu_ctrl = OP_LUI;
      CSR_RW:                                                                                                                     ctrl_o.alu_ctrl = OP_CSRRW;
      CSR_RS:                                                                                                                     ctrl_o.alu_ctrl = OP_CSRRS;
      CSR_RC:                                                                                                                     ctrl_o.alu_ctrl = OP_CSRRC;
      CSR_RWI:                                                                                                                    ctrl_o.alu_ctrl = OP_CSRRWI;
      CSR_RSI:                                                                                                                    ctrl_o.alu_ctrl = OP_CSRRSI;
      CSR_RCI:                                                                                                                    ctrl_o.alu_ctrl = OP_CSRRCI;
      default:                                                                                                                    ctrl_o.alu_ctrl = OP_ADD;
    endcase

    case (1'b1)
      b_beq:   ctrl_o.pc_sel = BEQ;
      b_bne:   ctrl_o.pc_sel = BNE;
      b_blt:   ctrl_o.pc_sel = BLT;
      b_bge:   ctrl_o.pc_sel = BGE;
      b_bltu:  ctrl_o.pc_sel = BLTU;
      b_bgeu:  ctrl_o.pc_sel = BGEU;
      i_jalr:  ctrl_o.pc_sel = JALR;
      u_jal:   ctrl_o.pc_sel = JAL;
      default: ctrl_o.pc_sel = NO_BJ;
    endcase

    case (inst_i.opcode)
      op_r_type: begin
        ctrl_o.rf_rw_en    = 1'b1;
        ctrl_o.csr_or_data = 1'b0;
        ctrl_o.rd_csr      = 1'b0;
        ctrl_o.wr_csr      = 1'b0;
        ctrl_o.csr_idx     = inst_i[31:20];
        ctrl_o.imm_sel     = NO_IMM;
        ctrl_o.alu_in2_sel = 1'b0;
        ctrl_o.wr_en       = 1'b0;
        ctrl_o.result_src  = 2'b00;
        ctrl_o.rw_size     = NO_SIZE;
      end
      op_i_type: begin
        ctrl_o.rf_rw_en    = 1'b1;
        ctrl_o.csr_or_data = 1'b0;
        ctrl_o.rd_csr      = 1'b0;
        ctrl_o.wr_csr      = 1'b0;
        ctrl_o.csr_idx     = inst_i[31:20];
        if (i_slli || i_srli || i_srai) begin
          ctrl_o.imm_sel = I_USIMM;
        end else begin
          ctrl_o.imm_sel = I_IMM;
        end
        ctrl_o.alu_in2_sel = 1'b1;
        ctrl_o.wr_en       = 1'b0;
        ctrl_o.result_src  = 2'b00;
        ctrl_o.rw_size     = NO_SIZE;
      end
      op_i_type_load: begin
        ctrl_o.rf_rw_en    = 1'b1;
        ctrl_o.csr_or_data = 1'b0;
        ctrl_o.rd_csr      = 1'b0;
        ctrl_o.wr_csr      = 1'b0;
        ctrl_o.csr_idx     = inst_i[31:20];
        ctrl_o.imm_sel     = I_IMM;
        ctrl_o.alu_in2_sel = 1'b1;
        ctrl_o.wr_en       = 1'b0;
        ctrl_o.result_src  = 2'b01;
        case (1'b1)
          i_lb, i_lbu: ctrl_o.rw_size = BYTE;
          i_lh, i_lhu: ctrl_o.rw_size = HALF_WORD;
          i_lw:        ctrl_o.rw_size = WORD;
          default:     ctrl_o.rw_size = NO_SIZE;
        endcase
      end
      op_s_type: begin
        ctrl_o.rf_rw_en    = 1'b0;
        ctrl_o.csr_or_data = 1'b0;
        ctrl_o.rd_csr      = 1'b0;
        ctrl_o.wr_csr      = 1'b0;
        ctrl_o.csr_idx     = inst_i[31:20];
        ctrl_o.imm_sel     = S_IMM;
        ctrl_o.alu_in2_sel = 1'b1;
        ctrl_o.wr_en       = 1'b1;
        case (1'b1)  // uniqeu case
          s_sb:    ctrl_o.rw_size = BYTE;
          s_sh:    ctrl_o.rw_size = HALF_WORD;
          s_sw:    ctrl_o.rw_size = WORD;
          default: ctrl_o.rw_size = NO_SIZE;
        endcase
        ctrl_o.result_src = 2'b00;
      end
      op_b_type: begin
        ctrl_o.rf_rw_en    = 1'b0;
        ctrl_o.csr_or_data = 1'b0;
        ctrl_o.rd_csr      = 1'b0;
        ctrl_o.wr_csr      = 1'b0;
        ctrl_o.csr_idx     = inst_i[31:20];
        ctrl_o.imm_sel     = B_IMM;
        ctrl_o.alu_in2_sel = 1'b0;
        ctrl_o.wr_en       = 1'b0;
        ctrl_o.result_src  = 2'b00;
        ctrl_o.rw_size     = NO_SIZE;
      end
      op_i_type_jump      : //i_jalr
        begin
        ctrl_o.rf_rw_en    = 1'b1;
        ctrl_o.csr_or_data = 1'b0;
        ctrl_o.rd_csr      = 1'b0;
        ctrl_o.wr_csr      = 1'b0;
        ctrl_o.csr_idx     = inst_i[31:20];
        ctrl_o.imm_sel     = I_IMM;
        ctrl_o.alu_in2_sel = 1'b1;
        ctrl_o.wr_en       = 1'b0;
        ctrl_o.result_src  = 2'b10;
        ctrl_o.rw_size     = NO_SIZE;
      end
      op_u_type_jump      : //u_jalr
        begin
        ctrl_o.rf_rw_en    = 1'b1;
        ctrl_o.csr_or_data = 1'b0;
        ctrl_o.rd_csr      = 1'b0;
        ctrl_o.wr_csr      = 1'b0;
        ctrl_o.csr_idx     = inst_i[31:20];
        ctrl_o.imm_sel     = J_IMM;
        ctrl_o.alu_in2_sel = 1'b0;
        ctrl_o.wr_en       = 1'b0;
        ctrl_o.result_src  = 2'b10;
        ctrl_o.rw_size     = NO_SIZE;
      end
      op_u_type_auipc: begin
        ctrl_o.rf_rw_en    = 1'b1;
        ctrl_o.csr_or_data = 1'b0;
        ctrl_o.rd_csr      = 1'b0;
        ctrl_o.wr_csr      = 1'b0;
        ctrl_o.csr_idx     = inst_i[31:20];
        ctrl_o.imm_sel     = U_IMM;
        ctrl_o.alu_in2_sel = 1'b1;
        ctrl_o.wr_en       = 1'b0;
        ctrl_o.result_src  = 2'b00;
        ctrl_o.rw_size     = NO_SIZE;
      end
      op_u_type_load: begin
        ctrl_o.rf_rw_en    = 1'b1;
        ctrl_o.csr_or_data = 1'b0;
        ctrl_o.rd_csr      = 1'b0;
        ctrl_o.wr_csr      = 1'b0;
        ctrl_o.csr_idx     = inst_i[31:20];
        ctrl_o.imm_sel     = U_IMM;
        ctrl_o.alu_in2_sel = 1'b1;
        ctrl_o.wr_en       = 1'b0;
        ctrl_o.result_src  = 2'b00;
        ctrl_o.rw_size     = NO_SIZE;
      end
      system: begin
        case (1'b1)
          CSR_RW, CSR_RS, CSR_RC: begin
            ctrl_o.rf_rw_en    = 1'b1;
            ctrl_o.csr_or_data = 1'b1;
            ctrl_o.rd_csr      = CSR_RW ? inst_i.rd_addr != 0 : 1'b1;
            ctrl_o.wr_csr      = (CSR_RS || CSR_RC) ? inst_i.r1_addr != 0 : 1'b1;
            ctrl_o.csr_idx     = inst_i[31:20];
            ctrl_o.imm_sel     = NO_IMM;
            ctrl_o.alu_in2_sel = 1'b0;
            ctrl_o.wr_en       = 1'b0;
            ctrl_o.result_src  = 2'b00;
            ctrl_o.rw_size     = NO_SIZE;
          end
          CSR_RWI, CSR_RSI, CSR_RCI: begin
            ctrl_o.rf_rw_en    = 1'b1;
            ctrl_o.csr_or_data = 1'b1;
            ctrl_o.rd_csr      = CSR_RW ? inst_i.rd_addr != 0 : 1'b1;
            ctrl_o.wr_csr      = (CSR_RS || CSR_RC) ? inst_i.r1_addr != 0 : 1'b1;
            ctrl_o.csr_idx     = inst_i[31:20];
            ctrl_o.imm_sel     = CSR_IMM;
            ctrl_o.alu_in2_sel = 1'b1;
            ctrl_o.wr_en       = 1'b0;
            ctrl_o.result_src  = 2'b00;
            ctrl_o.rw_size     = NO_SIZE;
          end
        endcase
      end
      default: begin
        ctrl_o.rf_rw_en    = 1'b0;
        ctrl_o.csr_or_data = 1'b0;
        ctrl_o.rd_csr      = 1'b0;
        ctrl_o.wr_csr      = 1'b0;
        ctrl_o.csr_idx     = inst_i[31:20];
        ctrl_o.imm_sel     = NO_IMM;
        ctrl_o.alu_in2_sel = 1'b0;
        ctrl_o.wr_en       = 1'b0;
        ctrl_o.result_src  = 2'b00;
        ctrl_o.rw_size     = NO_SIZE;
      end
    endcase
  end

endmodule
