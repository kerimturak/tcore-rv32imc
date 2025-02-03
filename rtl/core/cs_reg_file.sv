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
// Engineer:       Kerim TURAK - kerimturak@hotmail.com
//
// Additional contributions by:
//
// Design Name:    reg_file
// Project Name:   TCORE
// Language:       SystemVerilog
//
// Description:    Core integer registers
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
    input  logic [11:0]     csr_idx_i,
    input  logic [XLEN-1:0] csr_wdata_i,
    output logic [XLEN-1:0] csr_rdata_o,
    input  logic            trap_active_i,
    input  instr_type_e     instr_type_i,
    input  logic [XLEN-1:0] trap_cause_i,
    input  logic [XLEN-1:0] trap_mepc_i,
    output logic [XLEN-1:0] mtvec_o,
    output logic [XLEN-1:0] mepc_o
);

  // Unused (veya ileride kullanılacak) sinyaller:
  logic go_to_trap;
  logic go_to_trap_q;
  logic return_trap;
  logic return_trap_q;

  // CSR adres tanımları
  localparam MSTATUS    = 12'h300;
  localparam MTVEC      = 12'h305;
  localparam MIE_ADDR   = 12'h304;  // Ayrı MIE CSR'si
  localparam MIP        = 12'h344;
  localparam MCYCLE     = 12'hB00;
  localparam MCYCLEH    = 12'hB80;
  localparam MINSTRET   = 12'hB02;
  localparam MINSTRETH  = 12'hB82;  // Düzeltildi
  localparam MSCRATCH   = 12'h340;
  localparam MEPC       = 12'h341;
  localparam MCAUSE     = 12'h342;
  //localparam MISA       = 12'h301;

  // MXLEN tanımı
  localparam MXLEN = 32;

  // mstatus kaydı: ilgili alanlar (MIE, MPIE, MPP) tekil olarak tanımlanır.
  typedef struct packed {
    logic       mie;    // MIE: 1 bit (örn. mstatus[3])
    logic       mpie;   // MPIE: 1 bit (örn. mstatus[7])
    logic [1:0] mpp;    // MPP: 2 bit (örn. mstatus[12:11])
  } mstatus_t;

  // mstatus yapısı ile 32-bit CSR değeri arasında pack/unpack dönüşümleri:
  function automatic logic [31:0] pack_mstatus(mstatus_t mstat);
    logic [31:0] data;
    begin
      data = 32'd0;
      data[3]     = mstat.mie;
      data[7]     = mstat.mpie;
      data[12:11] = mstat.mpp;
      pack_mstatus = data;
    end
  endfunction

  function automatic mstatus_t unpack_mstatus(logic [31:0] data);
    mstatus_t ret;
    begin
      ret.mie  = data[3];
      ret.mpie = data[7];
      ret.mpp  = data[12:11];
      unpack_mstatus = ret;
    end
  endfunction

  // CSR kayıtları
  mstatus_t            mstatus;
  logic [XLEN-1:0]     mtvec;
  logic [XLEN-1:0]     mip;
  logic [XLEN-1:0]     mie;      // Ayrı MIE CSR'si
  logic [XLEN-1:0]     mcycle;
  logic [XLEN-1:0]     mcycleh;
  logic [XLEN-1:0]     minstret;
  logic [XLEN-1:0]     minstreth;
  logic [XLEN-1:0]     mscratch; // Yazım hatası düzeltildi (mstratch -> mscratch)
  logic [XLEN-1:0]     mepc;
  logic [XLEN-1:0]     mcause;
  //misa_t               misa;

  // Çıkış sinyallerine bağlı bazı durumların (örn. trap geçiş adresi) çıkışa aktarılması
  always_comb begin
    go_to_trap   = trap_active_i;
    return_trap  = mepc;  // Trap dönüşü için kullanılabilir
    mtvec_o      = mtvec;
    mepc_o       = mepc;
  end

  // CSR'lerin güncellenme mantığı
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      mstatus   <= '{mie: 1'b0, mpie: 1'b0, mpp: 2'd0};
      mtvec     <= '0;
      mip       <= '0;
      mie       <= '0;
      mcycle    <= '0;
      mcycleh   <= '0;
      minstret  <= '0;
      minstreth <= '0;
      mscratch  <= '0;
      mepc      <= '0;
      mcause    <= '0;
      //misa.extensions <= 32'b0 | (1'b1 << 2) | (1'b1 << 8) | (1'b1 << 12);
      //misa.nonimp <= '0;
      //misa.mxl <= 'b1;
    end else begin
      if (trap_active_i) begin
        // Trap girişinde:
        // - Trap öncesi PC (trap_mepc_i) ve trap nedeni (trap_cause_i) saklanır.
        // - mstatus içerisinde MIE alanı eski değeri MPIE'ye aktarılır ve MIE sıfırlanır.
        // - MPP, trap geldiği privilege modunu saklamak amacıyla ayarlanır (örneğin, 2'b11: M-mode).
        mepc         <= trap_mepc_i;
        mcause       <= trap_cause_i;
        mstatus.mpie <= mstatus.mie;  // Eski MIE değeri saklanır
        mstatus.mie  <= 1'b0;          // Kesmeler devre dışı bırakılır
        mstatus.mpp  <= 2'b11;
      end else begin
        if (instr_type_i == mret) begin
          // mret (trap'dan dönüş) esnasında:
          // - mstatus.mie, trap öncesi kesme etkinlik değeri (MPIE) ile geri yüklenir.
          // - MPIE, trap sonrası tekrar aktif olması için 1'e ayarlanır.
          // - MPP, trap sonrası en düşük desteklenen privilege moduna (örneğin U-mode: 2'b00) ayarlanır.
          mstatus.mie  <= mstatus.mpie;
          mstatus.mpie <= 1'b1;
          mstatus.mpp  <= 2'b00;
        end else if (wr_en_i) begin
          case (csr_idx_i)
            // MSTATUS yazma: Gelen 32-bit değeri mstatus yapısına dönüştür.
            MSTATUS:    mstatus   <= unpack_mstatus(csr_wdata_i);
            MTVEC:      mtvec     <= csr_wdata_i;
            MIE_ADDR:   mie       <= csr_wdata_i;
            MIP:        mip       <= csr_wdata_i;
            MCYCLE:     mcycle    <= csr_wdata_i;
            MCYCLEH:    mcycleh   <= csr_wdata_i;
            MINSTRET:   minstret  <= csr_wdata_i;
            MINSTRETH:  minstreth <= csr_wdata_i;
            MSCRATCH:   mscratch  <= csr_wdata_i;
            MEPC:       mepc      <= csr_wdata_i;
            MCAUSE:     mcause    <= csr_wdata_i;
            // MTVAL:   // Uygulanmadı
            default: ; // Tanımlı olmayan CSR adreslerinde işlem yapılmaz.
          endcase
        end
      end
    end
  end

  // CSR okuma mantığı
  always_comb begin
    if (rd_en_i) begin
      case (csr_idx_i)
        // MISA:     csr_rdata_o = misa;
        MSTATUS:    csr_rdata_o = pack_mstatus(mstatus);
        MTVEC:      csr_rdata_o = mtvec;
        MIE_ADDR:   csr_rdata_o = mie;
        MIP:        csr_rdata_o = mip;
        MCYCLE:     csr_rdata_o = mcycle;
        MCYCLEH:    csr_rdata_o = mcycleh;
        MINSTRET:   csr_rdata_o = minstret;
        MINSTRETH:  csr_rdata_o = minstreth;
        MSCRATCH:   csr_rdata_o = mscratch;
        MEPC:       csr_rdata_o = mepc;
        MCAUSE:     csr_rdata_o = mcause;
        // MTVAL:   csr_rdata_o = mtval;
        default:    csr_rdata_o = 32'd0;
      endcase
    end else begin
      csr_rdata_o = 32'd0;
    end
  end

endmodule
