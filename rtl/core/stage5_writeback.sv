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
// Design Name:    stage5_writeback                                           //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    stage5_writeback                                           //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`include "tcore_defines.svh"
module stage5_writeback
  import tcore_param::*;
(
    input  logic [     1:0] data_sel_i,
    input  logic [XLEN-1:0] pc2_i,
    input  logic [XLEN-1:0] pc4_i,
    input  logic            is_comp_i,
    input  logic [XLEN-1:0] alu_result_i,
    input  logic [XLEN-1:0] read_data_i,
    input  logic            stall_i,
    input  logic            rf_rw_en_i,
    output logic            rf_rw_en_o,
    output logic [XLEN-1:0] wb_data_o,
    output logic [XLEN-1:0] wb_pc_o,
    output logic            trap_active_o,
    input logic             fe_exc_type_i,
    input logic             de_exc_type_i,
    input logic             ex_exc_type_i
);

  always_comb begin
    rf_rw_en_o = rf_rw_en_i && !stall_i;
    wb_data_o  = data_sel_i[1] ? (is_comp_i ? pc2_i : pc4_i) : (data_sel_i[0] ? read_data_i : alu_result_i);
    trap_active_o = '0;
    if (ex_exc_type_i) begin
      trap_active_o = '1;
    end else if(de_exc_type_i) begin
      trap_active_o = '1;
    end else if (fe_exc_type_i) begin
      trap_active_o = '1;
    end
    exc_valid_o = trap_active
  end

endmodule
