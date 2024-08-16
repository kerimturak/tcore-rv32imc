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
// Design Name:    ras                                                        //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    RAS                                                        //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`include "tcore_defines.svh"
import tcore_param::*;
module ras (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic        spec_hit_i,
    input  logic        restore_i,
    input  logic [31:0] restore_pc_i,
    input  logic        req_valid_i,
    input  logic        j_type_i,
    input  logic        jr_type_i,
    input  logic [ 4:0] rd_addr_i,
    input  logic [ 4:0] r1_addr_i,
    input  logic [31:0] return_addr_i,
    output logic [31:0] popped_addr_o,
    output logic        predict_valid_o
);
  localparam RAS_SIZE = 8;
  typedef enum logic [1:0] {
    NONE,
    PUSH,
    POP,
    BOTH
  } ras_op_e;

  logic    [31:0] ras     [RAS_SIZE-1:0];
  ras_op_e        ras_op;
  logic           link_rd;
  logic           link_r1;

  always_comb begin
    popped_addr_o = ras[0];
    ras_op = NONE;
    link_rd = rd_addr_i == 5'd1 || rd_addr_i == 5'd5;
    link_r1 = r1_addr_i == 5'd1 || r1_addr_i == 5'd5;
    if (req_valid_i) begin
      if (j_type_i && link_rd) ras_op = PUSH;
      else if (jr_type_i && (link_rd || link_r1)) begin
        if (link_rd && link_r1) ras_op = (rd_addr_i == r1_addr_i) ? PUSH : BOTH;
        else if (link_r1) ras_op = POP;
        else ras_op = PUSH;
      end
    end
    predict_valid_o = req_valid_i && (ras_op inside {POP, BOTH});
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      ras <= '{default: 0};
    end else begin
      if (restore_i) begin
        for (int i = RAS_SIZE - 1; i > 0; i--) ras[i] <= ras[i-1];
        ras[0] <= restore_pc_i;
      end else if (req_valid_i) begin
        case (ras_op)
          PUSH: begin
            for (int i = RAS_SIZE - 1; i > 0; i--) ras[i] <= ras[i-1];
            ras[0] <= return_addr_i;
          end
          POP:  for (int i = 0; i < RAS_SIZE - 1; i++) ras[i] <= ras[i+1];
          BOTH: ras[0] <= return_addr_i;
        endcase
      end
    end
  end

endmodule
