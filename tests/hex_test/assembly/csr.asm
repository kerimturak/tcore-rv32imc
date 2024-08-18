    # 1'den 31'e kadar değerleri sırasıyla x1 - x31 registerlarına yaz
    li x1, 1
    li x2, 2
    li x3, 3
    li x4, 4
    li x5, 5
    li x6, 6
    li x7, 7
    li x8, 8
    li x9, 9
    li x10, 10
    li x11, 11
    li x12, 12
    li x13, 13
    li x14, 14
    li x15, 15
    li x16, 16
    li x17, 17
    li x18, 18
    li x19, 19
    li x20, 20
    li x21, 21
    li x22, 22
    li x23, 23
    li x24, 24
    li x25, 25
    li x26, 26
    li x27, 27
    li x28, 28
    li x29, 29
    li x30, 30
    li x31, 31

    # CSRRW işlemi
    csrrw x1, 0x300, x1  # mstatus CSR ile x1'in değerini değiştir

    # CSRRS işlemi (CSR Read and Set Bits)
    csrrs x2, 0x300, x2  # x2 içindeki bitleri mstatus'a set et ve mstatus'taki önceki değeri x2'ye yükle

    # CSRRC işlemi (CSR Read and Clear Bits)
    csrrc x3, 0x300, x3  # x3 içindeki bitleri mstatus'tan temizle ve mstatus'taki önceki değeri x3'e yükle

    # CSRRWI işlemi (Immediate versiyon, RS1 yerine immediate)
    csrrwi x2, 0x300, x2  # mstatus'a 5 değerini yaz ve önceki değeri x4'e yükle

    # CSRRSI işlemi (Immediate versiyon, CSR'ye immediate değer set et)
    csrrsi x5, 0x300, x5  # mstatus'un 2 numaralı bitini set et ve önceki değeri x5'e yükle

    # CSRRCI işlemi (Immediate versiyon, CSR'den immediate değer clear et)
    csrrci x6, 0x300, x6  # mstatus'un 1 numaralı bitini temizle ve önceki değeri x6'ya yükle

    # Sonlandırma
    li a7, 93           # Ecall numarası (exit)
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
