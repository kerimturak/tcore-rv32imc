////////////////////////////////////////////////////////////////////////////////
// Engineer:       Kerim TURAK - kerimturak@hotmail.com                       //
//                                                                            //
// Additional contributions by:                                               //
//                 --                                                         //
//                                                                            //
// Design Name:    ras                                                        //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    RAS (Return Address Stack) Unit                            //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module ras
  import tcore_param::*;
#(
    parameter RAS_SIZE = 8
) (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic        restore_i,
    input  logic [31:0] restore_pc_i,
    input  logic        req_valid_i,
    input  logic        j_type_i,
    input  logic        jr_type_i,
    input  logic [ 4:0] rd_addr_i,
    input  logic [ 4:0] r1_addr_i,
    input  logic [31:0] return_addr_i,
    output logic [31:0] popped_addr_o,
    output logic        predict_valid_o
);

  // RAS operation types
  typedef enum logic [1:0] {
    NONE,
    PUSH,
    POP,
    BOTH
  } ras_op_e;

  logic    [XLEN-1:0] ras                               [RAS_SIZE-1:0];  // Stack memory
  ras_op_e            ras_op;  // Selected RAS operation
  logic               link_rd;
  logic               link_r1;

  // Combinational logic to determine RAS operation and outputs
  always_comb begin
    ras_op  = NONE;

    link_rd = (rd_addr_i == 5'd1 || rd_addr_i == 5'd5);  // Link register x1 (ra) or x5 (t0)
    link_r1 = (r1_addr_i == 5'd1 || r1_addr_i == 5'd5);

    if (req_valid_i) begin
      if (j_type_i && link_rd) ras_op = PUSH;
      else if (jr_type_i && (link_rd || link_r1)) begin
        if (link_rd && link_r1) ras_op = (rd_addr_i == r1_addr_i) ? PUSH : BOTH;
        else if (link_r1) ras_op = POP;
        else ras_op = PUSH;
      end
    end
    popped_addr_o   = (ras_op == BOTH) ? return_addr_i : ras[0];
    predict_valid_o = req_valid_i && (ras_op inside {POP, BOTH});
  end

  // Sequential logic for RAS behavior on clock edge
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      ras <= '{default: 0};
    end else begin
      if (restore_i) begin
        for (int i = RAS_SIZE - 1; i > 0; i--) ras[i] <= ras[i-1];
        ras[0] <= restore_pc_i;
      end else if (req_valid_i) begin
        case (ras_op)
          PUSH: begin
            for (int i = RAS_SIZE - 1; i > 0; i--) ras[i] <= ras[i-1];
            ras[0] <= return_addr_i;
          end
          POP: begin
            for (int i = 0; i < RAS_SIZE - 1; i++) ras[i] <= ras[i+1];
          end
          BOTH: begin
            ras[0] <= return_addr_i;
          end
        endcase
      end
    end
  end

endmodule
