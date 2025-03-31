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
module dcache
  import tcore_param::*;
#(
    parameter CACHE_SIZE = (DC_CAPACITY),
    parameter BLK_SIZE = tcore_param::BLK_SIZE,
    parameter XLEN = tcore_param::XLEN,
    parameter NUM_WAY = DC_WAY
) (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  dcache_req_t cache_req_i,
    output dcache_res_t cache_res_o,
    input  dlowX_res_t  lowX_res_i,
    output dlowX_req_t  lowX_req_o
);

  localparam NUM_SET = (CACHE_SIZE / BLK_SIZE) / NUM_WAY;
  localparam IDX_WIDTH = $clog2(NUM_SET) == 0 ? 1 : $clog2(NUM_SET);
  localparam BOFFSET = $clog2(BLK_SIZE / 8);
  localparam WOFFSET = $clog2((BLK_SIZE / 32));
  localparam TAG_SIZE = XLEN - IDX_WIDTH - BOFFSET;

  logic                  uncached_q;
  logic                  rw_q;
  logic[1:0]                 rw_size_q;
  logic                  cache_miss;
  logic                  cache_hit;
  logic  [IDX_WIDTH-1:0] pc_idx;
  logic  [     XLEN-1:0] addr_q;
  logic  [         31:0] wdata_q;
  logic  [  NUM_WAY-1:0] cache_wr_way;
  logic  [ BLK_SIZE-1:0] cache_select_data;
  logic  [ BLK_SIZE-1:0] mask_data;
  logic                  data_array_wr_en;
  logic  [ BLK_SIZE-1:0] data_wr_pre;
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
  logic  [IDX_WIDTH-1:0] cache_idx;
  logic  [  NUM_WAY-1:0] tag_write_way;
  logic                  node_wr_en;
  logic  [  NUM_WAY-2:0] updated_node;
  logic  [  NUM_WAY-2:0] cache_wr_node;
  logic  [  NUM_WAY-2:0] cache_rd_node;
  logic                  cpu_valid_q;
  logic  [  WOFFSET-1:0] word_idx;
  logic                  write_back;
  logic                  dirty_wr_en;
  logic  [  NUM_WAY-1:0] dirty_write_way;
  logic                  dirty_wr_data;
  logic  [  NUM_WAY-1:0] dirty_rd_data;
  logic  [ TAG_SIZE-1:0] evict_tag;
  logic  [ BLK_SIZE-1:0] evict_data;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      addr_q      <= '0;
      wdata_q     <= '0;
      uncached_q  <= '0;
      rw_q        <= '0;
      rw_size_q   <= 0;
      cpu_valid_q <= '0;
      flush_index <= '0;
      flush       <= '1;
    end else begin
      addr_q      <= cache_req_i.addr;
      wdata_q     <= cache_req_i.data;
      cpu_valid_q <= cache_req_i.valid;
      uncached_q  <= cache_req_i.uncached;
      rw_q        <= cache_req_i.rw;
      rw_size_q   <= cache_req_i.rw_size;
      if (flush && flush_index != 2 ** IDX_WIDTH - 1) begin
        flush_index <= flush_index + 1'b1;
      end else begin
        flush_index <= 1'b0;
        flush       <= 1'b0;
      end
    end
  end

  for (genvar i = 0; i < NUM_WAY; i++) begin : ddata_array
    sp_bram #(
        .DATA_WIDTH(BLK_SIZE),
        .NUM_SETS  (NUM_SET)
    ) data_array (
        .clk    (clk_i),
        .chip_en(1'b1),
        .addr   (pc_idx),
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
        .addr   (cache_idx),
        .wr_en  (tag_write_way[i]),
        .wr_data(cache_wr_tag),
        .rd_data(cache_rd_tag[i])
    );
  end

  for (genvar i = 0; i < NUM_WAY; i++) begin : ddirty_array
    sp_bram #(
        .DATA_WIDTH(1),
        .NUM_SETS  (NUM_SET)
    ) dirty_array (
        .clk    (clk_i),
        .chip_en(1'b1),
        .addr   (cache_idx),
        .wr_en  (dirty_write_way[i]),
        .wr_data(dirty_wr_data),
        .rd_data(dirty_rd_data[i])
    );
  end

  sp_bram #(
      .DATA_WIDTH(NUM_WAY - 1),
      .NUM_SETS  (NUM_SET)
  ) node_array (
      .clk    (clk_i),
      .chip_en(1'b1),
      .addr   (cache_idx),
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

  always_comb begin
    data_wr_pre = mask_data;
    case (rw_size_q)
      2'b00:data_wr_pre[cache_req_i.addr[BOFFSET-1:2]*32+:32] = wdata_q;
      2'b01:data_wr_pre[cache_req_i.addr[BOFFSET-1:1]*16+:16] = wdata_q;
      2'b10:data_wr_pre[cache_req_i.addr[BOFFSET-1:0]*8+:8] = wdata_q;
      2'b11:data_wr_pre = '0;
    endcase
  end

  always_comb begin
    for (int i = 0; i < NUM_WAY; i++) begin
      cache_valid_vec[i] = cache_rd_tag[i][TAG_SIZE];
      cache_hit_vec[i]   = cache_rd_tag[i][TAG_SIZE-1:0] == addr_q[XLEN-1:IDX_WIDTH+BOFFSET];
    end
    cache_wr_tag = flush ? '0 : {1'b1, addr_q[XLEN-1:IDX_WIDTH+BOFFSET]};
    cache_wr_node = flush ? '0 : updated_node;
    cache_select_data = '0;
    for (int i = 0; i < NUM_WAY; i++) begin
      if (cache_hit_vec[i]) cache_select_data = data_rd_line[i];
    end

    cache_miss = cpu_valid_q && !flush && !(|(cache_valid_vec & cache_hit_vec));
    cache_hit = cpu_valid_q && !flush && (|(cache_valid_vec & cache_hit_vec));

    cache_wr_way = cache_hit ? cache_hit_vec : evict_way;

    write_back = cache_miss && (|(dirty_rd_data & evict_way & cache_valid_vec));
    data_array_wr_en = (cache_hit && rw_q) || (cache_miss && lowX_res_i.valid && !uncached_q) && !write_back;
    tag_array_wr_en = (cache_miss && lowX_res_i.valid && !uncached_q) && !write_back;

    pc_idx = cache_req_i.addr[IDX_WIDTH+BOFFSET:BOFFSET];
    cache_idx = flush ? flush_index : pc_idx;

    dirty_wr_en = (rw_q && (cache_hit || (cache_miss && lowX_res_i.valid))) || (write_back && lowX_res_i.valid);
    for (int i = 0; i < NUM_WAY; i++) dirty_write_way[i] = flush ? '1 : cache_wr_way[i] && dirty_wr_en || flush;
    dirty_wr_data = flush ? '0 : (write_back ? '0 : rw_q ? '1 : '0);

    evict_tag = '0;
    evict_data = '0;
    for (int i = 0; i < NUM_WAY; i++) if (evict_way[i]) evict_tag = cache_rd_tag[i][TAG_SIZE-1:0];
    for (int i = 0; i < NUM_WAY; i++) if (evict_way[i]) evict_data = data_rd_line[i];

    for (int i = 0; i < NUM_WAY; i++) data_write_way[i] = cache_wr_way[i] && data_array_wr_en;
    for (int i = 0; i < NUM_WAY; i++) tag_write_way[i] = flush ? '1 : cache_wr_way[i] && tag_array_wr_en || flush;

    mask_data = cache_hit ? cache_select_data : lowX_res_i.data;
    data_wr_line = rw_q ? data_wr_pre : lowX_res_i.data;

    node_wr_en    = flush || data_array_wr_en;
  end

  always_comb begin
    word_idx = cache_req_i.addr[(WOFFSET+2)-1:2];
    lowX_req_o.valid = cache_miss && lowX_res_i.ready;
    lowX_req_o.ready = 1'b1;
    lowX_req_o.uncached = write_back ? '0 : uncached_q;
    lowX_req_o.addr = write_back ? {evict_tag, pc_idx, {BOFFSET{1'b0}}} : {addr_q[31:BOFFSET], {BOFFSET{1'b0}}};
    lowX_req_o.rw = write_back ? '1 : '0;
    lowX_req_o.rw_size = write_back ? 2'b11 : rw_size_q;
    lowX_req_o.data = write_back ? evict_data : '0;

    cache_res_o.valid = !rw_q ? !write_back && cpu_valid_q &&  (cache_hit || (cache_miss && lowX_req_o.ready && lowX_res_i.valid)) :
                        !write_back && cpu_valid_q && cache_req_i.ready  && (cache_hit || (cache_miss && lowX_req_o.ready && lowX_res_i.valid));
    cache_res_o.ready = !rw_q ? !write_back && (!cache_miss || lowX_res_i.valid) && !flush && !tag_array_wr_en : !write_back && !tag_array_wr_en && lowX_req_o.ready && lowX_res_i.valid && !flush;
    dcache_res.miss = cache_miss;
    cache_res_o.data = (cache_miss && lowX_res_i.valid) ? lowX_res_i.data[word_idx*32+:32] : cache_select_data[word_idx*32+:32];
  end

endmodule
