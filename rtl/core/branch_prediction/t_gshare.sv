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
// Design Name:    branch_prediction                                          //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Global History-Based Branch Predictor                      //
//                    - Global History Register - GHR                         //
//                    - Pattern History Table - PHT                           //
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
`include "tcore_defines.svh"
import tcore_param::*;
module t_gshare (
    input  logic                     clk_i,
    input  logic                     rst_ni,
    input  logic                     spec_hit_i,
    input  logic                     stall_i,
    input  logic                     is_comp_i,
    input  inst_t                    inst_i,
    input  logic          [XLEN-1:0] pc_target_i,
    input  logic          [31:0]     pc_i,
    input  logic          [31:0]     pc2_i,
    input  logic          [31:0]     pc4_i,
    input  logic                     fetch_valid_i,
    output predict_info_t            spec_o
);

  logic [31:0] imm;
  logic        j_type;
  logic        jr_type;
  logic        b_type;
  logic        ras_valid;
  logic        req_valid;
  logic [31:0] popped_addr;
  logic [31:0] return_addr;

  // Global History logicister (GHR)
  // Pattern History Table (PHT) - 2-bit saturating counters
  // Branch Target Buffer (BTB)

  localparam PHT_SIZE = 128; // Pattern History Table size (number of entries)
  localparam BTB_SIZE = 128; // Branch Target Buffer size (number of entries)
  localparam GHR_SIZE = 9;  // Global History logicister size (in bits)
  logic           [31:0]                  stage_pc    [1:0];
  logic                                   branch_q    [1:0];
  logic                                   taken_q     [1:0];
  predict_info_t                          branch;
  logic           [GHR_SIZE-1:0]          ghr;
  logic           [1:0]                   pht         [PHT_SIZE];
  logic           [31:0]                  btb_target  [BTB_SIZE];
  logic           [31:$clog2(PHT_SIZE)+1] btb_pc      [BTB_SIZE];
  logic           [$clog2(PHT_SIZE)-1:0]  pht_rd_idx;
  logic           [$clog2(PHT_SIZE)-1:0]  pht_wr_idx;
  logic           [$clog2(BTB_SIZE)-1:0]  btb_rd_idx;
  logic           [$clog2(BTB_SIZE)-1:0]  btb_wr_idx;
  logic           [1:0]                   pht_ptr;
  logic           [1:0]                   pht_bit1;
  logic                                   ex_taken;

  always_comb begin
    b_type  = inst_i[6:0] == op_b_type;
    j_type  = inst_i[6:0] == op_u_type_jump;
    jr_type = inst_i[6:0] == op_i_type_jump;
    case (1'b1)
      b_type:  imm = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};  // b 13-bit signed immediate
      j_type:  imm = {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};  // J 20-bit signed immediate
      jr_type: imm = {{20{inst_i[31]}}, inst_i[31:20]};  // I 21-bit signed immediate
      default: imm = '0;
    endcase
    spec_o.pc    = ras_valid ? popped_addr : j_type ? pc_i + imm : branch.pc;
    spec_o.taken = fetch_valid_i && (j_type || branch.taken || (ras_valid && popped_addr !=0)) && (spec_o.pc < 32'h4000_3D40 );
    req_valid = !stall_i && fetch_valid_i && (j_type || jr_type);
    return_addr = is_comp_i ? pc2_i : pc4_i;
  end

  ras ras (
      .clk_i          (clk_i),
      .rst_ni         (rst_ni),
      .spec_hit_i     (spec_hit_i),
      .stall_i        (stall_i),
      .req_valid_i    (req_valid),
      .rd_addr_i      (inst_i.rd_addr),
      .r1_addr_i      (inst_i.r1_addr),
      .j_type_i       (j_type),
      .jr_type_i      (jr_type),
      .return_addr_i  (return_addr),
      .popped_addr_o  (popped_addr),
      .predict_valid_o(ras_valid)
  );

  always_comb begin
    pht_rd_idx = pc_i[$clog2(PHT_SIZE):1] ^ ghr[$clog2(PHT_SIZE)-1:0];
    btb_rd_idx = pc_i[$clog2(BTB_SIZE):1];
    pht_wr_idx = stage_pc[1][$clog2(PHT_SIZE):1] ^ ghr[$clog2(PHT_SIZE)-1:0];
    btb_wr_idx = stage_pc[1][$clog2(BTB_SIZE):1];
    ex_taken   = (spec_hit_i && taken_q[1]) || ((!spec_hit_i && !taken_q[1]));
    // Predicted PC output and valid signal
    branch.pc = (pht[pht_rd_idx][1]) && b_type ? btb_target[btb_rd_idx] : (is_comp_i ? pc2_i : pc4_i);
    branch.taken = (btb_pc[btb_rd_idx] == pc_i[31:$clog2(PHT_SIZE)+1]) && (pht[pht_rd_idx][1]);
  end

  always_ff @(posedge clk_i) begin
    if (rst_ni) begin
      stage_pc <= '{default:0};
      branch_q <= '{default:0};
      taken_q  <= '{default:0};
      pht_bit1 <= '{default:0};
    end else if (!stall_i) begin
      if (!spec_hit_i) begin
        stage_pc <= '{default:0};
        branch_q <= '{default:0};
        taken_q  <= '{default:0};
        pht_bit1 <= '{default:0};
      end else begin
        stage_pc[1] <= stage_pc[0];
        stage_pc[0] <= pc_i;
        branch_q[1] <= branch_q[0];
        branch_q[0] <= b_type;
        taken_q[1]  <= taken_q[0];
        taken_q[0]  <= spec_o.taken;
        pht_bit1[1] <= pht_bit1[0];
        pht_bit1[0] <= pht[pht_wr_idx][1];
      end
    end
  end

  // Update logic
  always @(posedge clk_i) begin
    if (rst_ni) begin
      ghr        <= 0;
      btb_target <= '{default:0};
      btb_pc     <= '{default:0};
      pht        <= '{default:2'b01}; // Initialize as "Weakly Not Taken"
      pht_ptr    <= '0;
    end else begin 
      if (branch_q[1] && !stall_i) begin  // Sadece branch türü bir talimat yürütülüyorsa güncelle
        if (ex_taken) begin // Update PHT and GHR
          if (pht[pht_wr_idx] < 2'b11) pht[pht_wr_idx]++;
        end else begin
          if (pht[pht_wr_idx] > 2'b00) pht[pht_wr_idx]--;
        end

        btb_target[btb_wr_idx]  <= ex_taken ? pc_target_i : '0;
        btb_pc[btb_wr_idx]      <= ex_taken ? stage_pc[1][31:$clog2(PHT_SIZE)+1] : '0;
        pht_ptr                 <= ex_taken ? pht_ptr + 1 : 0;
        //ghr                     <= ex_taken ? {ghr[GHR_SIZE-2:0], pht_bit1[1]} : {1'b0, pht_ptr >> ghr[GHR_SIZE-1:1]};
        ghr                     <= ex_taken ? {ghr[GHR_SIZE-2:0], pht_bit1[1] & spec_hit_i} : {1'b0, pht_ptr >> ghr[GHR_SIZE-1:1]};


      end
    end
  end
  
  logic [31:0] per_count_predict_hit;
  logic [31:0] per_count_predict_miss;

  always_ff @(posedge clk_i) begin
    if (rst_ni) begin
      per_count_predict_hit  <= '0;
      per_count_predict_miss <= '0;
    end else if (!stall_i && branch_q[1]) begin
      if (!spec_hit_i) begin
        per_count_predict_miss ++;
      end else begin
        per_count_predict_hit ++;
      end
    end
  end

endmodule
