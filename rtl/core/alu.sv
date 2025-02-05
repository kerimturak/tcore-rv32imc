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
// Design Name:    ALU                                                        //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Performs arithmetic and logical operations on input data.  //
//                 Key functions include addition, subtraction, and bitwise   //
//                 operations.                                                //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`include "tcore_defines.svh"
module alu
  import tcore_param::*;
(
    input  logic               clk_i,
    input  logic               rst_ni,
    input  logic    [XLEN-1:0] csr_rdata_i,
    input  logic    [XLEN-1:0] alu_a_i,
    input  logic    [XLEN-1:0] alu_b_i,
    input  alu_op_e            op_sel_i,
    output logic               alu_stall_o,
    output logic               zero_o,
    output logic               slt_o,
    output logic               sltu_o,
    output logic    [XLEN-1:0] alu_o
);

  // alu intermediate results
  typedef struct packed {
    logic [XLEN-1:0]   ADD;
    logic [XLEN-1:0]   SLT;
    logic [XLEN-1:0]   SLTU;
    logic [XLEN-1:0]   AND;
    logic [XLEN-1:0]   OR;
    logic [XLEN-1:0]   XOR;
    logic [XLEN-1:0]   SLL;
    logic [XLEN-1:0]   SRL;
    logic [XLEN-1:0]   SUB;
    logic [XLEN-1:0]   SRA;
    logic [XLEN-1:0]   LUI;
    logic [XLEN-1:0]   DIV;
    logic [XLEN-1:0]   DIVU;
    logic [XLEN-1:0]   REM;
    logic [XLEN-1:0]   REMU;
    logic [XLEN-1:0]   MUL;
    logic [2*XLEN-1:0] MULH;
    logic [2*XLEN-1:0] MULHSU;
    logic [2*XLEN-1:0] MULHU;
  } result_t;
  result_t              rslt;

  logic    [  XLEN-1:0] abs_A;
  logic    [  XLEN-1:0] abs_B;
  logic                 sign;
  logic                 mul_type;
  logic                 div_type;
  logic                 mul_start;
  logic                 div_start;
  logic    [  XLEN-1:0] mul_op_A;
  logic    [  XLEN-1:0] mul_op_B;
  logic    [  XLEN-1:0] div_op_A;
  logic    [  XLEN-1:0] div_op_B;
  logic    [2*XLEN-1:0] product;
  logic    [  XLEN-1:0] quotient;
  logic    [  XLEN-1:0] reminder;
  logic                 mul_stall;
  logic                 div_stall;
  logic                 alu_stall_q;
  logic                 mul_busy;
  logic                 div_busy;
  logic                 mul_valid;
  logic                 div_valid;
  logic    [2*XLEN-1:0] unsigned_prod;
  logic    [  XLEN-1:0] unsigned_quo;
  logic    [  XLEN-1:0] unsigned_rem;

  always_comb begin
    abs_A = alu_a_i[XLEN-1] ? ~alu_a_i + 1'b1 : alu_a_i;
    abs_B = alu_b_i[XLEN-1] ? ~alu_b_i + 1'b1 : alu_b_i;

    sign = alu_a_i[XLEN-1] ^ alu_b_i[XLEN-1];

    mul_type = op_sel_i inside {[OP_MUL : OP_MULHU]};
    div_type = op_sel_i inside {[OP_DIV : OP_REMU]};

    mul_start = mul_type && !mul_busy && !alu_stall_q;
    div_start = div_type && !div_busy && !alu_stall_q;

    mul_op_A = op_sel_i == OP_MULHU ? $unsigned(alu_a_i) : abs_A;
    mul_op_B = op_sel_i inside {OP_MULHSU, OP_MULHU} ? $unsigned(alu_b_i) : abs_B;

    div_op_A = op_sel_i inside {OP_DIVU, OP_REMU} ? $unsigned(alu_a_i) : abs_A;
    div_op_B = op_sel_i inside {OP_DIVU, OP_REMU} ? $unsigned(alu_b_i) : abs_B;

    product = sign ? ~(unsigned_prod - 1'b1) : unsigned_prod;

    quotient = sign ? ~(unsigned_quo - 1'b1) : unsigned_quo;
    reminder = sign ? ~(unsigned_rem - 1'b1) : unsigned_rem;

    mul_stall = (mul_type && !mul_valid || (mul_valid && mul_start));
    div_stall = (div_type && !div_valid || (div_valid && div_start));
    alu_stall_o = mul_stall || div_stall;
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) alu_stall_q <= 0;
    else alu_stall_q <= alu_stall_o;
  end

`ifdef WALLACE_SINGLE_CYCLE

  assign mul_valid = 1;
  assign mul_busy  = 0;

  mul #(
      .XLEN(32),
      .YLEN(32),
      .TYP (Mul_Type)
  ) u_mul (
      .a(mul_op_A),
      .b(mul_op_B),
      .c(unsigned_prod)
  );

`elsif DSP_MUL

  always_comb begin
    unsigned_prod = mul_op_A * mul_op_B;
    mul_valid = 1;
    mul_busy = 0;
  end

`else

  seq_multiplier #(
      .SIZE(32)
  ) seq_multiplier_inst (
      .clk_i         (clk_i),
      .rst_ni        (rst_ni),
      .start_i       (mul_start),
      .busy_o        (mul_busy),
      .done_o        (),
      .valid_o       (mul_valid),
      .multiplicand_i(mul_op_A),
      .multiplier_i  (mul_op_B),
      .product_o     (unsigned_prod)
  );

`endif

  divu_int #(
      .WIDTH(32)
  ) divu_int_inst (
      .clk_i     (clk_i),
      .rst_ni    (rst_ni),
      .start_i   (div_start),
      .busy_o    (div_busy),
      .done_o    (),
      .valid_o   (div_valid),
      .dbz_o     (),
      .dividend_i(div_op_A),
      .divisor_i (div_op_B),
      .quotient_o(unsigned_quo),
      .reminder_o(unsigned_rem)
  );

  always_comb begin
    rslt.ADD    = alu_a_i + alu_b_i;
    rslt.SUB    = alu_a_i - alu_b_i;
    rslt.SLT    = ($signed(alu_a_i) < $signed(alu_b_i)) ? 32'b1 : 32'b0;
    rslt.SLTU   = (alu_a_i < alu_b_i) ? 32'b1 : 32'b0;
    rslt.AND    = alu_a_i & alu_b_i;
    rslt.OR     = alu_a_i | alu_b_i;
    rslt.XOR    = alu_a_i ^ alu_b_i;
    rslt.SLL    = alu_a_i << alu_b_i[4:0];
    rslt.SRL    = alu_a_i >> alu_b_i[4:0];
    rslt.SRA    = $signed(alu_a_i) >>> alu_b_i[4:0];
    rslt.MUL    = product[31:0];
    rslt.MULH   = product;
    rslt.MULHU  = unsigned_prod;
    rslt.MULHSU = product;
    rslt.DIV    = quotient;
    rslt.DIVU   = unsigned_quo;
    rslt.REM    = reminder;
    rslt.REMU   = unsigned_rem;
    rslt.LUI    = alu_b_i;

    case (op_sel_i)
      OP_ADD:    alu_o = rslt.ADD;
      OP_SUB:    alu_o = rslt.SUB;
      OP_SLL:    alu_o = rslt.SLL;
      OP_SLT:    alu_o = rslt.SLT;
      OP_SLTU:   alu_o = rslt.SLTU;
      OP_XOR:    alu_o = rslt.XOR;
      OP_SRL:    alu_o = rslt.SRL;
      OP_SRA:    alu_o = rslt.SRA;
      OP_OR:     alu_o = rslt.OR;
      OP_AND:    alu_o = rslt.AND;
      OP_MUL:    alu_o = rslt.MUL;
      OP_MULH:   alu_o = rslt.MULH[2*XLEN-1:XLEN];
      OP_MULHSU: alu_o = rslt.MULHSU[2*XLEN-1:XLEN];
      OP_MULHU:  alu_o = rslt.MULHU[2*XLEN-1:XLEN];
      OP_DIV:    alu_o = rslt.DIV;
      OP_DIVU:   alu_o = rslt.DIVU;
      OP_REM:    alu_o = rslt.REM;
      OP_REMU:   alu_o = rslt.REMU;
      OP_LUI:    alu_o = rslt.LUI;
      OP_CSRRW:  alu_o = alu_a_i;
      OP_CSRRS:  alu_o = csr_rdata_i | alu_a_i;
      OP_CSRRC:  alu_o = csr_rdata_i & ~alu_a_i;
      OP_CSRRWI: alu_o = alu_b_i;
      OP_CSRRSI: alu_o = csr_rdata_i | alu_b_i;
      OP_CSRRCI: alu_o = csr_rdata_i & ~alu_b_i;
      default:   alu_o = 0;
    endcase

    // Flags
    zero_o = $signed(alu_a_i) == $signed(alu_b_i);
    slt_o  = ($signed(alu_a_i) < $signed(alu_b_i));
    sltu_o = ($unsigned(alu_a_i) < $unsigned(alu_b_i));
  end

endmodule
