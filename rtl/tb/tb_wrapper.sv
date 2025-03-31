`timescale 1ns / 1ps
import tcore_param::*;
module tb_wrapper;
  logic               clk_i = 0;
  logic               rst_ni = 0;
  logic       [127:0] ram        [2048-1:0];
  logic               uart_tx_o;
  logic               uart_rx_i;
  iomem_req_t         iomem_req;
  iomem_res_t         iomem_res;
  logic [$clog2(2048)-1:0] idx;

  assign idx = iomem_req.addr[$clog2(2048)+4-1:4];
  initial $readmemh("coremark_baremetal_static.mem", ram, 0, 2048);

  cpu soc (
      .clk_i      (clk_i),
      .rst_ni     (rst_ni),
      .iomem_req_o(iomem_req),
      .iomem_res_i(iomem_res),
      .uart_tx_o  (uart_tx_o),
      .uart_rx_i  (uart_rx_i)
  );

  logic [3:0] count;
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      iomem_res.valid <= '0;
      iomem_res.ready <= '1;
      iomem_res.data  <= '0;
      count <= '0;
    end else begin
      if (iomem_req.valid) begin
        if (|iomem_req.rw) begin
          // Write işlemi: 16 byte'lık kelime için rw_en sinyali aktif olan byte'ları güncelle.
          integer i;
          // Öncelikle mevcut kelimeyi oku ve sonra güncelle
          count <= (count == 15) ? 0 : count + 1;
          iomem_res.valid <= (count == 15);
          for (i = 0; i < 15; i = i + 1) begin
            if (iomem_req.rw[i])
              ram[idx][8*i +: 8] <= iomem_req.data[8*i +: 8];
          end
        end else begin
          count <= (count == 15) ? 0 : count + 1;
          iomem_res.valid <= (count == 15);
          iomem_res.data  <= ram[idx];
        end
      end else begin
        iomem_res.valid <= '0;
      end
    end
  end

  initial begin
    rst_ni    <= 0;
    uart_rx_i <= 1;
    #10;
    rst_ni <= 1;
  end

  always #5 clk_i = !clk_i;
endmodule
