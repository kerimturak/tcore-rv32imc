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
// Design Name:    cpu                                                        //
// Project Name:   TCORE                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    CPU is TOP module of the CORE design                       //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`include "tcore_defines.svh"
module cpu
  import tcore_param::*;
(
    input  logic                 clk_i,
    input  logic                 rst_ni,
    output logic                 iomem_valid,
    input  logic                 iomem_ready,
    output logic [         15:0] iomem_wstrb,
    output logic [     XLEN-1:0] iomem_addr,
    input  logic [BLK_SIZE -1:0] iomem_rdata,
    output logic [BLK_SIZE -1:0] iomem_wdata,
    output logic                 uart_tx_o,
    input  logic                 uart_rx_i
);

  logic                  stall_all;
  ilowX_req_t            lx_ireq;
  dlowX_res_t            lx_dres;
  dlowX_req_t            lx_dreq;
  mem_req_t              mem_req;
  // ------- fetch logic ------
  logic                  fe_stall;
  ilowX_res_t            lx_ires;
  logic                  fe_imiss_stall;
  logic       [XLEN-1:0] fe_pc;
  logic       [XLEN-1:0] fe_pc4;
  logic       [XLEN-1:0] fe_pc2;
  logic       [XLEN-1:0] fe_inst;
  logic                  fe_is_comp;
  // ------- decode logic ------
  pipe1_t                pipe1;
  ctrl_t                 de_ctrl;
  logic                  de_enable;
  logic                  de_stall;
  logic                  de_flush;
  logic                  de_flush_en;
  logic       [XLEN-1:0] de_r1_data;
  logic       [XLEN-1:0] de_r2_data;
  logic                  de_fwd_a;
  logic                  de_fwd_b;
  logic       [XLEN-1:0] de_imm;
  // ------ execute logic ------
  pipe2_t                pipe2;
  logic                  ex_flush;
  logic                  ex_flush_en;
  logic       [     1:0] ex_fwd_a;
  logic       [     1:0] ex_fwd_b;
  logic       [XLEN-1:0] ex_alu_result;
  logic       [XLEN-1:0] ex_pc_target;
  logic       [XLEN-1:0] ex_wdata;
  logic                  ex_pc_sel;
  logic                  ex_alu_stall;
  // ------- memory logic ------
  pipe3_t                pipe3;
  logic                  me_dmiss_stall;
  logic       [XLEN-1:0] me_rdata;
  // ------ writeback logic ----
  pipe4_t                pipe4;
  logic                  wb_rf_rw;
  logic       [XLEN-1:0] wb_data;

  //----------------------------------              fetch             ---------------------------------------------
  stage1_fetch fetch (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .stall_i      (stall_all),
      .fe_stall_i   (fe_stall),
      .pc_sel_i     (ex_pc_sel),
      .lx_ires_i    (lx_ires),
      .pc_target_i  (ex_pc_target),
      .lx_ireq_o    (lx_ireq),
      .pc_o         (fe_pc),
      .pc2_o        (fe_pc2),
      .pc4_o        (fe_pc4),
      .inst_o       (fe_inst),
      .is_comp_o    (fe_is_comp),
      .imiss_stall_o(fe_imiss_stall)
  );

  //----------------------------------              decode             ---------------------------------------------
  always_ff @(posedge clk_i) begin
    if (rst_ni || de_flush_en) begin
      pipe1 <= '{default: 0};
    end else if (de_enable) begin
      pipe1 <= '{pc      : fe_pc, pc4     : fe_pc4, pc2     : fe_pc2, inst    : fe_inst, is_comp : fe_is_comp};
    end
  end

  always_comb begin
    de_enable   = !(stall_all || de_stall);
    de_flush_en = stall_all ? 1'b0 : de_flush;
  end

  stage2_decode decode (
      .clk_i     (clk_i),
      .rst_ni    (rst_ni),
      .fwd_a_i   (de_fwd_a),
      .fwd_b_i   (de_fwd_b),
      .wb_data_i (wb_data),
      .inst_i    (pipe1.inst),
      .rd_addr_i (pipe4.rd_addr),
      .rf_rw_en_i(wb_rf_rw),
      .r1_data_o (de_r1_data),
      .r2_data_o (de_r2_data),
      .ctrl_o    (de_ctrl),
      .imm_o     (de_imm)
  );

  //----------------------------------              execute             ---------------------------------------------
  always_ff @(posedge clk_i) begin
    if (rst_ni || ex_flush_en) begin
      pipe2 <= '{default: 0};
    end else if (!stall_all) begin
      pipe2 <= '{
          pc          : pipe1.pc,
          pc4         : pipe1.pc4,
          pc2         : pipe1.pc2,
          is_comp     : pipe1.is_comp,
          rf_rw_en    : de_ctrl.rf_rw_en,
          wr_en       : de_ctrl.wr_en,
          rw_type     : de_ctrl.rw_type,
          result_src  : de_ctrl.result_src,
          alu_ctrl    : de_ctrl.alu_ctrl,
          pc_sel      : de_ctrl.pc_sel,
          alu_in1_sel : de_ctrl.alu_in1_sel,
          alu_in2_sel : de_ctrl.alu_in2_sel,
          ld_op_size  : de_ctrl.ld_op_size,
          r1_data     : de_r1_data,
          r2_data     : de_r2_data,
          r1_addr     : pipe1.inst.r1_addr,
          r2_addr     : pipe1.inst.r2_addr,
          rd_addr     : pipe1.inst.rd_addr,
          imm         : de_imm
      };
    end
  end

  stage3_execution execution (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .fwd_a_i      (ex_fwd_a),
      .fwd_b_i      (ex_fwd_b),
      .alu_result_i (pipe3.alu_result),
      .wb_data_i    (wb_data),
      .r1_data_i    (pipe2.r1_data),
      .r2_data_i    (pipe2.r2_data),
      .alu_in1_sel_i(pipe2.alu_in1_sel),
      .alu_in2_sel_i(pipe2.alu_in2_sel),
      .is_comp_i    (pipe2.is_comp),
      .pc_i         (pipe2.pc),
      .pc4_i        (pipe2.pc4),
      .pc2_i        (pipe2.pc2),
      .imm_i        (pipe2.imm),
      .pc_sel_i     (pipe2.pc_sel),
      .alu_ctrl_i   (pipe2.alu_ctrl),
      .write_data_o (ex_wdata),
      .pc_target_o  (ex_pc_target),
      .alu_result_o (ex_alu_result),
      .pc_sel_o     (ex_pc_sel),
      .alu_stall_o  (ex_alu_stall)
  );

  assign ex_flush_en = stall_all ? 1'b0 : ex_flush;

  //----------------------------------              memory             ---------------------------------------------
  always_ff @(posedge clk_i) begin
    if (rst_ni) begin
      pipe3 <= '{default: 0};
    end else if (!stall_all) begin
      pipe3 <= '{
          pc4         : pipe2.pc4,
          pc2         : pipe2.pc2,
          is_comp     : pipe2.is_comp,
          rf_rw_en    : pipe2.rf_rw_en,
          wr_en       : pipe2.wr_en,
          rw_type     : pipe2.rw_type,
          result_src  : pipe2.result_src,
          ld_op_size  : pipe2.ld_op_size,
          rd_addr     : pipe2.rd_addr,
          alu_result  : ex_alu_result,
          write_data  : ex_wdata
      };
    end
  end

  stage4_memory memory (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .stall_i      (stall_all),
      .wr_en_i      (pipe3.wr_en),
      .rw_type_i    (pipe3.rw_type),
      .alu_result_i (pipe3.alu_result),
      .write_data_i (pipe3.write_data),
      .lx_dres_i    (lx_dres),
      .ld_op_size_i (pipe3.ld_op_size),
      .lx_dreq_o    (lx_dreq),
      .me_data_o    (me_rdata),
      .dmiss_stall_o(me_dmiss_stall),
      .uart_rx_i    (uart_rx_i),
      .uart_tx_o    (uart_tx_o)
  );

  assign iomem_wdata = lx_dreq.data;

  //----------------------------------              write-back             ---------------------------------------------
  always_ff @(posedge clk_i) begin
    if (rst_ni) begin
      pipe4 <= '{default: 0};
    end else if (!stall_all) begin
      pipe4 <= '{
          pc4         : pipe3.pc4,
          pc2         : pipe3.pc2,
          is_comp     : pipe3.is_comp,
          rf_rw_en    : pipe3.rf_rw_en,
          result_src  : pipe3.result_src,
          rd_addr     : pipe3.rd_addr,
          alu_result  : pipe3.alu_result,
          read_data   : me_rdata
      };
    end
  end

  stage5_writeback writeback (
      .data_sel_i  (pipe4.result_src),
      .pc4_i       (pipe4.pc4),
      .pc2_i       (pipe4.pc2),
      .is_comp_i   (pipe4.is_comp),
      .alu_result_i(pipe4.alu_result),
      .read_data_i (pipe4.read_data),
      .stall_i     (stall_all),
      .rf_rw_en_i  (pipe4.rf_rw_en),
      .rf_rw_en_o  (wb_rf_rw),
      .wb_data_o   (wb_data)
  );

  //----------------------------------              Multiple-Stage         ---------------------------------------------
  hazard_unit hazard_unit (
      .r1_addr_de_i (pipe1.inst.r1_addr),
      .r2_addr_de_i (pipe1.inst.r2_addr),
      .r1_addr_ex_i (pipe2.r1_addr),
      .r2_addr_ex_i (pipe2.r2_addr),
      .rd_addr_ex_i (pipe2.rd_addr),
      .pc_sel_ex_i  (ex_pc_sel),
      .rslt_sel_ex_0(pipe2.result_src[0]),
      .rd_addr_me_i (pipe3.rd_addr),
      .rf_rw_me_i   (pipe3.rf_rw_en),
      .rf_rw_wb_i   (pipe4.rf_rw_en),
      .rd_addr_wb_i (pipe4.rd_addr),
      .stall_fe_o   (fe_stall),
      .stall_de_o   (de_stall),
      .flush_de_o   (de_flush),
      .flush_ex_o   (ex_flush),
      .fwd_a_ex_o   (ex_fwd_a),
      .fwd_b_ex_o   (ex_fwd_b),
      .fwd_a_de_o   (de_fwd_a),
      .fwd_b_de_o   (de_fwd_b)
  );

  memory_arbiter memory_arbiter (
      .clk_i        (clk_i),
      .rst_i        (rst_ni),
      .iomem_rdata_i(iomem_rdata),
      .icache_req_i (lx_ireq),
      .dcache_req_i (lx_dreq),
      .mem_ready_i  (iomem_ready),
      .icache_res_o (lx_ires),
      .dcache_res_o (lx_dres),
      .mem_req_o    (mem_req)
  );

  always_comb begin
    iomem_valid = mem_req.valid;
    iomem_addr  = mem_req.addr;
    iomem_wstrb = mem_req.rw;
    stall_all   = fe_imiss_stall || me_dmiss_stall || ex_alu_stall;
  end

endmodule
