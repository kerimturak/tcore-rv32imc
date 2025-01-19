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
// Design Name:    stage2_decode                                              //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    stage2_decode                                              //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`include "tcore_defines.svh"
module stage2_decode
  import tcore_param::*;
(
    input  logic             clk_i,
    input  logic             rst_ni,
    input  inst_t            inst_i,
    input  logic             fwd_a_i,
    input  logic             fwd_b_i,
    input  logic  [XLEN-1:0] wb_data_i,
    input  logic  [     4:0] rd_addr_i,
    input  logic             rf_rw_en_i,
    input exc_type_e         exc_type_i,

    output logic  [XLEN-1:0] r1_data_o,
    output logic  [XLEN-1:0] r2_data_o,
    output ctrl_t            ctrl_o,
    output logic  [XLEN-1:0] imm_o,
    output exc_type_e        exc_type_o

);

  logic [XLEN-1:0] r1_data;
  logic [XLEN-1:0] r2_data;

  always_comb begin
    r1_data_o  = fwd_a_i ? wb_data_i : r1_data;
    r2_data_o  = fwd_b_i ? wb_data_i : r2_data;
    exc_type_o = ctrl_o.exc_type == NO_EXCEPTION ? exc_type_i : ctrl_o.exc_type;
  end

  control_unit control_unit (
      .inst_i(inst_i),
      .ctrl_o  (ctrl_o)
  );

  reg_file reg_file (
      .clk_i    (clk_i),
      .rst_ni   (rst_ni),
      .rw_en_i  (rf_rw_en_i),
      .r1_addr_i(inst_i.r1_addr),
      .r2_addr_i(inst_i.r2_addr),
      .waddr_i  (rd_addr_i),
      .wdata_i  (wb_data_i),
      .r1_data_o(r1_data),
      .r2_data_o(r2_data)
  );

  extend extend (
      .imm_i(inst_i[31:7]),
      .sel_i(ctrl_o.imm_sel),
      .imm_o(imm_o)
  );

endmodule
