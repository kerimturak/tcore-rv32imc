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
module stage1_fetch
  import tcore_param::*;
(
    input  logic                     clk_i,
    input  logic                     rst_ni,
    input  logic                     stall_i,
    input  logic                     fe_stall_i,
    input  ilowX_res_t               lx_ires_i,
    input  logic          [XLEN-1:0] pc_target_i,
    input  logic                     spec_hit_i,
    output predict_info_t            spec_o,
    output ilowX_req_t               lx_ireq_o,
    output logic          [XLEN-1:0] pc_o,
    output logic          [XLEN-1:0] pc4_o,
    output logic          [XLEN-1:0] pc2_o,
    output logic          [XLEN-1:0] inst_o,
    output logic                     imiss_stall_o,
    output logic                     is_comp_o
);

  logic                   fetch_valid;
  logic        [XLEN-1:0] pc_next;
  logic                   pc_en;
  logic                   buffer_miss;
  logic                   uncached;
  logic                   memregion;
  gbuff_res_t             buff_res;
  logic                   icache_miss;
  icache_req_t            buff_req;
  icache_res_t            icache_res;
  icache_req_t            icache_req;
  logic                   illegal_instr;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      pc_o <= 32'h4000_0000;
    end else if (pc_en) begin
      pc_o <= fetch_valid ? pc_next : pc_o;
    end
  end

  always_comb begin
    fetch_valid   = 1'b1;
    pc_en         = !(stall_i || fe_stall_i);
    imiss_stall_o = (fetch_valid && !buff_res.valid || buffer_miss);
    pc4_o         = 32'd4 + pc_o;
    pc2_o         = 32'd2 + pc_o;
    buff_req      = '{valid    : fetch_valid, ready    : 1, addr     : pc_o, uncached : uncached};
  end

  always_comb begin
    if (spec_hit_i) begin
      pc_next = spec_o.taken ? spec_o.pc : (is_comp_o ? pc2_o : pc4_o);
    end else begin
      pc_next = pc_target_i;
    end
  end

  pma ipma (
      .addr_i     (pc_o),
      .uncached_o (uncached),
      .memregion_o(memregion)  // unused now
  );

  `ifdef STATIC_PREDICT
    t_branch_predict
  `else
    t_gshare 
  `endif
    branch_prediction (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .spec_hit_i   (spec_hit_i),
    `ifndef STATIC_PREDICT
      .pc_target_i  (pc_target_i),
    `endif
      .inst_i       (inst_o),
      .stall_i      (!pc_en),
      .is_comp_i    (is_comp_o),
      .pc_i         (pc_o),
      .pc2_i        (pc2_o),
      .pc4_i        (pc4_o),
      .fetch_valid_i(buff_res.valid),
      .spec_o       (spec_o)
  );

  gray_align_buffer gray_align_buffer (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .buff_req_i   (buff_req),
      .buff_res_o   (buff_res),
      .buffer_miss_o(buffer_miss),
      .lowX_res_i   (icache_res),
      .lowX_req_o   (icache_req)
  );

  icache icache (
      .clk_i        (clk_i),
      .rst_ni        (rst_ni),
      .cache_req_i  (icache_req),
      .cache_res_o  (icache_res),
      .icache_miss_o(icache_miss),
      .lowX_res_i   (lx_ires_i),
      .lowX_req_o   (lx_ireq_o)
  );

  riscv_compressed_decoder compressed_decoder (
      .instr_i        (buff_res.blk),
      .instr_o        (inst_o),
      .is_compressed_o(is_comp_o),
      .illegal_instr_o(illegal_instr)
  );

endmodule
