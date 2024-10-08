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

  typedef enum logic [2:0] {
    NO_IMM,
    I_IMM,
    I_USIMM,
    S_IMM,
    B_IMM,
    U_IMM,
    J_IMM
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
    OP_LUI
  } alu_op_e;

  typedef struct packed {
    logic [6:0] funct7;
    logic [4:0] r2_addr;
    logic [4:0] r1_addr;
    logic [2:0] funct3;
    logic [4:0] rd_addr;
    logic [6:0] opcode;
  } inst_t;

  typedef struct packed {
    logic [XLEN-1:0] pc;
    logic [XLEN-1:0] pc4;
    logic [XLEN-1:0] pc2;
    inst_t           inst;
    logic            is_comp;
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
  } pipe2_t;

  typedef struct packed {
    logic [XLEN-1:0] pc4;
    logic [XLEN-1:0] pc2;
    logic            is_comp;
    logic            rf_rw_en;
    logic            wr_en;
    size_e           rw_size;
    logic [1:0]      result_src;
    logic            ld_op_sign;
    logic [4:0]      rd_addr;
    logic [XLEN-1:0] alu_result;
    logic [XLEN-1:0] write_data;
  } pipe3_t;

  typedef struct packed {
    logic [XLEN-1:0] pc4;
    logic [XLEN-1:0] pc2;
    logic            is_comp;
    logic            rf_rw_en;
    logic [1:0]      result_src;
    logic [4:0]      rd_addr;
    logic [XLEN-1:0] alu_result;
    logic [XLEN-1:0] read_data;
  } pipe4_t;

  typedef struct packed {
    logic       rf_rw_en;
    imm_e       imm_sel;
    logic       wr_en;
    size_e      rw_size;
    logic [1:0] result_src;
    alu_op_e    alu_ctrl;
    pc_sel_e    pc_sel;
    logic [1:0] alu_in1_sel;
    logic       alu_in2_sel;
    logic       ld_op_sign;
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

  typedef struct packed {
    logic            taken;
    logic [XLEN-1:0] pc;
  } predict_info_t;
endpackage
