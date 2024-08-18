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
// Design Name:    reg_file                                                   //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Core integer registers                                     //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`include "tcore_defines.svh"
module cs_reg_file
  import tcore_param::*;
(
    input  logic            clk_i,
    input  logic            rst_ni,
    input  logic            rd_en_i,
    input  logic            wr_en_i,
    input  logic [    11:0] csr_idx_i,
    input  logic [XLEN-1:0] csr_wdata_i,
    output logic [XLEN-1:0] csr_rdata_o
);

  localparam MVENDORID = 12'hF11, MARCHID = 12'hF12, MIMPID = 12'hF13, MHARTID = 12'hF14,
  //machine trap setup
  MSTATUS = 12'h300, MISA = 12'h301, MIE = 12'h304, MTVEC = 12'h305,
  //machine trap handling
  MSCRATCH = 12'h340, MEPC = 12'h341, MCAUSE = 12'h342, MTVAL = 12'h343, MIP = 12'h344,
  //machine counters/timers
  MCYCLE = 12'hB00, MCYCLEH = 12'hB80,
  //TIME = 12'hC01,
  //TIMEH = 12'hC81,
  MINSTRET = 12'hB02, MINSTRETH = 12'hBB2, MCOUNTINHIBIT = 12'h320;

  logic [XLEN-1:0] mstatus;
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      csr_rdata_o <= '0;
      mstatus     <= '0;
    end else begin
      case (csr_idx_i)
        MSTATUS: begin
          case ({
            rd_en_i, wr_en_i
          })
            2'b00: csr_rdata_o <= '0;
            2'b01: mstatus <= csr_wdata_i;
            2'b10: csr_rdata_o <= mstatus;
            2'b11: begin
              csr_rdata_o <= mstatus;
              mstatus <= csr_wdata_i;
            end
          endcase
        end
      endcase
    end
  end
endmodule
