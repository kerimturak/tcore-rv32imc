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
    input  logic            clk_i,
    input  logic            rst_i,
    input  logic [XLEN-1:0] alu_a_i,
    input  logic [XLEN-1:0] alu_b_i,
    input  logic [     4:0] op_sel_i,
    output logic            alu_stall_o,
    output logic            zero_o,
    output logic            slt_o,
    output logic            sltu_o,
    output logic [XLEN-1:0] alu_o
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

  logic                 alu_stall_q;
  logic                 mul_stall;
  logic                 div_stall;
  logic    [  XLEN-1:0] abs_A;
  logic    [  XLEN-1:0] abs_B;
  logic                 sign;
  logic                 mul_busy;
  logic                 mul_start;
  logic    [2*XLEN-1:0] product;
  logic    [  XLEN-1:0] mul_op_A;
  logic    [  XLEN-1:0] mul_op_B;
  logic    [2*XLEN-1:0] unsigned_prod;
  logic                 mul_type;
  logic                 mul_valid;
  logic                 div_busy;
  logic                 div_start;
  logic    [  XLEN-1:0] div_op_A;
  logic    [  XLEN-1:0] div_op_B;
  logic    [  XLEN-1:0] unsigned_quo;
  logic    [  XLEN-1:0] quotient;
  logic    [  XLEN-1:0] unsigned_rem;
  logic    [  XLEN-1:0] reminder;
  logic                 div_type;
  logic                 div_valid;

  always_comb begin
    abs_A = alu_a_i[XLEN-1] ? ~alu_a_i + 1'b1 : alu_a_i;
    abs_B = alu_b_i[XLEN-1] ? ~alu_b_i + 1'b1 : alu_b_i;
    sign = alu_a_i[XLEN-1] ^ alu_b_i[XLEN-1];
    mul_type = op_sel_i inside {[10 : 13]};
    mul_start = mul_type && !mul_busy && !alu_stall_q;
    mul_op_A = op_sel_i == 13 ? $unsigned(alu_a_i) : abs_A;
    mul_op_B = op_sel_i == 13 || op_sel_i == 12 ? $unsigned(alu_b_i) : abs_B;
    product = sign ? ~(unsigned_prod - 1'b1) : unsigned_prod;
    mul_stall = (mul_type && !mul_valid || (mul_valid && mul_start));
    div_type = op_sel_i inside {[14 : 17]};
    div_start = div_type && !div_busy && !alu_stall_q;
    div_op_A = op_sel_i == 15 || op_sel_i == 17 ? $unsigned(alu_a_i) : abs_A;
    div_op_B = op_sel_i == 15 || op_sel_i == 17 ? $unsigned(alu_b_i) : abs_B;
    quotient = sign ? ~(unsigned_quo - 1'b1) : unsigned_quo;
    reminder = sign ? ~(unsigned_rem - 1'b1) : unsigned_rem;
    div_stall = (div_type && !div_valid || (div_valid && div_start));
    alu_stall_o = mul_stall || div_stall;
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) alu_stall_q <= 0;
    else alu_stall_q <= alu_stall_o;
  end

`ifdef WALLACE_SINGLE_CYCLE

  assign mul_valid = 1;
  assign mul_busy  = 0;
  mul #(
      .XLEN(32),
      .YLEN(32),
      .TYP (1)
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

`elsif WALLACE_MULTY_CYCLE

  typedef enum logic [2:0] {
    IDLE,
    CALC_1,
    CALC_2,
    CALC_3,
    CALC_4
  } state_t;
  state_t state, next_state;

  logic [15:0] products[3:0];
  logic [ 7:0] mul_A;

  for (genvar i = 0; i < 4; i++) begin : generate_multipliers
    wallace_8x8_product wtm (
        .a(mul_A),
        .b(abs_B[(i+1)*8-1-:8]),
        .z(products[i])
    );
  end

  assign mul_busy = state != IDLE;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      state <= IDLE;
      unsigned_prod <= 64'd0;
      mul_valid <= 1'b0;
    end else begin
      state <= next_state;
      if (state == IDLE) begin
        unsigned_prod <= 64'd0;
        mul_valid <= 1'b0;
      end else if (state inside {CALC_1, CALC_2, CALC_3, CALC_4}) begin
        unsigned_prod <= unsigned_prod + (products[0] << (0 +  (state - 1) * 8)) +
                                         (products[1] << (8 +  (state - 1) * 8)) +
                                         (products[2] << (16 + (state - 1) * 8)) +
                                         (products[3] << (24 + (state - 1) * 8));
        mul_valid <= state == CALC_4 ? 1'b1 : 1'b0;
      end
    end
  end

  always_comb begin
    next_state = state;
    case (state)
      IDLE: begin
        mul_A = '0;
        if (mul_start) begin
          next_state = CALC_1;
        end
      end
      CALC_1: begin
        mul_A = abs_A[7:0];
        next_state = CALC_2;
      end
      CALC_2: begin
        mul_A = abs_A[15:8];
        next_state = CALC_3;
      end
      CALC_3: begin
        mul_A = abs_A[23:16];
        next_state = CALC_4;
      end
      CALC_4: begin
        mul_A = abs_A[31:24];
        next_state = IDLE;
      end
    endcase
  end

`else

  seq_multiplier #(
      .SIZE(32)
  ) seq_multiplier_inst (
      .clk_i         (clk_i),
      .rst_ni        (rst_i),
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
      .rst_ni    (rst_i),
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
      0:       alu_o = rslt.ADD;
      1:       alu_o = rslt.SUB;
      2:       alu_o = rslt.SLL;
      3:       alu_o = rslt.SLT;
      4:       alu_o = rslt.SLTU;
      5:       alu_o = rslt.XOR;
      6:       alu_o = rslt.SRL;
      7:       alu_o = rslt.SRA;
      8:       alu_o = rslt.OR;
      9:       alu_o = rslt.AND;
      10:      alu_o = rslt.MUL;
      11:      alu_o = rslt.MULH[2*XLEN-1:XLEN];
      12:      alu_o = rslt.MULHSU[2*XLEN-1:XLEN];
      13:      alu_o = rslt.MULHU[2*XLEN-1:XLEN];
      14:      alu_o = rslt.DIV;
      15:      alu_o = rslt.DIVU;
      16:      alu_o = rslt.REM;
      17:      alu_o = rslt.REMU;
      18:      alu_o = rslt.LUI;
      default: alu_o = 0;
    endcase

    // Flags
    zero_o = $signed(alu_a_i) == $signed(alu_b_i);
    slt_o  = ($signed(alu_a_i) < $signed(alu_b_i));
    sltu_o = ($unsigned(alu_a_i) < $unsigned(alu_b_i));
  end

endmodule
