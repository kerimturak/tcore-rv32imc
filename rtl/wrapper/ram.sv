//////////////////////////////////////////////////////////////////////////////////
// Company: TUBITAK TUTEL
// Engineer:
//
// Create Date: 27.04.2022 10:41:19
// Design Name: TEKNOFEST
// Module Name: wrapper_ram
// Project Name: TEKNOFEST
// Target Devices: Nexys A7
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
module wrapper_ram #(
    parameter NB_COL    = 4,
    parameter COL_WIDTH = 8,
    parameter RAM_DEPTH = 131072,
    parameter INIT_FILE = ""
) (
    input logic clk_i,
    input logic rst_ni,

    input  logic [$clog2(RAM_DEPTH)  -1:0] wr_addr,
    input  logic [$clog2(RAM_DEPTH)  -1:0] rd_addr,
    input  logic [(NB_COL*COL_WIDTH) -1:0] wr_data,
    input  logic [ NB_COL            -1:0] wr_strb,
    output logic [(NB_COL*COL_WIDTH) -1:0] rd_data,

    input  logic rd_en,
    input  logic ram_prog_rx_i,
    output logic system_reset_o,
    output logic prog_mode_led_o
);

  localparam CPU_CLK = 50_000_000;  //Default CPU frequency on FPGA
  localparam BAUD_RATE = 115200;  //Default Baud rate for programming on the run via UART

  logic [(NB_COL*COL_WIDTH) -1:0] ram                 [RAM_DEPTH-1:0];
  logic [(NB_COL*COL_WIDTH) -1:0] ram_prog_data;
  logic                           ram_prog_data_valid;
  logic [ $clog2(RAM_DEPTH) -1:0] prog_addr;
  logic [ $clog2(RAM_DEPTH) -1:0] wr_addr_ram;
  logic [(NB_COL*COL_WIDTH) -1:0] wr_data_ram;

  assign wr_addr_ram = (prog_mode_led_o && ram_prog_data_valid) ? prog_addr : wr_addr;
  assign wr_data_ram = (prog_mode_led_o && ram_prog_data_valid) ? ram_prog_data : wr_data;

  if (INIT_FILE != "") begin : use_init_file
    initial $readmemh(INIT_FILE, ram, 0, RAM_DEPTH - 1);
  end else begin : init_bram_to_zero
    initial ram = '{default: '0};
  end

  always_ff @(posedge clk_i) begin
    if (rd_en) rd_data <= ram[rd_addr];
  end

  // yeniden programlanırken önceki program boyutu yenisinden küçükse önceki programın kalıntıları sonda kalabilir
  // onları 0'a yani nop instructionına çekiyoruz
  // logic reset_ram;

  for (genvar i = 0; i < NB_COL; i = i + 1) begin : byte_write
    always @(posedge clk_i) if (wr_strb[i] || (prog_mode_led_o && ram_prog_data_valid)) ram[wr_addr_ram][i*COL_WIDTH+:COL_WIDTH] <= wr_data_ram[i*COL_WIDTH+:COL_WIDTH];
  end

  always_ff @(posedge clk_i) begin
    if (!(rst_ni && system_reset_o)) begin
      prog_addr <= 'h0;
    end else begin
      if (prog_mode_led_o && ram_prog_data_valid) begin
        prog_addr <= prog_addr + 1'b1;
      end
    end
  end

  localparam PROGRAM_SEQUENCE = "TCORETEST";
  localparam PROG_SEQ_LENGTH = 9;
  localparam SEQ_BREAK_THRESHOLD = 32'd1000000;

  logic [PROG_SEQ_LENGTH*8-1:0] received_sequence;
  logic [                  3:0] rcv_seq_ctr;  // $clog2(length(PROGRAM_SEQUENCE))-1

  logic [                 31:0] sequence_break_ctr;
  logic                         sequence_break;
  logic [                 31:0] prog_uart_do;

  typedef enum logic [2:0] {
    SequenceWait       = 3'b000,
    SequenceReceive    = 3'b001,
    SequenceCheck      = 3'b011,
    SequenceLengthCalc = 3'b010,
    SequenceProgram    = 3'b110,
    SequenceFinish     = 3'b100
  } fsm_t;

  fsm_t                                    state_prog;
  fsm_t                                    state_prog_next;

  //always_ff@ (posedge clk_i) begin
  //  if (state_prog == SequenceLengthCalc) reset_ram <= 1;
  //  else                                  reset_ram <= 0;
  //end

  logic [$clog2((NB_COL*COL_WIDTH)/8)-1:0] instruction_byte_ctr;  // for word
  logic [          (NB_COL*COL_WIDTH)-1:0] prog_instruction;
  logic [                            31:0] prog_intr_number;  // expected program length
  logic [                            31:0] prog_intr_ctr;  // counted program which is received

  logic                                    prog_inst_valid;
  logic                                    prog_sys_rst_n;
  logic                                    ram_prog_rd_en;


  for (genvar j = 0; j < (NB_COL * COL_WIDTH); j = j + 32) begin : reorder_word
    assign ram_prog_data[j+:32] = prog_instruction[127-j-:32];
  end

  //assign ram_prog_data       = {prog_instruction[31:0], prog_instruction[63:32], prog_instruction[95:64], prog_instruction[127:96]};
  assign ram_prog_data_valid = prog_inst_valid;
  assign system_reset_o      = prog_sys_rst_n;
  assign ram_prog_rd_en      = (state_prog != SequenceFinish);
  assign prog_mode_led_o     = (state_prog == SequenceProgram);
  assign sequence_break      = sequence_break_ctr == SEQ_BREAK_THRESHOLD;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) state_prog <= SequenceWait;
    else state_prog <= state_prog_next;
  end

  always_comb begin
    state_prog_next = state_prog;
    case (state_prog)

      SequenceWait: begin
        if (prog_uart_do != '1) begin  // gönderilen pattern full 1 olmayınca çalışmaya başla
          state_prog_next = SequenceReceive;
        end
      end

      SequenceReceive: begin  // gönderilen patter hala 1 değil ise alınan sequence counter limite ulaşmış mı bak
        if (prog_uart_do != '1) begin  // ulaşmışsa gelen sequence programlama sequence'imize eşitmi ona bakmak için sonraki state'e geç
          if (rcv_seq_ctr == PROG_SEQ_LENGTH - 1) begin
            state_prog_next = SequenceCheck;
          end
        end else if (sequence_break) begin  // uzun süre beklendiyse sequence gelmemiştir başlangıca dön takılı kalma burada
          state_prog_next = SequenceWait;
        end
      end

      SequenceCheck: begin
        if (received_sequence == PROGRAM_SEQUENCE) begin
          state_prog_next = SequenceLengthCalc;
        end else begin
          state_prog_next = SequenceWait;
        end
      end

      SequenceLengthCalc: begin  // şimdi programlamaya başlama kodu alındı birde bu aşamada gelecek programın uzunluğu alınıyor
        if ((prog_uart_do != '1) && &instruction_byte_ctr[1:0]) begin
          state_prog_next = SequenceProgram;
        end
      end

      SequenceProgram: begin
        if (prog_intr_ctr == prog_intr_number & ~&instruction_byte_ctr) begin
          state_prog_next = SequenceFinish;
        end
      end

      SequenceFinish: begin
        state_prog_next = SequenceWait;
      end

      default: begin
      end

    endcase
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      instruction_byte_ctr <= '0;
      prog_instruction     <= '0;
      prog_intr_number     <= '0;
      prog_intr_ctr        <= '0;
      sequence_break_ctr   <= '0;
      received_sequence    <= '0;
      rcv_seq_ctr          <= '0;
      prog_inst_valid      <= '0;
      prog_sys_rst_n       <= '1;
    end else begin
      case (state_prog)
        SequenceWait: begin
          instruction_byte_ctr <= '0;
          prog_instruction     <= '0;
          prog_intr_number     <= '0;
          prog_intr_ctr        <= '0;
          sequence_break_ctr   <= '0;
          received_sequence    <= '0;
          rcv_seq_ctr          <= '0;
          prog_inst_valid      <= '0;
          prog_sys_rst_n       <= '1;

          if (prog_uart_do != '1) begin  // sequence gelmeye başladı counterı 1 arttır sonraki state e geç ve datayı kaydet ilk byte olarak
            rcv_seq_ctr <= rcv_seq_ctr + 4'h1;  // ilj harf alındı "T"
            received_sequence <= {received_sequence[PROG_SEQ_LENGTH*8-9:0], prog_uart_do[7:0]};
          end
        end

        SequenceReceive: begin  // geriye kalan harfleri bu state te bekliyoruz
          if (prog_uart_do != '1) begin
            received_sequence <= {received_sequence[PROG_SEQ_LENGTH*8-9:0], prog_uart_do[7:0]};
            if (rcv_seq_ctr == PROG_SEQ_LENGTH - 1) begin
              rcv_seq_ctr <= 4'h0;
            end else begin
              rcv_seq_ctr <= rcv_seq_ctr + 4'h1;
            end
          end else begin  // sequence tetiklenmiş ve belli süre içerisinde gelmemişse program takılmasın diye başa dönmesini söylüyoruz
            if (sequence_break) begin
              sequence_break_ctr <= 32'h0;
              rcv_seq_ctr        <= 4'h0;
            end else begin
              sequence_break_ctr <= sequence_break_ctr + 32'h1;
            end
          end
        end

        SequenceCheck: begin  // TEKNOFEST SEQUENCE'i geldi counterı sıfırla ki ilerde byle'ları sayalım
          instruction_byte_ctr <= 4'b0;
        end

        SequenceLengthCalc: begin
          prog_intr_ctr <= 32'h0;
          if (prog_uart_do != '1) begin
            prog_intr_number <= {prog_intr_number[3*8-1:0], prog_uart_do[7:0]};
            if (&instruction_byte_ctr[1:0]) begin  // instruction_byte_ctr[1:0] burada 4 bytlık bir program boyutu verisi alacağız
              instruction_byte_ctr <= 4'b0;
            end else begin
              instruction_byte_ctr <= instruction_byte_ctr + 4'b1;
            end
          end
        end

        SequenceProgram: begin
          if (prog_uart_do != '1) begin
            prog_instruction <= {prog_instruction[(NB_COL*COL_WIDTH-8)-1:0], prog_uart_do[7:0]};  // // veri bit genişliği eksi 1 byte ve eksi 1
            if (&instruction_byte_ctr) begin
              instruction_byte_ctr <= 4'b0;
              prog_inst_valid      <= 1'b1;
            end else begin
              instruction_byte_ctr <= instruction_byte_ctr + 4'b1;
              prog_inst_valid      <= 1'b0;
            end
            if (&instruction_byte_ctr[1:0]) begin
              prog_intr_ctr <= prog_intr_ctr + 32'h1;
            end
          end else begin
            prog_inst_valid <= 1'b0;
          end
        end

        SequenceFinish: begin
          prog_sys_rst_n <= 1'b0;
        end

        default: begin
        end

      endcase
    end
  end

  simpleuart #(
      .DEFAULT_DIV(CPU_CLK / BAUD_RATE)
  ) simpleuart (
      .clk       (clk_i),
      .resetn    (rst_ni),
      .ser_tx    (),
      .ser_rx    (ram_prog_rx_i),
      .reg_div_we(4'h0),
      .reg_div_di(32'h0),
      .reg_div_do(),
      .reg_dat_we(1'b0),
      .reg_dat_re(ram_prog_rd_en),
      .reg_dat_di(32'h0),
      .reg_dat_do(prog_uart_do)
  );

endmodule
