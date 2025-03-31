////////////////////////////////////////////////////////////////////////////////
// Engineer:       Kerim TURAK - kerimturak@hotmail.com
//
// Additional contributions by:
//                 --
//
// Design Name:    align_buffer
// Project Name:   TCORE
// Language:       SystemVerilog
//
// Description:    Instruction align buffer for compressed instruction support,
//                 similar in concept to a Gray cache structure.
//                 This module aligns RISC-V compressed instructions to a 32-bit boundary.
//                 It handles unaligned accesses by splitting and recombining cache lines.
////////////////////////////////////////////////////////////////////////////////

//-----------------------------------------------------------------------------
//
//   Program Counter (32 bits)
//   +---------------------------------------------------+
//   |    31 ... 10    |   9 ... 2   |   1   |    0      |
//   |      Tag        |    Index    | Offset|  Offset   |
//   +---------------------------------------------------+
//                            |           |
//                 ---------------      ------
//                 |  0000 0000  |        1
//                 |             |        |           If unaligned, add 1 to Index
//                 |             |->  0000 0001
//                 |                        |
//                 |                        ---------------------------------------------------------------------
//                 |                                                                                            |
//                 |             +--------------------------------+     +--------------------------------+      |
//                 |             |        Odd Instruction         |     |         Even Instruction       |      |
//                 |             |             Bank               |     |               Bank             |      |
//                 |             +--------------------------------+     +--------------------------------+      |
// Index'=00000000 |-> Entry 0:  | Upprt 16 bits of 32-bit Inst A |    | Lower 16 bits of 32-bit Inst A   |     |
//                     Entry 1:  | Lower 16 bits of 32-bit Inst C |    | 16-bit Inst B                    | <---| <----  Index'=00000001
//                     Entry 2:  |  16-bit Inst E                 |    | Upprt 16 bits of 32-bit Inst C   |
//                     Entry 3:  | ...                            |    |                                  |
//                               +--------------------------------+    +----------------------------------+
//                                                         \                /
//                                                          \      32      /
//                                                           \    bits    /
//                                                            \----------/
//                                                               Concatenate
//                                                                 32-bit
//                                                               Instruction
//                                                                  ↓
//                                                               To Decoder
//
// In this design, each 32-bit instruction is split into two 16-bit parcels (lower/upper).
// - Odd bank stores the lower parcels (or partial instructions when Index is base).
// - Even bank stores the upper parcels (or the next part of the instruction if unaligned).
// If the requested instruction is unaligned (PC[1] == 1 and BOFFSET-based check),
// the Index for the even bank is incremented by 1 (overflow logic).
// The final 32-bit instruction is formed by concatenating the relevant parcels.
//-----------------------------------------------------------------------------

