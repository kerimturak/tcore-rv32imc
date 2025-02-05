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
// Design Name:    tcore_param                                                //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    tcore_param                                                //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
package tcore_param;
  localparam XLEN = 32;
  localparam BLK_SIZE = 128;

  localparam [6:0] system = 7'b11100_11;
  localparam [6:0] op_fence_i = 7'b00011_11;
  localparam [6:0] op_r_type = 7'b01100_11;  // 51, add, sub, sll, slt, sltu, xor, srl, sra, or, and,
  localparam [6:0] op_i_type_load = 7'b00000_11;  // lb, lh, lw, lbu, lhu,
  localparam [6:0] op_i_type = 7'b00100_11;  // addi, slti, sltiu, xori, ori, andi, slli, srli, srai,
  localparam [6:0] op_s_type = 7'b01000_11;  // sb, sh, sw,
  localparam [6:0] op_b_type = 7'b11000_11;  // beq, bne, blt, bge, bltu, bgeu,
  localparam [6:0] op_i_type_jump = 7'b11001_11;  // jal
  localparam [6:0] op_u_type_load = 7'b01101_11;  // u type load
  localparam [6:0] op_u_type_jump = 7'b11011_11;
  localparam [6:0] op_u_type_auipc = 7'b00101_11;

  // UART
  localparam UART_BYTE = 8;
  localparam UART_NUM_BITS = 11;
  localparam NO_BITS_SENT = $clog2(UART_NUM_BITS);
  localparam NO_BITS_RCVD = $clog2(UART_NUM_BITS);
  localparam UART_OVER_SAMPL = 16;
  localparam UART_CNTR = $clog2(UART_OVER_SAMPL);

  localparam IC_WAY = 8;
  localparam DC_WAY = 8;
  localparam IC_CAPACITY = 8 * (2 ** 10) * 8;
  localparam DC_CAPACITY = 8 * (2 ** 10) * 8;
  localparam BUFFER_CAPACITY = 8 * BLK_SIZE;

  localparam Mul_Type = 0;  // 1: dadda 0: wallace


  typedef enum logic [5:0] { 
    Null_Instr_Type,
    instr_invalid,
    r_add,
    r_sub,
    r_sll,
    r_slt,
    r_sltu,
    r_xor,
    r_srl,
    r_sra,
    r_or,
    r_and,
    i_addi,
    i_slti,
    i_sltiu,
    i_xori,
    i_ori,
    i_andi,
    i_slli,
    i_srli,
    i_srai,
    r_mul,
    r_mulh,
    r_mulhsu,
    r_mulhu,
    r_rem,
    r_remu,
    r_div,
    r_divu,
    i_lb ,
    i_lh ,
    i_lw ,
    i_lbu,
    i_lhu,
    s_sb,
    s_sh,
    s_sw,
    b_beq,
    b_bne,
    b_blt,
    b_bge,
    b_bltu,
    b_bgeu,
    u_lui,
    u_auipc,
    u_jal,
    i_jalr,
    CSR_RW,
    CSR_RS,
    CSR_RC,
    CSR_RWI,
    CSR_RSI,
    CSR_RCI,
    ecall,
    ebreak,
    mret,
    fence_i
  } instr_type_e;

  typedef struct packed {
    logic [6:0] funct7;
    logic [4:0] r2_addr;
    logic [4:0] r1_addr;
    logic [2:0] funct3;
    logic [4:0] rd_addr;
    logic [6:0] opcode;
  } inst_t;

  function instr_type_e resolved_instr_type;
    input inst_t inst_i;

    case (inst_i.opcode)
          op_fence_i : resolved_instr_type = inst_i.funct3 == '0 ? fence_i : instr_invalid;
          op_r_type: begin
            if (inst_i.funct7[0]) begin
              case (inst_i.funct3)
                3'd0: resolved_instr_type = r_mul   ;
                3'd1: resolved_instr_type = r_mulh  ;
                3'd2: resolved_instr_type = r_mulhsu;
                3'd3: resolved_instr_type = r_mulhu ;
                3'd4: resolved_instr_type = r_div   ;
                3'd5: resolved_instr_type = r_divu  ;
                3'd6: resolved_instr_type = r_rem   ;
                3'd7: resolved_instr_type = r_remu  ;
                default: resolved_instr_type = instr_invalid;
              endcase
            end else begin
              case (inst_i.funct3)
                3'd0: resolved_instr_type = (inst_i.funct7[5] == 1'b0) ? r_add  : r_sub;
                3'd1: resolved_instr_type = r_sll;
                3'd2: resolved_instr_type = r_slt;
                3'd3: resolved_instr_type = r_sltu;
                3'd4: resolved_instr_type = r_xor;
                3'd5: resolved_instr_type = (inst_i.funct7[5] == 1'b0) ? r_srl : r_sra;
                3'd6: resolved_instr_type = r_or;
                3'd7: resolved_instr_type = r_and;
                default: resolved_instr_type = instr_invalid;
              endcase
            end
              
          end

          op_i_type_load: begin
              case (inst_i.funct3)
                  3'd0: resolved_instr_type = i_lb ;
                  3'd1: resolved_instr_type = i_lh ;
                  3'd2: resolved_instr_type = i_lw ;
                  3'd4: resolved_instr_type = i_lbu;
                  3'd5: resolved_instr_type = i_lhu;
                  default: resolved_instr_type = instr_invalid;
              endcase
          end

          op_i_type: begin
              case (inst_i.funct3)
                  3'd0: resolved_instr_type = i_addi;
                  3'd2: resolved_instr_type = i_slti;
                  3'd3: resolved_instr_type = i_sltiu;
                  3'd4: resolved_instr_type = i_xori;
                  3'd6: resolved_instr_type = i_ori;
                  3'd7: resolved_instr_type = i_andi;
                  3'd1: resolved_instr_type = i_slli;
                  3'd5: resolved_instr_type = (inst_i.funct7[5] == 1'b0) ? i_srli : i_srai;
                  default: resolved_instr_type = instr_invalid;
              endcase
          end

          op_s_type: begin
              case (inst_i.funct3)
                  3'd0: resolved_instr_type = s_sb;
                  3'd1: resolved_instr_type = s_sh;
                  3'd2: resolved_instr_type = s_sw;
                  default: resolved_instr_type = instr_invalid;
              endcase
          end

          op_b_type: begin
              case (inst_i.funct3)
                  3'd0: resolved_instr_type = b_beq;
                  3'd1: resolved_instr_type = b_bne;
                  3'd4: resolved_instr_type = b_blt;
                  3'd5: resolved_instr_type = b_bge;
                  3'd6: resolved_instr_type = b_bltu;
                  3'd7: resolved_instr_type = b_bgeu;
                  default: resolved_instr_type = instr_invalid;
              endcase
          end

          op_u_type_load: resolved_instr_type = u_lui;
          op_u_type_auipc: resolved_instr_type = u_auipc;
          op_u_type_jump: resolved_instr_type = u_jal;
          op_i_type_jump: resolved_instr_type = i_jalr;

          system: begin
              case (inst_i.funct3)
                  3'd1: resolved_instr_type = CSR_RW;
                  3'd2: resolved_instr_type = CSR_RS;
                  3'd3: resolved_instr_type = CSR_RC;
                  3'd5: resolved_instr_type = CSR_RWI;
                  3'd6: resolved_instr_type = CSR_RSI;
                  3'd7: resolved_instr_type = CSR_RCI;
                  default: begin
                      if (inst_i[21:20] == 2'd0) resolved_instr_type = ecall;
                      else if (inst_i[21:20] == 2'd1) resolved_instr_type = ebreak;
                      else if (inst_i[21:20] == 2'd2) resolved_instr_type = mret;
                      else resolved_instr_type = instr_invalid;
                  end
              endcase
          end

          default: resolved_instr_type = instr_invalid; // Geçersiz talimat
      endcase
      return resolved_instr_type;
  endfunction

  typedef enum logic [3:0] { 
    INSTR_MISALIGNED,
    INSTR_ACCESS_FAULT,
    ILLEGAL_INSTRUCTION,
    EBREAK,
    LOAD_MISALIGNED,
    LOAD_ACCESS_FAULT,
    STORE_MISALIGNED,
    STORE_ACCESS_FAULT,
    ECALL,
    NO_EXCEPTION
  } exc_type_e;

  typedef enum logic [2:0] {
    CSRRW  = 3'h1,
    CSRRS  = 3'h2,
    CSRRC  = 3'h3,
    CSRRWI = 3'h5,
    CSRRSI = 3'h6,
    CSRRCI = 3'h7
  } csr_op_t;

  typedef enum logic [3:0] {
    NO_BJ,
    BEQ,
    BNE,
    BLT,
    BGE,
    BLTU,
    BGEU,
    JALR,
    JAL
  } pc_sel_e;

  typedef enum logic [1:0] {
    NO_SIZE,
    BYTE,
    HALF_WORD,
    WORD
  } size_e;

  typedef enum logic [3:0] {
    NO_IMM,
    I_IMM,
    I_USIMM,
    S_IMM,
    B_IMM,
    U_IMM,
    J_IMM,
    CSR_IMM
  } imm_e;

  typedef enum logic [4:0] {
    OP_ADD,
    OP_SUB,
    OP_SLL,
    OP_SLT,
    OP_SLTU,
    OP_XOR,
    OP_SRL,
    OP_SRA,
    OP_OR,
    OP_AND,
    OP_MUL,
    OP_MULH,
    OP_MULHSU,
    OP_MULHU,
    OP_DIV,
    OP_DIVU,
    OP_REM,
    OP_REMU,
    OP_LUI,
    OP_CSRRW,
    OP_CSRRS,
    OP_CSRRC,
    OP_CSRRWI,
    OP_CSRRSI,
    OP_CSRRCI
  } alu_op_e;

  typedef struct packed {
    logic            taken;
    logic [XLEN-1:0] pc;
  } predict_info_t;

  typedef struct packed {
    logic [XLEN-1:0] pc;
    logic [XLEN-1:0] pc4;
    logic [XLEN-1:0] pc2;
    inst_t           inst;
    logic            is_comp;
    exc_type_e       exc_type;
    instr_type_e     instr_type;
    predict_info_t   spec;
  } pipe1_t;

  typedef struct packed {
    logic [XLEN-1:0] pc;
    logic [XLEN-1:0] pc4;
    logic [XLEN-1:0] pc2;
    logic            is_comp;
    logic            rf_rw_en;
    logic            wr_en;
    size_e           rw_size;
    logic [1:0]      result_src;
    alu_op_e         alu_ctrl;
    pc_sel_e         pc_sel;
    logic [1:0]      alu_in1_sel;
    logic            alu_in2_sel;
    logic            ld_op_sign;
    logic [XLEN-1:0] r1_data;
    logic [XLEN-1:0] r2_data;
    logic [4:0]      r1_addr;
    logic [4:0]      r2_addr;
    logic [4:0]      rd_addr;      //! destination register address
    logic [XLEN-1:0] imm;          //! immediate generater output
    logic            rd_csr;
    logic            wr_csr;
    logic [11:0]     csr_idx;
    logic            csr_or_data;
    exc_type_e       exc_type;
    instr_type_e     instr_type;
    predict_info_t   spec;
  } pipe2_t;

  typedef struct packed {
    logic [XLEN-1:0] pc4;
    logic [XLEN-1:0] pc2;
    logic [XLEN-1:0] pc;
    logic            is_comp;
    logic            rf_rw_en;
    logic            wr_en;
    size_e           rw_size;
    logic [1:0]      result_src;
    logic            ld_op_sign;
    logic [4:0]      rd_addr;
    logic [XLEN-1:0] alu_result;
    logic [XLEN-1:0] write_data;
    exc_type_e       exc_type;
    logic     [XLEN-1:0] mtvec;
  } pipe3_t;

  typedef struct packed {
    logic [XLEN-1:0] pc4;
    logic [XLEN-1:0] pc;
    logic [XLEN-1:0] pc2;
    logic            is_comp;
    logic            rf_rw_en;
    logic [1:0]      result_src;
    logic [4:0]      rd_addr;
    logic [XLEN-1:0] alu_result;
    logic [XLEN-1:0] read_data;
    exc_type_e       exc_type;
    logic     [XLEN-1:0] mtvec;
  } pipe4_t;

  typedef struct packed {
    logic        rf_rw_en;
    imm_e        imm_sel;
    logic        wr_en;
    size_e       rw_size;
    logic [1:0]  result_src;
    alu_op_e     alu_ctrl;
    pc_sel_e     pc_sel;
    logic [1:0]  alu_in1_sel;
    logic        alu_in2_sel;
    logic        ld_op_sign;
    logic        rd_csr;
    logic        wr_csr;
    logic [11:0] csr_idx;
    logic        csr_or_data;
    exc_type_e   exc_type;
  } ctrl_t;

  typedef struct packed {
    logic            valid;
    logic            ready;
    logic [XLEN-1:0] addr;
    logic            uncached;
  } icache_req_t;

  typedef struct packed {
    logic                valid;
    logic                ready;
    logic [BLK_SIZE-1:0] blk;
  } icache_res_t;

  typedef struct packed {
    logic        valid;
    logic        ready;
    logic [31:0] blk;
  } gbuff_res_t;

  typedef struct packed {
    logic                valid;
    logic                ready;
    logic [BLK_SIZE-1:0] blk;
  } ilowX_res_t;

  typedef struct packed {
    logic            valid;
    logic            ready;
    logic [XLEN-1:0] addr;
    logic            uncached;
  } ilowX_req_t;

  typedef struct packed {
    logic            valid;
    logic            ready;
    logic [XLEN-1:0] addr;
    logic            uncached;
    logic            rw;
    size_e           rw_size;
    logic [31:0]     data;
  } dcache_req_t;

  typedef struct packed {
    logic        valid;
    logic        ready;
    logic [31:0] data;
  } dcache_res_t;

  typedef struct packed {
    logic                valid;
    logic                ready;
    logic [BLK_SIZE-1:0] data;
  } dlowX_res_t;

  typedef struct packed {
    logic                valid;
    logic                ready;
    logic [XLEN-1:0]     addr;
    size_e               rw_size;
    logic                rw;
    logic [BLK_SIZE-1:0] data;
    logic                uncached;
  } dlowX_req_t;

  typedef struct packed {
    logic                valid;
    logic [XLEN-1:0]     addr;
    logic [BLK_SIZE-1:0] data;
    logic [15:0]         rw;
  } mem_req_t;

endpackage
