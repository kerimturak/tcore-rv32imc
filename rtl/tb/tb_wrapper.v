`timescale 1ns / 1ps
module tb_wrapper;
  reg  clk_i = 0;
  reg  rst_ni = 0;
  reg  program_rx_i = 1;
  reg  uart_rx_i = 1;
  wire prog_mode_led_o;
  wire uart_tx_o;

  teknofest_wrapper teknofest_wrapper (
      .clk_i          (clk_i),
      .rst_ni         (rst_ni),
      .program_rx_i   (program_rx_i),
      .prog_mode_led_o(prog_mode_led_o),
      .uart_tx_o      (uart_tx_o),
      .uart_rx_i      (uart_rx_i)
  );

  initial begin
    rst_ni       <= 0;
    program_rx_i <= 1;
    uart_rx_i    <= 1;
    repeat (2) @(posedge clk_i);
    rst_ni <= 1;
  end

  always #5 clk_i = !clk_i;


endmodule
