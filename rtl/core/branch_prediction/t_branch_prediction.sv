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
// Description:    2-bit dynamic prediction                                   //
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
`include "tcore_defines.svh"
import tcore_param::*;
module t_branch_predict (
    input  logic                 clk_i,
    input  logic                 rst_ni,
    input  logic                 spec_hit_i,
    input  logic                 stall_i,
    input  logic                 is_comp_i,
    input  inst_t                inst_i,
    input  logic          [31:0] pc_i,
    input  logic          [31:0] pc2_i,
    input  logic          [31:0] pc4_i,
    input  logic                 fetch_valid_i,
    output predict_info_t        spec_o
);

  logic [31:0] imm;
  logic        j_type;
  logic        jr_type;
  logic        b_type;
  logic        instr_b_taken;
  logic        ras_valid;
  logic        req_valid;
  logic [31:0] popped_addr;
  logic [31:0] return_addr;

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
    instr_b_taken = (b_type & imm[31]);
`ifndef RAS
    spec_o.pc    = pc_i + imm;
    spec_o.taken = fetch_valid_i & (j_type || instr_b_taken ) & (spec_o.pc < 32'h4000_3D00 );
`else
    spec_o.pc    = ras_valid ? popped_addr : pc_i + imm;
    spec_o.taken = fetch_valid_i & (j_type || instr_b_taken || (ras_valid & popped_addr !=0)) & (spec_o.pc < 32'h4000_3D40 );
    req_valid = !stall_i && fetch_valid_i && (j_type || jr_type);
    return_addr = is_comp_i ? pc2_i : pc4_i;
`endif
  end
`ifdef RAS
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
`endif

  property check_spec_hit;
    @(posedge clk_i) disable iff (rst_ni) req_valid |-> (!stall_i && !spec_hit_i) throughout ##1 (!stall_i) or(!stall_i && !spec_hit_i) throughout ##2 (!stall_i);
  endproperty

  assert_check_spec_hit :
  assert property (check_spec_hit)
  else $display("Warning: spec_hit_i did not go high within 2 cycles after req_valid without stall_i.");


endmodule
