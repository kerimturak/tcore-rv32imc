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
// Design Name:    memory_arbiter                                             //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Data and Instruction request arbiter                       //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`include "tcore_defines.svh"
import tcore_param::*;
module memory_arbiter (
    input  logic                       clk_i,
    input  logic                       rst_i,
    input  ilowX_req_t                 icache_req_i,
    input  dlowX_req_t                 dcache_req_i,
    input  logic                       mem_ready_i,
    input  logic       [BLK_SIZE -1:0] iomem_rdata_i,
    output ilowX_res_t                 icache_res_o,
    output dlowX_res_t                 dcache_res_o,
    output mem_req_t                   mem_req_o
);

  localparam BOFFSET = $clog2(BLK_SIZE / 8);

  typedef enum logic [1:0] {
    IDLE,
    ICACHE,
    DCACHE
  } round_e;
  round_e round;

  always_comb begin
    icache_res_o.valid = round == ICACHE && mem_ready_i;
    icache_res_o.ready = 1'b1;
    icache_res_o.blk = iomem_rdata_i;
    dcache_res_o.valid = round == DCACHE && mem_ready_i;
    dcache_res_o.ready = 1'b1;
    dcache_res_o.data = iomem_rdata_i;

    mem_req_o.addr = round == DCACHE ? dcache_req_i.addr : icache_req_i.addr;
    mem_req_o.valid = round == DCACHE ? dcache_req_i.valid : icache_req_i.valid;

    mem_req_o.rw = '0;
    if (round == DCACHE && dcache_req_i.rw && !dcache_req_i.uncached) begin
      case (dcache_req_i.rw_type)
        0:       mem_req_o.rw = '0;
        1:       mem_req_o.rw = 'b1 << dcache_req_i.addr[BOFFSET-1:0];
        2:       mem_req_o.rw = 'b11 << dcache_req_i.addr[BOFFSET-1:0];
        default: mem_req_o.rw = '1;
      endcase
    end
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      round <= IDLE;
    end else begin
      case (round_e'({
        icache_req_i.valid, dcache_req_i.valid
      }))
        IDLE:    round <= IDLE;
        ICACHE:  round <= DCACHE;
        DCACHE:  round <= ICACHE;
        default: round <= ICACHE;
      endcase
    end
  end

endmodule
