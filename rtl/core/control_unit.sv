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
    input  inst_t             inst_i,
    input  instr_type_e       instr_type_i,
    output ctrl_t             ctrl_o
);

  logic illegal_shift;

  always_comb begin
    illegal_shift = (instr_type_i == r_sll || instr_type_i == i_srli || instr_type_i == r_sra) && inst_i[25];
    ctrl_o.exc_type = illegal_shift ? ILLEGAL_INSTRUCTION : NO_EXCEPTION;
    ctrl_o.alu_in1_sel = instr_type_i == u_auipc ? 2'd2 : (instr_type_i == i_jalr ? 2'b1 : 2'b0);
    ctrl_o.ld_op_sign  = !(instr_type_i == i_lhu || instr_type_i == i_lbu) && (instr_type_i == i_lh || instr_type_i == i_lb);
    case (instr_type_i)
      r_add, i_lb, i_lh, i_lw, i_lbu,
      i_lhu, i_addi, s_sb, s_sh, s_sw,
      b_beq, b_bne, b_blt, b_bge, b_bltu,
      b_bgeu, u_jal, i_jalr:               ctrl_o.alu_ctrl = OP_ADD;
      r_sub:                               ctrl_o.alu_ctrl = OP_SUB;
      r_sll, i_slli:                       ctrl_o.alu_ctrl = OP_SLL;
      r_slt, i_slti:                       ctrl_o.alu_ctrl = OP_SLT;
      r_sltu, i_sltiu:                     ctrl_o.alu_ctrl = OP_SLTU;
      r_xor, i_xori:                       ctrl_o.alu_ctrl = OP_XOR;
      r_srl, i_srli:                       ctrl_o.alu_ctrl = OP_SRL;
      r_sra, i_srai:                       ctrl_o.alu_ctrl = OP_SRA;
      r_or, i_ori:                         ctrl_o.alu_ctrl = OP_OR;
      r_and, i_andi:                       ctrl_o.alu_ctrl = OP_AND;
      r_mul:                               ctrl_o.alu_ctrl = OP_MUL;
      r_mulh:                              ctrl_o.alu_ctrl = OP_MULH;
      r_mulhsu:                            ctrl_o.alu_ctrl = OP_MULHSU;
      r_mulhu:                             ctrl_o.alu_ctrl = OP_MULHU;
      r_div:                               ctrl_o.alu_ctrl = OP_DIV;
      r_divu:                              ctrl_o.alu_ctrl = OP_DIVU;  // roundin
      r_rem:                               ctrl_o.alu_ctrl = OP_REM;
      r_remu:                              ctrl_o.alu_ctrl = OP_REMU;
      u_lui:                               ctrl_o.alu_ctrl = OP_LUI;
      CSR_RW:                              ctrl_o.alu_ctrl = OP_CSRRW;
      CSR_RS:                              ctrl_o.alu_ctrl = OP_CSRRS;
      CSR_RC:                              ctrl_o.alu_ctrl = OP_CSRRC;
      CSR_RWI:                             ctrl_o.alu_ctrl = OP_CSRRWI;
      CSR_RSI:                             ctrl_o.alu_ctrl = OP_CSRRSI;
      CSR_RCI:                             ctrl_o.alu_ctrl = OP_CSRRCI;
      default:                             ctrl_o.alu_ctrl = OP_ADD;
    endcase

    case (instr_type_i)
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
        if (instr_type_i == i_slli || instr_type_i ==i_srli || instr_type_i ==i_srai) begin
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
        case (instr_type_i)
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
        case (instr_type_i)  // uniqeu case
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
        case (instr_type_i)
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
