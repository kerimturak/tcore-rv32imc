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

  logic                     stall_all;
  ilowX_req_t               lx_ireq;
  dlowX_res_t               lx_dres;
  dlowX_req_t               lx_dreq;
  mem_req_t                 mem_req;
  // ------- fetch logic ------
  logic                     fe_stall;
  ilowX_res_t               lx_ires;
  logic                     fe_imiss_stall;
  logic          [XLEN-1:0] fe_pc;
  logic          [XLEN-1:0] fe_pc4;
  logic          [XLEN-1:0] fe_pc2;
  logic          [XLEN-1:0] fe_inst;
  logic                     fe_is_comp;
  predict_info_t            fe_spec;
  exc_type_e                fe_exc_type;
  instr_type_e              fe_instr_type;
  // ------- decode logic ------
  pipe1_t                   pipe1;
  ctrl_t                    de_ctrl;
  logic                     de_enable;
  logic                     de_stall;
  logic                     de_flush;
  logic                     de_flush_en;
  logic          [XLEN-1:0] de_r1_data;
  logic          [XLEN-1:0] de_r2_data;
  logic                     de_fwd_a;
  logic                     de_fwd_b;
  logic          [XLEN-1:0] de_imm;
  predict_info_t            de_spec;
  exc_type_e                de_exc_type;

  // ------ execute logic ------
  pipe2_t                   pipe2;
  logic                     ex_flush;
  logic                     ex_flush_en;
  logic          [     1:0] ex_fwd_a;
  logic          [     1:0] ex_fwd_b;
  logic          [XLEN-1:0] ex_alu_result;
  logic          [XLEN-1:0] ex_pc_target;
  logic          [XLEN-1:0] ex_pc_target_last;
  logic          [XLEN-1:0] ex_wdata;
  logic                     ex_pc_sel;
  logic                     ex_alu_stall;
  predict_info_t            ex_spec;
  logic                     ex_spec_hit;
  exc_type_e                ex_exc_type;
  exc_type_e                alu_exc_type;
  logic                     ex_rd_csr;
  logic                     ex_wr_csr;
  logic     [XLEN-1:0]      ex_mtvec;
  // ------- memory logic ------
  pipe3_t                   pipe3;
  logic                     me_dmiss_stall;
  logic          [XLEN-1:0] me_rdata;
  // ------ writeback logic ----
  pipe4_t                   pipe4;
  logic                     wb_rf_rw;
  logic          [XLEN-1:0] wb_pc;
  logic          [XLEN-1:0] wb_data;

  logic            wb_trap_active;
  logic [XLEN-1:0] wb_trap_cause;
  logic [XLEN-1:0] wb_trap_mepc;
  //----------------------------------              fetch             ---------------------------------------------
  logic [4:0] exc_array;
  logic  priority_flush;

  stage1_fetch fetch (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .stall_i      (stall_all),
      .fe_stall_i   (fe_stall),
      .lx_ires_i    (lx_ires),
      .pc_target_i  (ex_pc_target_last),
      .spec_hit_i   (ex_spec_hit),
      .wb_pc_i      (wb_pc),
      .exc_array_i  (exc_array),
      .spec_o       (fe_spec),
      .lx_ireq_o    (lx_ireq),
      .pc_o         (fe_pc),
      .pc2_o        (fe_pc2),
      .pc4_o        (fe_pc4),
      .inst_o       (fe_inst),
      .is_comp_o    (fe_is_comp),
      .imiss_stall_o(fe_imiss_stall),
      .exc_type_o   (fe_exc_type),
      .instr_type_o (fe_instr_type)
  );

  //----------------------------------              decode             ---------------------------------------------
  always_ff @(posedge clk_i) begin
    if (!rst_ni || de_flush_en) begin
      pipe1   <= '{exc_type_e: NO_EXCEPTION, instr_type: instr_invalid, default: 0};
      de_spec <= '0;
    end else if (de_enable) begin
      pipe1   <= '{pc      : fe_pc, pc4     : fe_pc4, pc2     : fe_pc2, inst    : fe_inst, is_comp : fe_is_comp, exc_type: fe_exc_type, instr_type : fe_instr_type};
      de_spec <= fe_spec;
    end
  end

  always_comb begin
    de_enable   = !(stall_all || de_stall);
    de_flush_en = priority_flush ? 1'b0 : stall_all ? 1'b0 : de_flush;
  end

  stage2_decode decode (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .fwd_a_i      (de_fwd_a),
      .fwd_b_i      (de_fwd_b),
      .wb_data_i    (wb_data),
      .inst_i       (pipe1.inst),
      .instr_type_i (pipe1.instr_type),
      .exc_type_i   (pipe1.exc_type),
      .rd_addr_i    (pipe4.rd_addr),
      .rf_rw_en_i   (wb_rf_rw),
      .r1_data_o    (de_r1_data),
      .r2_data_o    (de_r2_data),
      .ctrl_o       (de_ctrl),
      .imm_o        (de_imm),
      .exc_type_o   (de_exc_type)
  );

  //----------------------------------              execute             ---------------------------------------------
  always_ff @(posedge clk_i) begin
    if (!rst_ni || ex_flush_en) begin
      pipe2   <= '{exc_type_e: NO_EXCEPTION, default: 0, alu_ctrl: OP_ADD, pc_sel: NO_BJ, rw_size: NO_SIZE};
      ex_spec <= '0;
    end else if (!stall_all) begin
      ex_spec <= de_spec;
      pipe2 <= '{
          pc          : pipe1.pc,
          pc4         : pipe1.pc4,
          pc2         : pipe1.pc2,
          is_comp     : pipe1.is_comp,
          rf_rw_en    : de_ctrl.rf_rw_en,
          wr_en       : de_ctrl.wr_en,
          rw_size     : de_ctrl.rw_size,
          result_src  : de_ctrl.result_src,
          alu_ctrl    : de_ctrl.alu_ctrl,
          pc_sel      : de_ctrl.pc_sel,
          alu_in1_sel : de_ctrl.alu_in1_sel,
          alu_in2_sel : de_ctrl.alu_in2_sel,
          ld_op_sign  : de_ctrl.ld_op_sign,
          rd_csr      : de_ctrl.rd_csr,
          wr_csr      : de_ctrl.wr_csr,
          csr_idx     : de_ctrl.csr_idx,
          csr_or_data : de_ctrl.csr_or_data,
          r1_data     : de_r1_data,
          r2_data     : de_r2_data,
          r1_addr     : pipe1.inst.r1_addr,
          r2_addr     : pipe1.inst.r2_addr,
          rd_addr     : pipe1.inst.rd_addr,
          imm         : de_imm,
          exc_type    : de_exc_type
      };
    end
  end

  always_comb begin
    ex_flush_en = priority_flush ? 1'b0 : stall_all ? 1'b0 : ex_flush;
      if (alu_exc_type != NO_EXCEPTION) begin
        ex_exc_type = alu_exc_type;
      end else if (de_ctrl.rw_size != NO_SIZE) begin
        if (de_ctrl.wr_en) begin
          unique case (de_ctrl.rw_size)
            HALF_WORD: ex_exc_type = ex_alu_result[1] ? STORE_MISALIGNED : NO_EXCEPTION;
            WORD:      ex_exc_type = ex_alu_result[1] | ex_alu_result[0] ? STORE_MISALIGNED : NO_EXCEPTION;
            default:   ex_exc_type = NO_EXCEPTION;
          endcase
        end else begin
          unique case (de_ctrl.rw_size)
            HALF_WORD: ex_exc_type = ex_alu_result[1] ? LOAD_MISALIGNED : NO_EXCEPTION;
            WORD:      ex_exc_type = ex_alu_result[1] | ex_alu_result[0] ? LOAD_MISALIGNED : NO_EXCEPTION;
            default:   ex_exc_type = NO_EXCEPTION;
          endcase
        end
      end else begin
        ex_exc_type = NO_EXCEPTION;
      end
      ex_rd_csr = pipe2.rd_csr & !stall_all;
      ex_wr_csr = pipe2.wr_csr & !stall_all;
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


      .trap_active_i(wb_trap_active),
      .trap_cause_i (wb_trap_cause),
      .trap_mepc_i  (wb_trap_mepc),

      .rd_csr_i     (ex_rd_csr),
      .wr_csr_i     (ex_wr_csr),
      .csr_idx_i    (pipe2.csr_idx),

      .is_comp_i    (pipe2.is_comp),
      .csr_or_data_i(pipe2.csr_or_data),
      .pc_i         (pipe2.pc),
      .pc4_i        (pipe2.pc4),
      .pc2_i        (pipe2.pc2),
      .imm_i        (pipe2.imm),
      .pc_sel_i     (pipe2.pc_sel),
      .alu_ctrl_i   (pipe2.alu_ctrl),
      .exc_type_i   (pipe2.exc_type),
      .write_data_o (ex_wdata),
      .pc_target_o  (ex_pc_target),
      .alu_result_o (ex_alu_result),
      .pc_sel_o     (ex_pc_sel),
      .alu_stall_o  (ex_alu_stall),
      .exc_type_o   (alu_exc_type),
      .mtvec_o      (ex_mtvec)
  );

  always_comb begin
    if (ex_pc_sel) ex_spec_hit = ex_spec.taken && (ex_pc_target == ex_spec.pc);
    else ex_spec_hit = !ex_spec.taken;

    if (!ex_spec_hit) begin
      if (ex_pc_sel) ex_pc_target_last = ex_pc_target;
      else ex_pc_target_last = pipe2.is_comp ? pipe2.pc2 : pipe2.pc4;
    end else begin
      ex_pc_target_last = ex_pc_target;
    end
  end

  //----------------------------------              memory             ---------------------------------------------
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      pipe3 <= '{exc_type_e: NO_EXCEPTION, default: 0, rw_size: NO_SIZE};
    end else if (!stall_all) begin
      pipe3 <= '{
          pc4         : pipe2.pc4,
          pc2         : pipe2.pc2,
          pc          : pipe2.pc,
          is_comp     : pipe2.is_comp,
          rf_rw_en    : pipe2.rf_rw_en,
          wr_en       : pipe2.wr_en,
          rw_size     : pipe2.rw_size,
          result_src  : pipe2.result_src,
          ld_op_sign  : pipe2.ld_op_sign,
          rd_addr     : pipe2.rd_addr,
          alu_result  : ex_alu_result,
          write_data  : ex_wdata,
          exc_type    : ex_exc_type,
          mtvec       : ex_mtvec
      };
    end
  end

  stage4_memory memory (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .stall_i      (stall_all),
      .wr_en_i      (pipe3.wr_en),
      .rw_size_i    (pipe3.rw_size),
      .alu_result_i (pipe3.alu_result),
      .write_data_i (pipe3.write_data),
      .lx_dres_i    (lx_dres),
      .ld_op_sign_i (pipe3.ld_op_sign),
      .lx_dreq_o    (lx_dreq),
      .me_data_o    (me_rdata),
      .dmiss_stall_o(me_dmiss_stall),
      .uart_rx_i    (uart_rx_i),
      .uart_tx_o    (uart_tx_o)
  );

  //----------------------------------              write-back             ---------------------------------------------
