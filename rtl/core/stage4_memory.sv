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
// Design Name:    stage4_memory                                              //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    stage4_memory                                              //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`include "tcore_defines.svh"
module stage4_memory
  import tcore_param::*;
(
    input  logic                  clk_i,
    input  logic                  rst_ni,
    input  logic                  stall_i,
    input  logic                  wr_en_i,
    input  logic       [     1:0] rw_type_i,
    input  logic       [XLEN-1:0] alu_result_i,
    input  logic       [XLEN-1:0] write_data_i,
    input  dlowX_res_t            lx_dres_i,
    input  logic       [     4:0] ld_op_size_i,
    output dlowX_req_t            lx_dreq_o,
    output logic       [XLEN-1:0] me_data_o,
    output logic                  dmiss_stall_o,
    output logic                  uart_tx_o,
    input  logic                  uart_rx_i
);

  dcache_req_t            dcache_req;
  dcache_res_t            dcache_res;
  logic                   dcache_miss;
  logic        [XLEN-1:0] pherip_addr;
  logic        [XLEN-1:0] pherip_wdata;
  //logic [1:0] pherip_awr;  //! memory stage bus operation signals a: active, w: write, r: read
  logic        [     3:0] pherip_sel;
  logic        [XLEN-1:0] pherip_rdata;
  logic                   pherip_valid;
  logic        [XLEN-1:0] rd_data;
  logic                   uncached;
  logic                   memregion;

  always_comb begin
    dcache_req.valid = !dcache_res.valid && |rw_type_i && memregion;
    dcache_req.addr = alu_result_i;
    dcache_req.ready = 1'b1;
    dcache_req.rw = wr_en_i;
    dcache_req.rw_type = rw_type_i;
    dcache_req.data = write_data_i;
    dcache_req.uncached = uncached;
    dmiss_stall_o = (dcache_req.valid && !dcache_res.valid);
  end

  pma dpma (
      .addr_i     (alu_result_i),
      .uncached_o (uncached),
      .memregion_o(memregion)            // unused now
  );

  dcache dcache (
      .clk_i        (clk_i),
      .rst_i        (rst_ni),
      .cache_req_i  (dcache_req),
      .cache_res_o  (dcache_res),
      .dcache_miss_o(dcache_miss),
      .lowX_res_i   (lx_dres_i),
      .lowX_req_o   (lx_dreq_o)
  );

  logic [ 7:0] selected_byte;
  logic [15:0] selected_halfword;
  always_comb begin : read_data_size_handler
    rd_data = !memregion ? pherip_rdata : dcache_res.data;
    // Default assignment
    me_data_o = '0;
    // Select the appropriate byte or halfword based on address
    selected_byte = rd_data[(dcache_req.addr[1:0]*8)+:8];
    selected_halfword = rd_data[(dcache_req.addr[1]*16)+:16];
    // Determine the output based on load operation sizef
    unique case (1'b1)
      ld_op_size_i[0]: me_data_o = {{24{selected_byte[7]}}, selected_byte};  // Byte with sign extension
      ld_op_size_i[1]: me_data_o = {{16{selected_halfword[15]}}, selected_halfword};  // Halfword with sign extension
      ld_op_size_i[2]: me_data_o = rd_data;  // Word
      ld_op_size_i[3]: me_data_o = {24'b0, selected_byte};  // Byte without sign extension
      ld_op_size_i[4]: me_data_o = {16'b0, selected_halfword};  // Halfword without sign extension
      default:         me_data_o = '0;
    endcase
  end


  always_comb begin
    pherip_valid = !memregion && !stall_i;
    pherip_addr  = !memregion ? alu_result_i : '0;
    pherip_sel   = !memregion && !stall_i ? 4'b1111 : 4'b0000;
    pherip_wdata = !memregion ? write_data_i : '0;
  end
  uart uart_inst (
      .clk_i     (clk_i),
      .rst_i     (rst_ni),
      .stb_i     (pherip_valid),
      .adr_i     (pherip_addr[3:2]),
      .byte_sel_i(pherip_sel),
      .we_i      (wr_en_i),
      .dat_i     (pherip_wdata),
      .dat_o     (pherip_rdata),
      .uart_rx_i (uart_rx_i),
      .uart_tx_o (uart_tx_o)
  );

endmodule
