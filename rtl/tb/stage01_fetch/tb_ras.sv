`timescale 1ns/1ps

module tb_ras;
  // Clock ve reset sinyalleri
  logic clk;
  logic rst_ni;

  // RAS modülüne giden sinyaller
  logic        restore_i;
  logic [31:0] restore_pc_i;
  logic        req_valid_i;
  logic        j_type_i;
  logic        jr_type_i;
  logic [4:0]  rd_addr_i;
  logic [4:0]  r1_addr_i;
  logic [31:0] return_addr_i;

  // RAS modülünden çıkan sinyaller
  logic [31:0] popped_addr_o;
  logic        predict_valid_o;

  // UUT (Unit Under Test) örneği
  ras uut (
    .clk_i(clk),
    .rst_ni(rst_ni),
    .restore_i(restore_i),
    .restore_pc_i(restore_pc_i),
    .req_valid_i(req_valid_i),
    .j_type_i(j_type_i),
    .jr_type_i(jr_type_i),
    .rd_addr_i(rd_addr_i),
    .r1_addr_i(r1_addr_i),
    .return_addr_i(return_addr_i),
    .popped_addr_o(popped_addr_o),
    .predict_valid_o(predict_valid_o)
  );

  // Clock üretimi: 10 ns periyot
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Stimulus ve self-checking test senaryoları
  initial begin
    // Başlangıç değerleri
    rst_ni        <= 0;
    restore_i     <= 0;
    restore_pc_i  <= 32'd0;
    req_valid_i   <= 0;
    j_type_i      <= 0;
    jr_type_i     <= 0;
    rd_addr_i     <= 5'd0;
    r1_addr_i     <= 5'd0;
    return_addr_i <= 32'd0;

    // Reset uygulaması
    repeat(2)@(posedge clk);
    rst_ni <= 1;
    repeat(2)@(posedge clk);

    // ------------------------------------------------------
    // Test 1: PUSH İşlemi (j_type_i=1 ve link için rd_addr_i = 1)
    // ------------------------------------------------------
    rd_addr_i    <= 5'd1;      // link kontrolü: 1 veya 5
    r1_addr_i    <= 5'd0;
    j_type_i     <= 1;
    jr_type_i    <= 0;
    req_valid_i  <= 1;
    return_addr_i<= 32'hA000_0000; // Push yapılacak adres
    @(posedge clk);
    req_valid_i <= 0;
    j_type_i    <= 0;
    @(posedge clk);
    #1;
    // PUSH işlemi sırasında predict_valid_o'nun aktif olmaması beklenir.
    if (predict_valid_o !== 0)
      $error("Test 1 Failed: PUSH sırasında predict_valid_o 0 olmalı.");

    // ------------------------------------------------------
    // Test 2: POP İşlemi (jr_type_i=1, link için r1_addr_i = 1)
    // ------------------------------------------------------
    // Önce push yapılan adresin stack'te olduğunu varsayıyoruz.
    rd_addr_i   <= 5'd0;       // rd kullanılmayacak
    r1_addr_i   <= 5'd1;       // link kontrolü: 1 veya 5
    j_type_i    <= 0;
    jr_type_i   <= 1;
    req_valid_i <= 1;
    @(posedge clk);
    req_valid_i <= 0;
    jr_type_i   <= 0;
    @(posedge clk);


    // ------------------------------------------------------
    // Test 3: BOTH İşlemi (jr_type_i=1 ve hem rd hem de r1 link kontrolü aktif)
    // ------------------------------------------------------
    rd_addr_i    <= 5'd1;       // link
    r1_addr_i    <= 5'd5;       // link
    jr_type_i    <= 1;
    req_valid_i  <= 1;
    return_addr_i<= 32'hB000_0000; // Yeni adres

        #1;
    // POP işleminde, daha önce push yapılan adresin (0xA000_0000) pop edilerek çıkması beklenir.
    if (popped_addr_o !== 32'hA000_0000)
      $error("Test 2 Failed: POP işleminde beklenen adres 0xA0000000 değil, gelen: %h", popped_addr_o);

    if (predict_valid_o !== 1)
      $error("Test 2 Failed: POP sırasında predict_valid_o 1 olmalı.");
    @(posedge clk);
    req_valid_i <= 0;
    jr_type_i   <= 0;
    @(posedge clk);

    // BOTH işlemi: Hem pop hem push yapılır; böylece stack'in en üstü yeni değere güncellenir.
    if (popped_addr_o !== 32'hB000_0000)
      $error("Test 3 Failed: BOTH işleminde üst değer 0xB0000000 olmalı, gelen: %h", popped_addr_o);

    if (predict_valid_o !== 1)
      $error("Test 3 Failed: BOTH işleminde predict_valid_o 1 olmalı.");

    // ------------------------------------------------------
    // Test 4: RESTORE İşlemi (restore_i=1)
    // ------------------------------------------------------
    restore_i    <= 1;
    restore_pc_i <= 32'hC000_0000; // Restore adresi
    @(posedge clk);
    restore_i <= 0;
    @(posedge clk);

    // Restore işleminde, stack'in en üstünün restore_pc_i ile güncellenmiş olması beklenir.
    if (popped_addr_o !== 32'hC000_0000)
      $error("Test 4 Failed: RESTORE işleminde beklenen adres 0xC0000000 değil, gelen: %h", popped_addr_o);

    $display("Tüm testler başarıyla geçti.");
    repeat(2)@(posedge clk);
    $finish;
  end

endmodule
