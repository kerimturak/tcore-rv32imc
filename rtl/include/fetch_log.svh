integer log_file;

// Log dosyasını aç
initial begin
  log_file = $fopen("fetch_log.txt", "w");
  if (log_file == 0) begin
    $display("ERROR: Log file could not be opened!");
    $finish;
  end
end

// Fetch edilen instruction’ları kaydet
always @(posedge clk_i) begin
  if (!rst_ni) begin
    $fclose(log_file);
    log_file = $fopen("fetch_log.txt", "w");
  end else if (!stall_i && buff_res.valid) begin
    if (is_comp_o) begin
      $fwrite(log_file, "%0h:    %h\n", pc_o, buff_res.blk[15:0]);  // Sadece PC yazılıyor
    end else begin
      $fwrite(log_file, "%0h:    %h\n", pc_o, buff_res.blk);  // Sadece PC yazılıyor
    end
  end
end

// Simülasyon bittiğinde dosyayı kapat
final begin
  $fclose(log_file);
end
