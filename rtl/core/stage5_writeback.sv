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
    input  logic [XLEN-1:0] pc_i,
    input  logic [XLEN-1:0] mtvec_i,
    input  logic            is_comp_i,
    input  logic [XLEN-1:0] alu_result_i,
    input  logic [XLEN-1:0] read_data_i,
    input  logic            stall_i,
    input  logic            rf_rw_en_i,
    output logic            rf_rw_en_o,
    output logic [XLEN-1:0] wb_data_o,
    output logic [XLEN-1:0] wb_pc_o,
    output logic            trap_active_o,
    output logic [XLEN-1:0] trap_cause_o,
    output logic [XLEN-1:0] trap_mepc_o,
    input  exc_type_e       exc_type_i
);

  always_comb begin
    rf_rw_en_o = rf_rw_en_i && !stall_i;
    wb_data_o  = data_sel_i[1] ? (is_comp_i ? pc2_i : pc4_i) : (data_sel_i[0] ? read_data_i : alu_result_i);
    trap_active_o = '0;
    trap_mepc_o = pc_i;
    if (exc_type_i != NO_EXCEPTION) begin
      trap_active_o = '1;
    end

    case (exc_type_i)
      NO_EXCEPTION: trap_cause_o = '1;
      //INSTR_MISALIGNED: trap_cause_o = 0; // compressed destekleniyor
      INSTR_ACCESS_FAULT: trap_cause_o = 1;
      ILLEGAL_INSTRUCTION: trap_cause_o = 2;
      EBREAK: trap_cause_o = 3;
      LOAD_MISALIGNED: trap_cause_o = 4;
      LOAD_ACCESS_FAULT: trap_cause_o = 5;
      STORE_MISALIGNED: trap_cause_o = 6;
      STORE_ACCESS_FAULT: trap_cause_o = 7;
      ECALL: trap_cause_o = 11;
      default: trap_cause_o = '1;
    endcase

    if (trap_active_o) begin
      wb_pc_o = mtvec_i;
    end
  end

endmodule
