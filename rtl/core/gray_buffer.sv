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
// Design Name:    gray_align_buffer                                          //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Instruction align buffer for compressed instruction        //
//                 support  likewise Gray cache structure                     //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`include "tcore_defines.svh"
module gray_align_buffer
  import tcore_param::*;
#(
    parameter CACHE_SIZE = BUFFER_CAPACITY,
    parameter BLK_SIZE   = 128,
    parameter XLEN       = 32,
    parameter NUM_WAY    = 1,
    parameter DATA_WIDTH = 16
) (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  icache_req_t buff_req_i,
    output gbuff_res_t  buff_res_o,
    output logic        buffer_miss_o,
    input  ilowX_res_t  lowX_res_i,
    output ilowX_req_t  lowX_req_o
);

  localparam NUM_SET = (CACHE_SIZE / BLK_SIZE) / NUM_WAY;
  localparam IDX_WIDTH = $clog2(NUM_SET);
  localparam BOFFSET = $clog2(BLK_SIZE / 8);
  localparam WOFFSET = (BLK_SIZE / 32);
  localparam TAG_SIZE = XLEN - IDX_WIDTH - BOFFSET;

  logic cpu_valid_q;

  typedef struct packed {
    logic valid;
    logic match;
    logic miss;
    logic hit;
    logic [IDX_WIDTH-1:0] rd_idx;
    logic [IDX_WIDTH-1:0] data_wr_idx;
    logic tag_wr_en;
    logic [(BLK_SIZE/32)-1:0][DATA_WIDTH-1:0] wr_parcel;
    logic [(BLK_SIZE/32)-1:0][DATA_WIDTH-1:0] rd_parcel;
    logic [TAG_SIZE:0] rd_tag;
    logic [TAG_SIZE:0] wr_tag;
    logic [DATA_WIDTH-1:0] parcel;
    logic [DATA_WIDTH-1:0] deviceX_parcel;
  } gray_t;

  gray_t even, odd;
  logic [           1:0] miss_state;
  logic [           1:0] hit_state;
  logic [ IDX_WIDTH-1:0] wr_idx;
  logic                  tag_wr_en;
  logic                  data_wr_en;
  logic [    TAG_SIZE:0] wr_tag;
  logic [    TAG_SIZE:0] wr_tag_q;
  logic [DATA_WIDTH-1:0] ebram      [BLK_SIZE/32] [NUM_SET];
  logic [DATA_WIDTH-1:0] obram      [BLK_SIZE/32] [NUM_SET];
  logic [    TAG_SIZE:0] tag_ram    [    NUM_SET];
  logic [           1:0] word_sel;
  logic [   WOFFSET-1:0] parcel_idx;
  logic                  overflow;
  logic                  unalign;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      cpu_valid_q <= '0;
      wr_tag_q    <= '0;
    end else begin
      cpu_valid_q <= buff_req_i.valid;
      wr_tag_q    <= wr_tag;
    end
  end

  always_comb begin
    unalign = &buff_req_i.addr[3:1];
    {overflow, even.rd_idx} = buff_req_i.addr[IDX_WIDTH+BOFFSET-1:BOFFSET] + unalign;
    odd.rd_idx = buff_req_i.addr[IDX_WIDTH+BOFFSET-1:BOFFSET];

    odd.wr_tag = {1'b1, buff_req_i.addr[XLEN-1 : IDX_WIDTH+BOFFSET]};
    even.wr_tag = overflow ? odd.wr_tag + 1 : odd.wr_tag;

    even.rd_tag = tag_ram[even.rd_idx];
    odd.rd_tag = tag_ram[odd.rd_idx];

    even.valid = even.rd_tag[TAG_SIZE];
    odd.valid = odd.rd_tag[TAG_SIZE];

    even.match = (even.rd_tag[TAG_SIZE-1:0] == even.wr_tag[TAG_SIZE-1:0]);
    odd.match = (odd.rd_tag[TAG_SIZE-1:0] == odd.wr_tag[TAG_SIZE-1:0]);

    even.miss = cpu_valid_q && !(even.valid && even.match);
    even.hit = cpu_valid_q && (even.valid && even.match);
    odd.miss = cpu_valid_q && !(odd.valid && odd.match);
    odd.hit = cpu_valid_q && (odd.valid && odd.match);

    miss_state = {odd.miss, even.miss};
    hit_state = {odd.hit, even.hit};

    wr_tag = odd.miss ? odd.wr_tag : even.wr_tag;
    wr_idx = odd.miss ? odd.rd_idx : even.rd_idx;

    //! not odd_miss or or not unalign so write even
    even.tag_wr_en = lowX_res_i.valid && !buff_req_i.uncached && !odd.miss && even.miss;
    // odd misses have priority
    odd.tag_wr_en = lowX_res_i.valid && !buff_req_i.uncached && odd.miss;
    tag_wr_en = lowX_res_i.valid && !buff_req_i.uncached && (odd.miss || (!odd.miss && even.miss));

    even.data_wr_idx = odd.tag_wr_en ? odd.rd_idx : even.rd_idx;
    odd.data_wr_idx = even.tag_wr_en && !odd.tag_wr_en ? even.rd_idx : odd.rd_idx;

    data_wr_en = even.tag_wr_en || odd.tag_wr_en;
  end

  for (genvar i = 0; i < BLK_SIZE / 32; i++) begin
    always_comb begin
      even.wr_parcel[i] = lowX_res_i.blk[i*32+:16];
      odd.wr_parcel[i]  = lowX_res_i.blk[(2*i+1)*16+:16];
      even.rd_parcel[i] = ebram[i][even.rd_idx];
      odd.rd_parcel[i]  = obram[i][odd.rd_idx];
    end

    always_ff @(posedge clk_i) begin
      if (data_wr_en) ebram[i][even.data_wr_idx] <= even.wr_parcel[i];
      if (data_wr_en) obram[i][odd.data_wr_idx] <= odd.wr_parcel[i];
    end
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      tag_ram <= '{default: '0};
    end else begin
      for (int i = 0; i < 1; i = i + 1) begin
        if (tag_wr_en) begin
          tag_ram[wr_idx][i*(TAG_SIZE+1)+:(TAG_SIZE+1)] <= wr_tag_q[i*(TAG_SIZE+1)+:TAG_SIZE+1];
        end
      end
    end
  end

  always_comb begin
    word_sel = buff_req_i.addr[3:2];
    parcel_idx = unalign ? 0 : {2'b0, word_sel};
    even.parcel = unalign ? even.rd_parcel[0] : even.rd_parcel[parcel_idx+buff_req_i.addr[1]];
    odd.parcel = odd.rd_parcel[word_sel];
    odd.deviceX_parcel = lowX_res_i.blk[((word_sel+1)*32)-1-:16];
    even.deviceX_parcel = unalign ? lowX_res_i.blk[15 : 0] : lowX_res_i.blk[((word_sel+1)*32)-1-:16];
  end

  always_comb begin : EVEN_ODD_COMBINE
    if (!unalign && !buff_req_i.addr[1] && |miss_state && lowX_res_i.valid) begin
      // two parcell miss and not unalign
      buff_res_o.blk = lowX_res_i.blk[((word_sel+1)*32)-1-:32];
    end else if (buff_req_i.addr[1] && |miss_state && lowX_res_i.valid) begin
      // unalign
      case (miss_state)
        2'b00: buff_res_o.blk = {even.parcel, odd.parcel};  // never
        2'b01: buff_res_o.blk = {even.deviceX_parcel, odd.parcel};  // lower:hit | upper:miss
        2'b10: buff_res_o.blk = {even.parcel, odd.deviceX_parcel};
        2'b11: buff_res_o.blk = '0;
      endcase
    end else if (!buff_req_i.addr[1] && &hit_state) begin
      buff_res_o.blk = {odd.parcel, even.parcel};
    end else begin
      buff_res_o.blk = {even.parcel, odd.parcel};
    end
  end

  always_comb begin
    buff_res_o.valid = buff_req_i.ready && (&hit_state || (((|miss_state && !buff_req_i.addr[1]) || (!(&miss_state) && buff_req_i.addr[1])) && lowX_res_i.valid));
    buff_res_o.ready = ((!even.miss && !odd.miss) || (lowX_res_i.valid && !(&miss_state)));
    buffer_miss_o = |miss_state;
    lowX_req_o.valid = (|miss_state && !buff_req_i.uncached);
    lowX_req_o.ready = 1'b1;
    lowX_req_o.uncached = buff_req_i.uncached;

    case ({
      unalign, odd.miss, even.miss
    })
      3'b101:  lowX_req_o.addr = (buff_req_i.addr & '1 << 4) + 16;
      default: lowX_req_o.addr = buff_req_i.addr & '1 << 4;
    endcase
  end

endmodule