`ifndef REMOVE_WB_STAGE
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      pipe4 <= '{exc_type_e: NO_EXCEPTION, default: 0};
    end else if (!stall_all) begin
      pipe4 <= '{
          pc4         : pipe3.pc4,
          pc2         : pipe3.pc2,
          pc          : pipe3.pc,
          is_comp     : pipe3.is_comp,
          rf_rw_en    : pipe3.rf_rw_en,
          result_src  : pipe3.result_src,
          rd_addr     : pipe3.rd_addr,
          alu_result  : pipe3.alu_result,
          read_data   : me_rdata,
          exc_type    : pipe3.exc_type,
          mtvec       : ex_mtvec
      };
    end
  end
`else
  always_comb begin
    pipe4 = '{
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
`endif

  stage5_writeback writeback (
      .data_sel_i    (pipe4.result_src),
      .pc4_i         (pipe4.pc4),
      .pc2_i         (pipe4.pc2),
      .pc_i          (pipe4.pc),
      .is_comp_i     (pipe4.is_comp),
      .alu_result_i  (pipe4.alu_result),
      .read_data_i   (pipe4.read_data),
      .stall_i       (stall_all),
      .mtvec_i       (pipe4.mtvec),
      .rf_rw_en_i    (pipe4.rf_rw_en),
      .rf_rw_en_o    (wb_rf_rw),
      .wb_pc_o       (wb_pc),
      .wb_data_o     (wb_data),
      .exc_type_i    (pipe4.exc_type),
      .trap_cause_o  (wb_trap_cause),
      .trap_active_o (wb_trap_active),
      .trap_mepc_o   (wb_trap_mepc)
  );

  //----------------------------------              Multiple-Stage         ---------------------------------------------
  hazard_unit hazard_unit (
      .r1_addr_de_i (pipe1.inst.r1_addr),
      .r2_addr_de_i (pipe1.inst.r2_addr),
      .r1_addr_ex_i (pipe2.r1_addr),
      .r2_addr_ex_i (pipe2.r2_addr),
      .rd_addr_ex_i (pipe2.rd_addr),
      .pc_sel_ex_i  (!ex_spec_hit),
      .rslt_sel_ex_0(pipe2.result_src[0]),
      .rd_addr_me_i (pipe3.rd_addr),
      .rf_rw_me_i   (pipe3.rf_rw_en),
      .rf_rw_wb_i   (pipe4.rf_rw_en),
      .rd_addr_wb_i (pipe4.rd_addr),
      //.exc_array_i  (exc_array),
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
      .rst_ni       (rst_ni),
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
    iomem_wdata = mem_req.data;
    stall_all   = fe_imiss_stall || me_dmiss_stall || ex_alu_stall;
    exc_array = '0;
    exc_array = {pipe4.exc_type != NO_EXCEPTION, pipe3.exc_type!= NO_EXCEPTION, pipe2.exc_type!= NO_EXCEPTION, pipe1.exc_type!= NO_EXCEPTION, fe_exc_type!= NO_EXCEPTION};

    priority_flush = '0;

    if (|exc_array[3:0]) begin // memory exception
      priority_flush = '1;
    end 
  end

endmodule
