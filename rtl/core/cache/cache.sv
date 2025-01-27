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
// Design Name:    dcache                                                     //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Writeback full configurable data cache                     //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`include "tcore_defines.svh"
module cache
  import tcore_param::*;
#(
    parameter CACHE_SIZE = (DC_CAPACITY),
    parameter BLK_SIZE = tcore_param::BLK_SIZE,
    parameter XLEN = tcore_param::XLEN,
    parameter NUM_WAY = DC_WAY,
    parameter string WHICH_CACHE = "DCACHE",
    parameter type cache_req_t,
    parameter type cache_res_t,
    parameter type lowX_res_t,
    parameter type lowX_req_t
) (
    input  logic       clk_i,
    input  logic       rst_ni,
    input  cache_req_t cache_req_i,
    output cache_res_t cache_res_o,
    output logic       cache_miss_o,
    input  lowX_res_t  lowX_res_i,
    output lowX_req_t  lowX_req_o
);

  localparam NUM_SET = (CACHE_SIZE / BLK_SIZE) / NUM_WAY;
  localparam IDX_WIDTH = $clog2(NUM_SET) == 0 ? 1 : $clog2(NUM_SET);
  localparam BOFFSET = $clog2(BLK_SIZE / 8);
  localparam WOFFSET = $clog2((BLK_SIZE / 32));
  localparam TAG_SIZE = XLEN - IDX_WIDTH - BOFFSET;

  logic                  cache_miss;
  logic                  cache_hit;
  logic  [IDX_WIDTH-1:0] rd_idx;
  logic  [IDX_WIDTH-1:0] wr_idx;
  logic  [  NUM_WAY-1:0] cache_wr_way;
  logic  [ BLK_SIZE-1:0] cache_select_data;
  logic  [ BLK_SIZE-1:0] mask_data;
  logic                  data_array_wr_en;
  logic  [ BLK_SIZE-1:0] data_wr_line;
  logic  [ BLK_SIZE-1:0] data_rd_line      [NUM_WAY];
  logic  [  NUM_WAY-1:0] data_write_way;
  logic                  tag_array_wr_en;
  logic  [   TAG_SIZE:0] cache_wr_tag;
  logic  [   TAG_SIZE:0] cache_rd_tag      [NUM_WAY];
  logic  [  NUM_WAY-1:0] evict_way;
  logic  [  NUM_WAY-1:0] cache_valid_vec;
  logic  [  NUM_WAY-1:0] cache_hit_vec;
  logic                  flush;
  logic  [IDX_WIDTH-1:0] flush_index;
  logic  [IDX_WIDTH-1:0] cache_idx[NUM_WAY];
  logic  [IDX_WIDTH-1:0] node_idx;
  logic  [  NUM_WAY-1:0] tag_write_way;
  logic                  node_wr_en;
  logic  [  NUM_WAY-2:0] updated_node;
  logic  [  NUM_WAY-2:0] cache_wr_node;
  logic  [  NUM_WAY-2:0] cache_rd_node;
  logic  [  WOFFSET-1:0] word_idx;
  logic                  write_back;
  logic                  dirty_wr_en;
  logic  [  NUM_WAY-1:0] dirty_write_way;
  logic                  dirty_wr_data;
  logic  [  NUM_WAY-1:0] dirty_rd_data;
  logic  [ TAG_SIZE-1:0] evict_tag;
  logic  [ BLK_SIZE-1:0] evict_data;
  cache_req_t           cache_req_q;
  logic                  cache_wr_en;

  for (genvar i = 0; i < NUM_WAY; i++) begin : ddata_array
    sp_bram #(
        .DATA_WIDTH(BLK_SIZE),
        .NUM_SETS  (NUM_SET)
    ) data_array (
        .clk    (clk_i),
        .chip_en(1'b1),
        .addr   (rd_idx),
        .wr_en  (data_write_way[i]),
        .wr_data(data_wr_line),
        .rd_data(data_rd_line[i])
    );
  end

  for (genvar i = 0; i < NUM_WAY; i++) begin : dtag_array
    sp_bram #(
        .DATA_WIDTH(TAG_SIZE + 1),
        .NUM_SETS  (NUM_SET)
    ) tag_array (
        .clk    (clk_i),
        .chip_en(1'b1),
        .addr   (cache_idx[i]),
        .wr_en  (tag_write_way[i]),
        .wr_data(cache_wr_tag),
        .rd_data(cache_rd_tag[i])
    );
  end

  if (WHICH_CACHE == "DCACHE") begin
    for (genvar i = 0; i < NUM_WAY; i++) begin : ddirty_array
      sp_bram #(
          .DATA_WIDTH(1),
          .NUM_SETS  (NUM_SET)
      ) dirty_array (
          .clk    (clk_i),
          .chip_en(1'b1),
          .addr   (cache_idx[i]),
          .wr_en  (dirty_write_way[i]),
          .wr_data(dirty_wr_data),
          .rd_data(dirty_rd_data[i])
      );
    end
  end

  sp_bram #(
      .DATA_WIDTH(NUM_WAY - 1),
      .NUM_SETS  (NUM_SET)
  ) node_array (
      .clk    (clk_i),
      .chip_en(1'b1),
      .addr   (node_idx),
      .wr_en  (node_wr_en),
      .wr_data(cache_wr_node),
      .rd_data(cache_rd_node)
  );

  plru #(
      .NUM_WAY(NUM_WAY)
  ) dplru (
      .node_i     (cache_rd_node),
      .hit_vec_i  (cache_hit_vec),
      .evict_way_o(evict_way),
      .node_o     (updated_node)
  );

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      cache_req_q <= '0;
      flush_index <= '0;
      flush       <= '1;
    end else begin
      cache_req_q      <= cache_req_i;
      if (flush && flush_index != 2 ** IDX_WIDTH - 1) begin
        flush_index <= flush_index + 1'b1;
      end else begin
        flush_index <= 1'b0;
        flush       <= 1'b0;
      end
    end
  end

  always_comb begin
    for (int i = 0; i < NUM_WAY; i++) begin
      cache_valid_vec[i] = cache_rd_tag[i][TAG_SIZE];
      cache_hit_vec[i]   = cache_rd_tag[i][TAG_SIZE-1:0] == cache_req_q.addr[XLEN-1:IDX_WIDTH+BOFFSET];
    end
    cache_wr_tag = flush ? '0 : {1'b1, cache_req_q.addr[XLEN-1:IDX_WIDTH+BOFFSET]};
    cache_wr_node = flush ? '0 : updated_node;
    cache_select_data = '0;
    for (int i = 0; i < NUM_WAY; i++) begin
      if (cache_hit_vec[i]) cache_select_data = data_rd_line[i];
    end
    cache_miss = cache_req_q.valid && !flush && !(|(cache_valid_vec & cache_hit_vec));
    cache_hit  = cache_req_q.valid && !flush &&  (|(cache_valid_vec & cache_hit_vec));
    rd_idx = cache_req_i.addr[IDX_WIDTH+BOFFSET:BOFFSET];
    wr_idx = flush ? flush_index : cache_req_q.addr[IDX_WIDTH+BOFFSET:BOFFSET];

    // Data Cache
    if (WHICH_CACHE == "DCACHE") begin
      write_back = cache_miss && (|(dirty_rd_data & evict_way & cache_valid_vec));
      data_array_wr_en = (cache_hit && cache_req_q.rw) || (cache_miss && lowX_res_i.valid && !cache_req_q.uncached) && !write_back; // icachte cache_wr_En'e denk
      tag_array_wr_en = (cache_miss && lowX_res_i.valid && !cache_req_q.uncached) && !write_back;
      dirty_wr_en = (cache_req_q.rw && (cache_hit || (cache_miss && lowX_res_i.valid))) || (write_back && lowX_res_i.valid);
      node_wr_en    = flush || data_array_wr_en;
      cache_wr_way = cache_hit ? cache_hit_vec : evict_way;
      for (int i = 0; i < NUM_WAY; i++) data_write_way[i] = cache_wr_way[i] && data_array_wr_en;
      for (int i = 0; i < NUM_WAY; i++) tag_write_way[i] = flush ? '1 : cache_wr_way[i] && tag_array_wr_en;
      for (int i = 0; i < NUM_WAY; i++) dirty_write_way[i] = flush ? '1 : cache_wr_way[i] && dirty_wr_en;
      for (int i = 0; i < NUM_WAY; i++) cache_idx[i] = tag_write_way[i] ? wr_idx: rd_idx;
      dirty_wr_data = flush ? '0 : (write_back ? '0 : cache_req_q.rw ? '1 : '0);
      evict_tag = '0;
      evict_data = '0;
      for (int i = 0; i < NUM_WAY; i++) if (evict_way[i]) evict_tag = cache_rd_tag[i][TAG_SIZE-1:0];
      for (int i = 0; i < NUM_WAY; i++) if (evict_way[i]) evict_data = data_rd_line[i];
      mask_data = cache_hit ? cache_select_data : lowX_res_i.data;
      case (cache_req_q.rw_size)
        WORD:      mask_data[cache_req_i.addr[BOFFSET-1:2]*32+:32] = cache_req_q.data;
        HALF_WORD: mask_data[cache_req_i.addr[BOFFSET-1:1]*16+:16] = cache_req_q.data;
        BYTE:      mask_data[cache_req_i.addr[BOFFSET-1:0]*8+:8] = cache_req_q.data;
        NO_SIZE:   mask_data = '0;
      endcase
      data_wr_line = cache_req_q.rw ? mask_data : lowX_res_i.data;
    // Instruction Cache
    end else begin
      cache_wr_en = cache_miss && lowX_res_i.valid && !cache_req_q.uncached || flush;
      node_wr_en = cache_wr_en || cache_hit ;
      for (int i = 0; i < NUM_WAY; i++) data_write_way[i] = evict_way[i] && cache_wr_en;
      for (int i = 0; i < NUM_WAY; i++) tag_write_way[i] = flush ? '1 : evict_way[i] && cache_wr_en;
      for (int i = 0; i < NUM_WAY; i++) cache_idx[i] = cache_wr_en ? wr_idx : rd_idx;
    end
    node_idx = node_wr_en ? wr_idx: rd_idx;
  end

  always_comb begin
    cache_miss_o = cache_miss;
    if (WHICH_CACHE == "DCACHE") begin
      lowX_req_o.valid = cache_miss && lowX_res_i.ready;
      lowX_req_o.ready = !flush;
      lowX_req_o.addr = write_back ? {evict_tag, rd_idx, {BOFFSET{1'b0}}} : {cache_req_q.addr[31:BOFFSET], {BOFFSET{1'b0}}};
      lowX_req_o.uncached = write_back ? '0 : cache_req_q.uncached;
      lowX_req_o.rw = write_back ? '1 : '0;
      lowX_req_o.rw_size = write_back ? WORD : cache_req_q.rw_size;
      lowX_req_o.data = write_back ? evict_data : '0;

      word_idx = cache_req_i.addr[(WOFFSET+2)-1:2];
      cache_res_o.valid = !cache_req_q.rw ? !write_back && cache_req_q.valid &&  (cache_hit || (cache_miss && lowX_req_o.ready && lowX_res_i.valid)) :
                          !write_back && cache_req_q.valid && cache_req_i.ready  && (cache_hit || (cache_miss && lowX_req_o.ready && lowX_res_i.valid));
      cache_res_o.ready = !cache_req_q.rw ? !write_back && (!cache_miss || lowX_res_i.valid) && !flush && !tag_array_wr_en : !write_back && !tag_array_wr_en && lowX_req_o.ready && lowX_res_i.valid && !flush;
      cache_res_o.data = (cache_miss && lowX_res_i.valid) ? lowX_res_i.data[word_idx*32+:32] : cache_select_data[word_idx*32+:32];
    end else begin
      lowX_req_o.valid    = cache_miss;
      lowX_req_o.ready    = !flush;
      lowX_req_o.addr     = cache_req_q.addr;
      lowX_req_o.uncached = cache_req_q.uncached;
      cache_res_o.valid   = cache_req_i.ready && (cache_hit || (cache_miss && lowX_req_o.ready && lowX_res_i.valid));
      cache_res_o.ready   = (!cache_miss || lowX_res_i.valid) && !flush;
      cache_res_o.data    = (cache_miss && lowX_res_i.valid) ? lowX_res_i.data : cache_select_data;
    end
  end

endmodule
