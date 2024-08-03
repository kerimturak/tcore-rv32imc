// This module includes portions of the CVA6 TLB implementation.
// PLRU mechanism is converted a module.

// Copyright (c) 2018 ETH Zurich and University of Bologna.
// Copyright (c) 2021 Thales.
// Copyright (c) 2022 Bruno Sá and Zero-Day Labs.
// Copyright (c) 2024 PlanV Technology
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Angela Gonzalez PlanV Technology
// Date: 26/02/2024

`timescale 1ns / 1ps
`include "tcore_defines.svh"
module plru #(
    parameter NUM_WAY = 4
) (
    input  logic [NUM_WAY-2:0] node_i,
    input  logic [NUM_WAY-1:0] hit_vec_i,
    output logic [NUM_WAY-1:0] evict_way_o,
    output logic [NUM_WAY-2:0] node_o
);

  always_comb begin : plru_replacement
    node_o = node_i;
    for (int unsigned i = 0; i < NUM_WAY; i++) begin
      automatic int unsigned idx_base, shift, new_index;
      if (hit_vec_i[i]) begin
        for (int unsigned lvl = 0; lvl < $clog2(NUM_WAY); lvl++) begin
          idx_base = $unsigned((2 ** lvl) - 1);
          shift = $clog2(NUM_WAY) - lvl;
          new_index = ~((i >> (shift - 1)) & 32'b1);
          node_o[idx_base+(i>>shift)] = new_index[0];
        end
      end
    end

    evict_way_o = '0;
    for (int unsigned i = 0; i < NUM_WAY; i += 1) begin
      automatic int unsigned idx_base, shift, new_index;
      automatic logic en;
      en = 1'b1;
      for (int unsigned lvl = 0; lvl < $clog2(NUM_WAY); lvl++) begin
        idx_base = $unsigned((2 ** lvl) - 1);
        shift = $clog2(NUM_WAY) - lvl;
        new_index = (i >> (shift - 1)) & 32'b1;
        if (new_index[0]) begin
          en &= node_i[idx_base+(i>>shift)];
        end else begin
          en &= ~node_i[idx_base+(i>>shift)];
        end
      end
      evict_way_o[i] = en;
    end
  end
endmodule
