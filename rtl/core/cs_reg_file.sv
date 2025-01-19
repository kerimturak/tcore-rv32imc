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


  localparam MSTATUS = 12'h300;
  localparam MTVEC = 12'h305;
  localparam MIP = 12'h344;
  localparam MIE = 12'h304;
  localparam MCYCLE = 12'hB00;
  localparam MCYCLEH = 12'hB80;
  localparam MINSTRET = 12'hB02;
  localparam MINSTRETH = 12'hBB2;
  localparam MSCRATCH = 12'h340;
  localparam MEPC = 12'h341;
  localparam MCAUSE = 12'h342;
  //localparam MISA = 12'h301;

  localparam MXLEN = 32;
  //typedef struct packed {
  //  logic [25:0] extensions;
  //  logic [MXLEN-3:26] nonimp;
  //  logic [MXLEN-1:MXLEN-2] mxl;
  //} misa_t;

               //mcause codes
    localparam MACHINE_SOFTWARE_INTERRUPT =3,
               MACHINE_TIMER_INTERRUPT = 7,
               MACHINE_EXTERNAL_INTERRUPT = 11,
               INSTRUCTION_ADDRESS_MISALIGNED = 0,
               ILLEGAL_INSTRUCTION = 2,
               EBREAK = 3,
               LOAD_ADDRESS_MISALIGNED = 4,
               STORE_ADDRESS_MISALIGNED = 6,
               ECALL = 11;

  typedef struct packed {
    logic [3] mie;
    logic [7] mpie;
    logic [12:11] mpp;
  } mstatus_t;

  mstatus_t            mstatus;
  logic     [XLEN-1:0] mtvec;
  logic     [XLEN-1:0] mip;
  logic     [XLEN-1:0] mie;
  logic     [XLEN-1:0] mcycle;
  logic     [XLEN-1:0] mcycleh;
  logic     [XLEN-1:0] minstret;
  logic     [XLEN-1:0] minstreth;
  logic     [XLEN-1:0] mstratch;
  logic     [XLEN-1:0] mepc;
  logic     [XLEN-1:0] mcause;
  //misa_t               misa;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      mstatus <= '0;
      mtvec <= '0;
      mip <= '0;
      mie <= '0;
      mcycle <= '0;
      mcycleh <= '0;
      minstret <= '0;
      minstreth <= '0;
      mstratch <= '0;
      mepc <= '0;
      mcause <= '0;
      //misa.extensions <= 32'b0 | (1'b1 << 2) | (1'b1 << 8) | (1'b1 << 12);
      //misa.nonimp <= '0;
      //misa.mxl <= 'b1;
    end else if (wr_en_i) begin
      case (csr_idx_i)
        //MISA:          misa <= csr_wdata_i;
        MSTATUS:       mstatus <= csr_wdata_i;
        MTVEC:         mtvec <= csr_wdata_i;
        MIE:           mie <= csr_wdata_i;
        MIP:           mip <= csr_wdata_i;
        MCYCLE:        mcycle <= csr_wdata_i;
        MCYCLEH:       mcycleh <= csr_wdata_i;
        MINSTRET:      minstret <= csr_wdata_i;
        MINSTRETH:     minstreth <= csr_wdata_i;
        MSCRATCH:      mstratch <= csr_wdata_i;
        MEPC:          mepc <= csr_wdata_i;
        MCAUSE:        mcause <= csr_wdata_i;
        //MTVAL:         mtval <= csr_wdata_i;
      endcase
    end
  end

  always_comb begin
    if (rd_en_i) begin
      case (csr_idx_i)
        //MISA:     csr_rdata_o = misa;
        MSTATUS:  csr_rdata_o = mstatus;
        MTVEC:    csr_rdata_o = mtvec;
        MIE:      csr_rdata_o = mie;
        MIP:      csr_rdata_o = mip;
        MCYCLE:   csr_rdata_o = mcycle;
        MCYCLEH:  csr_rdata_o = mcycleh;
        MINSTRET: csr_rdata_o = minstret;
        MINSTRETH:csr_rdata_o = minstreth;
        MSCRATCH: csr_rdata_o = mstratch;
        MEPC:     csr_rdata_o = mepc;
        MCAUSE:   csr_rdata_o = mcause;
        //MTVAL:    csr_rdata_o = mtval;
        default:  csr_rdata_o = '0;
      endcase
    end else begin
      csr_rdata_o = '0;
    end
  end
endmodule