`timescale 1ns / 1ps
module align_buffer
  import tcore_param::*;
#(
    parameter CACHE_SIZE = 512,
    parameter BLK_SIZE   = 128,
    parameter XLEN       = 32,
    parameter NUM_WAY    = 1,
    parameter DATA_WIDTH = 16
) (
    input  logic       clk_i,
    input  logic       rst_ni,
    input  logic       flush_i,
    input  abuff_req_t buff_req_i,
    output abuff_res_t buff_res_o,
    input  blowX_res_t lowX_res_i,
    output blowX_req_t lowX_req_o
);

  // Calculate the number of sets, index width, block offset, and tag size.
  localparam NUM_SET = (CACHE_SIZE / BLK_SIZE) / NUM_WAY;
  localparam IDX_WIDTH = $clog2(NUM_SET);
  localparam BOFFSET = $clog2(BLK_SIZE / 8);
  localparam WOFFSET = (BLK_SIZE / 32);
  localparam TAG_SIZE = XLEN - IDX_WIDTH - BOFFSET;

  // Define a structure similar to a gray cache line structure that holds all necessary signals.
  typedef struct packed {
    logic                                     valid;
    logic                                     match;
    logic                                     miss;
    logic                                     hit;
    logic [IDX_WIDTH-1:0]                     rd_idx;
    logic [IDX_WIDTH-1:0]                     data_wr_idx;
    logic                                     tag_wr_en;
    // Each cache line is divided into multiple parcels, each holding a 16-bit compressed instruction
    logic [(BLK_SIZE/32)-1:0][DATA_WIDTH-1:0] wr_parcel;
    logic [(BLK_SIZE/32)-1:0][DATA_WIDTH-1:0] rd_parcel;
    logic [TAG_SIZE:0]                        rd_tag;
    logic [TAG_SIZE:0]                        wr_tag;
    logic [DATA_WIDTH-1:0]                    parcel;
    logic [DATA_WIDTH-1:0]                    deviceX_parcel;
  } gray_t;

  // Define two instances (even and odd) for dual path handling.
  // Even and odd are used to manage the case when the requested instruction spans two cache lines.
  // - "even" typically corresponds to the upper half of the cache line,
  // - "odd" corresponds to the lower half.
  gray_t even, odd;
  logic [                1:0] miss_state;
  logic [                1:0] hit_state;
  logic [      IDX_WIDTH-1:0] wr_idx;
  logic                       tag_wr_en;
  logic                       data_wr_en;
  logic [         TAG_SIZE:0] wr_tag;
  // Define Block RAMs for even and odd paths
  logic [     DATA_WIDTH-1:0] ebram                                                                                 [BLK_SIZE/32] [NUM_SET];
  logic [     DATA_WIDTH-1:0] obram                                                                                 [BLK_SIZE/32] [NUM_SET];
  logic [         TAG_SIZE:0] tag_ram                                                                               [    NUM_SET];
  logic [$clog2(WOFFSET)-1:0] word_sel;
  logic [        WOFFSET-1:0] parcel_idx;  // Index to select a particular parcel within a cache line
  logic                       overflow;  // Overflow flag when unaligned access causes index wrap-around
  logic                       unalign;  // Signal indicating an unaligned access (instruction spans two cache lines)
  logic                       lookup_ack;  // Acknowledge signal for the lookup process

  always_comb begin
    // Determine if the fetch request is unaligned. Since the fetch size is 32 bits,
    // if the lower address bits (except LSB) are all ones, then the request spans cache line boundary.
    unalign = &buff_req_i.addr[BOFFSET-1:1];

    // Calculate the even index: if unaligned, add 1 to the index.
    // In case of overflow, the even index wraps to the first row.
    {overflow, even.rd_idx} = buff_req_i.addr[IDX_WIDTH+BOFFSET-1:BOFFSET] + unalign;
    // For odd, use the base index from the request address.
    odd.rd_idx = buff_req_i.addr[IDX_WIDTH+BOFFSET-1:BOFFSET];

    // Prepare tags for writing:
    // Odd path: set valid bit and extract tag from the request address.
    odd.wr_tag = {1'b1, buff_req_i.addr[XLEN-1 : IDX_WIDTH+BOFFSET]};
    // Even path: if there is an overflow (unaligned access causing index wrap),
    // then increment the odd tag; otherwise, use the same tag.
    even.wr_tag = overflow ? odd.wr_tag + 1 : odd.wr_tag;

    // Read the stored tags from the tag RAM.
    even.rd_tag = tag_ram[even.rd_idx];
    odd.rd_tag = tag_ram[odd.rd_idx];

    // Check validity and tag match.
    even.valid = even.rd_tag[TAG_SIZE];
    odd.valid = odd.rd_tag[TAG_SIZE];

    even.match = (even.rd_tag[TAG_SIZE-1:0] == even.wr_tag[TAG_SIZE-1:0]);
    odd.match = (odd.rd_tag[TAG_SIZE-1:0] == odd.wr_tag[TAG_SIZE-1:0]);

    // Determine hit and miss conditions for both even and odd paths.
    even.miss = buff_req_i.valid && !(even.valid && even.match);
    even.hit = buff_req_i.valid && (even.valid && even.match);
    odd.miss = buff_req_i.valid && !(odd.valid && odd.match);
    odd.hit = buff_req_i.valid && (odd.valid && odd.match);

    // Combine miss and hit states into 2-bit vectors.
    miss_state = {odd.miss, even.miss};
    hit_state = {odd.hit, even.hit};

    // When odd path has a miss, it gets priority over even for tag/data write.
    wr_tag = odd.miss ? odd.wr_tag : even.wr_tag;
    wr_idx = odd.miss ? odd.rd_idx : even.rd_idx;

    // Enable tag write: for even, only if odd is not missing and even is missing,
    // and for odd, if odd is missing.
    even.tag_wr_en = lowX_res_i.valid && !buff_req_i.uncached && !odd.miss && even.miss;
    odd.tag_wr_en = lowX_res_i.valid && !buff_req_i.uncached && odd.miss;
    tag_wr_en = lowX_res_i.valid && !buff_req_i.uncached && (odd.miss || (!odd.miss && even.miss));

    // Determine which index to write data to:
    // Priority is given to odd if its tag is being written.
    even.data_wr_idx = odd.tag_wr_en ? odd.rd_idx : even.rd_idx;
    odd.data_wr_idx = even.tag_wr_en && !odd.tag_wr_en ? even.rd_idx : odd.rd_idx;

    // Overall data write enable is active if either even or odd requires writing.
    data_wr_en = even.tag_wr_en || odd.tag_wr_en;
  end

  // Generate block RAMs for even and odd parcels.
  // Each cache line is divided into multiple parcels (each 16-bit wide) based on the block size.
  for (genvar i = 0; i < BLK_SIZE / 32; i++) begin
    // Combinational block for reading and splitting data from the lower level response.
    always_comb begin
      // The lower level memory block (lowX_res_i.blk) is divided into 16-bit parcels.
      // Even parcels take the even-indexed 16-bit segments.
      even.wr_parcel[i] = lowX_res_i.blk[i*32+:16];
      // Odd parcels take the odd-indexed 16-bit segments.
      odd.wr_parcel[i]  = lowX_res_i.blk[(2*i+1)*16+:16];
      // Read parcels from the respective block RAM arrays.
      even.rd_parcel[i] = ebram[i][even.rd_idx];
      odd.rd_parcel[i]  = obram[i][odd.rd_idx];
    end

    // Sequential block to write data into the block RAM arrays on the rising edge of the clock.
    always_ff @(posedge clk_i) begin
      if (data_wr_en) ebram[i][even.data_wr_idx] <= even.wr_parcel[i];
      if (data_wr_en) obram[i][odd.data_wr_idx] <= odd.wr_parcel[i];
    end
  end

  // Sequential block to update the tag RAM.
  always_ff @(posedge clk_i) begin
    if (!rst_ni | flush_i) begin
      // On reset or flush, clear the tag RAM.
      tag_ram <= '{default: '0};
    end else begin
      // For now, iterate over one way (future expansion to set-associative caches is planned).
      for (int i = 0; i < 1; i = i + 1) begin
        if (tag_wr_en) begin
          // Write the computed tag into the tag RAM at the selected index.
          tag_ram[wr_idx][i*(TAG_SIZE+1)+:(TAG_SIZE+1)] <= wr_tag[i*(TAG_SIZE+1)+:TAG_SIZE+1];
        end
      end
    end
  end

  // Combinational logic to select the appropriate word and parcel based on the access address.
  always_comb begin
    // Select the word index from the request address.
    word_sel = buff_req_i.addr[BOFFSET-1:2];
    // For unaligned access, force the parcel index to 0; otherwise, derive from the word selection.
    parcel_idx = unalign ? 0 : '0 | word_sel;

    // Even parcel selection:
    // If the access is unaligned, always use the first parcel.
    // Otherwise, select the parcel based on the sum of parcel_idx and the bit indicating lower/upper half.
    even.parcel = unalign ? even.rd_parcel[0] : even.rd_parcel[parcel_idx+buff_req_i.addr[1]];

    // Odd parcel selection:
    // The odd path uses the word selection directly.
    odd.parcel = odd.rd_parcel[word_sel];

    // Device parcel: data coming directly from the lower level response.
    odd.deviceX_parcel = lowX_res_i.blk[((word_sel+1)*32)-1-:16];
    even.deviceX_parcel = unalign ? lowX_res_i.blk[15 : 0] : lowX_res_i.blk[((word_sel+1)*32)-1-:16];
  end

  // Combinational block to combine even and odd parcels into a 32-bit instruction block.
  // The combination logic depends on whether the access is unaligned and on hit/miss status.
  always_comb begin : EVEN_ODD_COMBINE
    if (!unalign && !buff_req_i.addr[1] && |miss_state && lowX_res_i.valid) begin
      // When there is a miss in one of the parcels and the address bit 1 is 0,
      // use the lower 32 bits from the lower level response.
      buff_res_o.blk = lowX_res_i.blk[((word_sel+1)*32)-1-:32];
    end else if (buff_req_i.addr[1] && |miss_state && lowX_res_i.valid) begin
      // For unaligned accesses (address bit 1 is 1) with any miss,
      // select the appropriate parcels:
      // - Case 2'b01: even path hit (using deviceX_parcel) and odd path miss.
      // - Case 2'b10: even path miss and odd path hit (using deviceX_parcel).
      // - Case 2'b11: both miss result in a zeroed block.
      case (miss_state)
        2'b00: buff_res_o.blk = {even.parcel, odd.parcel};  // Should never occur if both are hit.
        2'b01: buff_res_o.blk = {even.deviceX_parcel, odd.parcel};  // Lower (even) miss; use deviceX parcel.
        2'b10: buff_res_o.blk = {even.parcel, odd.deviceX_parcel};  // Upper (odd) miss; use deviceX parcel.
        2'b11: buff_res_o.blk = '0;  // Both paths miss.
      endcase
    end else if (!buff_req_i.addr[1] && &hit_state) begin
      // For aligned accesses (address bit 1 is 0) with both hits, combine odd and even parcels.
      buff_res_o.blk = {odd.parcel, even.parcel};
    end else begin
      // Default case: combine even and odd parcels.
      buff_res_o.blk = {even.parcel, odd.parcel};
    end
  end

  // Combinational block to generate final valid/ready signals and prepare the lower-level request.
  always_comb begin
    // Determine when the buffer response is valid:
    // It is valid when the fetch request is ready and either both hit,
    // or when a miss condition exists but a valid lower level response is present.
    buff_res_o.valid = buff_req_i.ready && (&hit_state || (((|miss_state && !buff_req_i.addr[1]) || (!(&miss_state) && buff_req_i.addr[1])) && lowX_res_i.valid));
    // The buffer is ready when not in reset or flush and either no miss exists or a valid response is available.
    buff_res_o.ready = rst_ni && !flush_i && ((!even.miss && !odd.miss) || (lowX_res_i.valid && !(&miss_state)));
    // Indicate if there is any miss in the even or odd path.
    buff_res_o.miss  = |miss_state;

    // Generate the lower level request signal.
    if (&miss_state) begin
      // When both even and odd paths miss:
      if (lowX_res_i.valid) begin
        lowX_req_o.valid = !lookup_ack && (unalign ? !buff_req_i.uncached : 0);
      end else begin
        lowX_req_o.valid = !lookup_ack && !buff_req_i.uncached;
      end
    end else if (|miss_state) begin
      lowX_req_o.valid = !lookup_ack && !buff_req_i.uncached && !lowX_res_i.valid;
    end else begin
      lowX_req_o.valid = 0;
    end
    lowX_req_o.ready = rst_ni && !flush_i;
    lowX_req_o.uncached = buff_req_i.uncached;

    // Calculate the address for the lower level request.
    // For unaligned accesses with odd miss, adjust the address accordingly.
    case ({
      unalign, odd.miss, even.miss
    })
      3'b101:  lowX_req_o.addr = (buff_req_i.addr & '1 << 4) + (BLK_SIZE / 8);
      default: lowX_req_o.addr = buff_req_i.addr & '1 << 4;
    endcase
  end

  // Sequential block to manage the lookup acknowledge signal.
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      lookup_ack <= '0;
    end else begin
      // The lookup acknowledge is set based on the lower level response and request readiness.
      lookup_ack <= lowX_res_i.valid ? !lowX_req_o.ready : (!lookup_ack ? lowX_req_o.valid && lowX_res_i.ready : lookup_ack);
    end
  end
endmodule
