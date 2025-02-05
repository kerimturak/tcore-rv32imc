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
// Design Name:    hazard_unit                                                //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Pipeline hazard control managing unit                      //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`include "tcore_defines.svh"
module hazard_unit (
    input  logic [4:0] r1_addr_de_i,
    input  logic [4:0] r2_addr_de_i,
    input  logic [4:0] r1_addr_ex_i,
    input  logic [4:0] r2_addr_ex_i,
    input  logic [4:0] rd_addr_ex_i,
    input  logic       pc_sel_ex_i,
    input  logic       rslt_sel_ex_0,
    input  logic [4:0] rd_addr_me_i,
    input  logic       rf_rw_me_i,
    input  logic       rf_rw_wb_i,
    input  logic [4:0] rd_addr_wb_i,
    output logic       stall_fe_o,
    output logic       stall_de_o,
    output logic       flush_de_o,
    output logic       flush_ex_o,
    output logic [1:0] fwd_a_ex_o,
    output logic [1:0] fwd_b_ex_o,
    output logic       fwd_a_de_o,
    output logic       fwd_b_de_o
);

  logic lw_stall;

  always_comb begin
    if (rf_rw_me_i && (r1_addr_ex_i == rd_addr_me_i) && (r1_addr_ex_i != 0)) begin // memory to execution
      fwd_a_ex_o = 2'b10;
    end else if (rf_rw_wb_i && (r1_addr_ex_i == rd_addr_wb_i) && (r1_addr_ex_i != 0)) begin // writeback to execution
      fwd_a_ex_o = 2'b01;
    end else begin
      fwd_a_ex_o = 2'b00;
    end

    if (rf_rw_me_i && (r2_addr_ex_i == rd_addr_me_i) && (r2_addr_ex_i != 0)) begin
      fwd_b_ex_o = 2'b10;
    end else if (rf_rw_wb_i && (r2_addr_ex_i == rd_addr_wb_i) && (r2_addr_ex_i != 0)) begin
      fwd_b_ex_o = 2'b01;
    end else begin
      fwd_b_ex_o = 2'b00;
    end

    fwd_a_de_o = rf_rw_wb_i && (r1_addr_de_i == rd_addr_wb_i) && (r1_addr_de_i != 0); // writeback to decode
    fwd_b_de_o = rf_rw_wb_i && (r2_addr_de_i == rd_addr_wb_i) && (r2_addr_de_i != 0);

    lw_stall   = rslt_sel_ex_0 && ((r1_addr_de_i == rd_addr_ex_i) || (r2_addr_de_i == rd_addr_ex_i));
    stall_fe_o = lw_stall;
    stall_de_o = lw_stall;

    flush_de_o = pc_sel_ex_i;
    flush_ex_o = lw_stall || pc_sel_ex_i;

  end

endmodule
