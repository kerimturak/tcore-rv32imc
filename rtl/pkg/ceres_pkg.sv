package ceres_pkg;

  localparam XLEN = 32;
  localparam BLK_SIZE = 128;
  localparam NUM_WAY = 4;

  typedef struct packed {
    logic            valid;
    logic            ready;
    logic [XLEN-1:0] addr;
    logic            uncached;
  } abuff_req_t;

  typedef struct packed {
    logic        valid;
    logic        ready;
    logic [31:0] blk;
  } abuff_res_t;


  typedef struct packed {
    logic                valid;
    logic                ready;
    logic [BLK_SIZE-1:0] blk;
  } blowX_res_t;

  typedef struct packed {
    logic            valid;
    logic            ready;
    logic [XLEN-1:0] addr;
    logic            uncached;
  } blowX_req_t;








  function automatic void get_pma_attributes(input logic [XLEN-1:0] addr_i, output logic uncached_o, output logic memregion_o, output logic grand_o);
    typedef struct packed {
      logic [XLEN-1:0] addr;
      logic [XLEN-1:0] mask;
      logic uncached;
      logic memregion;
      logic x;
      logic w;
      logic r;
    } pma_t;

    localparam pma_t [2:0] pma_map = '{
        '{addr : 32'h8000_0000, mask: 32'h000F_FFFF, uncached: 1'b0, memregion: 1'b1, x : 1'b1, w : 1'b1, r : 1'b1},
        '{addr : 32'h2000_0000, mask: 32'h0000_000F, uncached: 1'b0, memregion: 1'b0, x : 1'b0, w : 1'b1, r : 1'b1},
        '{addr : 32'h3000_0000, mask: 32'h0000_0007, uncached: 1'b1, memregion: 1'b1, x : 1'b0, w : 1'b0, r : 1'b1}
    };

    logic match_found = 0;
    uncached_o  = '0;
    memregion_o = '0;
    grand_o     = '0;

    for (int i = 0; i < 3; i++) begin
      if (pma_map[i].addr == (addr_i & ~pma_map[i].mask)) begin
        uncached_o  = pma_map[i].uncached;
        memregion_o = pma_map[i].memregion;
        grand_o     = pma_map[i].x;
        match_found = 1;
        break;
      end
    end
  endfunction






  typedef struct packed {
    logic            valid;
    logic            ready;
    logic [XLEN-1:0] addr;
    logic            uncached;
  } cache_req_t;

  typedef struct packed {
    logic                valid;
    logic                ready;
    logic [BLK_SIZE-1:0] blk;
  } cache_res_t;

  typedef struct packed {
    logic                valid;
    logic                ready;
    logic [BLK_SIZE-1:0] blk;
  } lowX_res_t;

  typedef struct packed {
    logic            valid;
    logic            ready;
    logic [XLEN-1:0] addr;
    logic            uncached;
  } lowX_req_t;
/*
  typedef struct packed {
    logic            valid;
    logic            ready;
    logic [XLEN-1:0] addr;
    logic            uncached;
    logic            rw;
    logic [1:0]      rw_size;
    logic [31:0]     data;
  } dcache_req_t;

  typedef struct packed {
    logic        valid;
    logic        ready;
    logic [31:0] data;
  } dcache_res_t;

  typedef struct packed {
    logic                valid;
    logic                ready;
    logic [BLK_SIZE-1:0] data;
  } dlowX_res_t;

  typedef struct packed {
    logic                valid;
    logic                ready;
    logic [XLEN-1:0]     addr;
    logic [1:0]          rw_size;
    logic                rw;
    logic [BLK_SIZE-1:0] data;
    logic                uncached;
  } dlowX_req_t;
*/




  // Fonksiyon: PLRU node güncellemesi
  function automatic [NUM_WAY-2:0] update_node(input logic [NUM_WAY-2:0] node_in, input logic [NUM_WAY-1:0] hit_vec);
    logic [NUM_WAY-2:0] node_tmp;
    int idx_base, shift;
    node_tmp = node_in;
    for (int unsigned i = 0; i < NUM_WAY; i++) begin
      if (hit_vec[i]) begin
        for (int unsigned lvl = 0; lvl < $clog2(NUM_WAY); lvl++) begin
          idx_base = (2 ** lvl) - 1;
          shift = $clog2(NUM_WAY) - lvl;
          // Güncelleme: ilgili bit tersleniyor
          node_tmp[idx_base+(i>>shift)] = ~((i >> (shift - 1)) & 1'b1);
        end
      end
    end
    return node_tmp;
  endfunction

  // Fonksiyon: PLRU evict_way belirleme
  function automatic [NUM_WAY-1:0] compute_evict_way(input logic [NUM_WAY-2:0] node_in);
    logic [NUM_WAY-1:0] way;
    int idx_base, shift;
    for (int unsigned i = 0; i < NUM_WAY; i++) begin
      logic en;
      en = 1'b1;
      for (int unsigned lvl = 0; lvl < $clog2(NUM_WAY); lvl++) begin
        idx_base = (2 ** lvl) - 1;
        shift = $clog2(NUM_WAY) - lvl;
        if (((i >> (shift - 1)) & 1'b1) == 1'b1) en &= node_in[idx_base+(i>>shift)];
        else en &= ~node_in[idx_base+(i>>shift)];
      end
      way[i] = en;
    end
    return way;
  endfunction
endpackage
