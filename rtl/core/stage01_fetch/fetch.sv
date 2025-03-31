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
// Design Name:    stage1_fetch                                               //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    stage1_fetch                                               //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`include "tcore_defines.svh"
module fetch
  import tcore_param::*;
#(
    parameter RESET_VECTOR = 32'h8000_0000
) (
    input  logic                     clk_i,
    input  logic                     rst_ni,
    input  logic          [     4:0] stall_i,
    input  logic                     flush_i,
    input  ilowX_res_t               lx_ires_i,
    input  logic          [XLEN-1:0] pc_target_i,
    input  logic                     spec_hit_i,
    input  logic          [     4:0] exc_array_i,
    input  logic          [XLEN-1:0] wb_pc_i,
    input  logic          [XLEN-1:0] mepc_i,
    output predict_info_t            spec_o,
    output ilowX_req_t               lx_ireq_o,
    output logic          [XLEN-1:0] pc_o,
    output logic          [XLEN-1:0] pc4_o,
    output logic          [XLEN-1:0] pc2_o,
    output logic          [XLEN-1:0] inst_o,
    output logic                     imiss_stall_o,
    output logic                     is_comp_o,
    output exc_type_e                exc_type_o,
    output instr_type_e              instr_type_o
);

  logic                   fetch_valid;
  logic        [XLEN-1:0] pc_next;
  logic                   pc_en;
  logic                   uncached;
  logic                   memregion;
  abuff_res_t             buff_res;
  abuff_req_t             buff_req;
  icache_res_t            icache_res;
  icache_req_t            icache_req;
  logic                   illegal_instr;
  logic                   grand;
  logic        [XLEN-1:0] pc;
  blowX_res_t             buff_lowX_res;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      pc <= RESET_VECTOR;
    end else if (pc_en) begin
      pc <= fetch_valid ? pc_next : pc;
    end
  end

  always_comb begin
    // writeback stage'ine ulaşan bir exeption varsa handler pc'sini writebackten al
    pc_o = exc_array_i[4] ? wb_pc_i : pc;

    if (buff_res.valid) instr_type_o = resolved_instr_type(inst_o);
    else instr_type_o = Null_Instr_Type;

    fetch_valid = !flush_i && (!spec_hit_i && ~|exc_array_i[3:2] ? 1 : ~(|exc_array_i[3:0]));  // || trap

    // request granted
    exc_type_o  = NO_EXCEPTION;
    if (!grand && fetch_valid) exc_type_o = INSTR_ACCESS_FAULT;
    else if (illegal_instr && buff_res.valid) exc_type_o = ILLEGAL_INSTRUCTION;
    else if (instr_type_o == ecall) exc_type_o = ECALL;
    else if (instr_type_o == ebreak) exc_type_o = EBREAK;
    else exc_type_o = NO_EXCEPTION;

    pc_en         = !(|stall_i[4:2] || stall_i[0]);
    imiss_stall_o = (fetch_valid && !buff_res.valid);
    pc4_o         = 32'd4 + pc_o;
    pc2_o         = 32'd2 + pc_o;
    buff_req      = '{valid    : fetch_valid, ready    : 1, addr     : pc_o, uncached : uncached};
  end

  always_comb begin
    if (spec_hit_i) pc_next = spec_o.taken ? spec_o.pc : (is_comp_o ? pc2_o : pc4_o);
    else pc_next = pc_target_i;
  end

  pma ipma (
      .addr_i     (pc_o),
      .uncached_o (uncached),
      .memregion_o(memregion),  // unused now
      .grand_o    (grand)
  );

  gshare_bp branch_prediction (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .spec_hit_i   (spec_hit_i),
      .pc_target_i  (pc_target_i),
      .inst_i       (inst_o),
      .stall_i      (!pc_en),
      .is_comp_i    (is_comp_o),
      .pc_i         (pc_o),
      .pc2_i        (pc2_o),
      .pc4_i        (pc4_o),
      .fetch_valid_i(buff_res.valid),
      .spec_o       (spec_o)
  );

  always_comb begin
    buff_lowX_res.valid = icache_res.valid;
    buff_lowX_res.ready = icache_res.ready;
    buff_lowX_res.blk   = icache_res.blk;
  end

  align_buffer align_buffer (
      .clk_i     (clk_i),
      .rst_ni    (rst_ni),
      .flush_i   (flush_i),
      .buff_req_i(buff_req),
      .buff_res_o(buff_res),
      .lowX_res_i(buff_lowX_res),
      .lowX_req_o(icache_req)
  );

  cache #(
      .IS_ICACHE  (1),
      .cache_req_t(icache_req_t),
      .cache_res_t(icache_res_t),
      .lowX_req_t (ilowX_req_t),
      .lowX_res_t (ilowX_res_t),
      .CACHE_SIZE (IC_CAPACITY),
      .BLK_SIZE   (BLK_SIZE),
      .XLEN       (XLEN),
      .NUM_WAY    (IC_WAY)
  ) icache (
      .clk_i      (clk_i),
      .rst_ni     (rst_ni),
      .flush_i    (flush_i),
      .cache_req_i(icache_req),
      .cache_res_o(icache_res),
      .lowX_res_i (lx_ires_i),
      .lowX_req_o (lx_ireq_o)
  );

  riscv_compressed_decoder compressed_decoder (
      .instr_i        (buff_res.blk),
      .instr_o        (inst_o),
      .is_compressed_o(is_comp_o),
      .illegal_instr_o(illegal_instr)
  );

  `include "fetch_log.svh"

endmodule
