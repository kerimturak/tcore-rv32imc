.globl _start

_start:
    li t0, 0              # t0'ı 0 olarak ayarla (döngü sayacı)
    li t1, 10             # t1'i 10 olarak ayarla (toplam döngü sayısı)

loop:
    # Register'ları başlat
    li t2, 100            # t2'yi 100 olarak ayarla
    li t3, 100            # t3'ü 100 olarak ayarla

    # Karşılaştır
    beq t2, t3, skip_10  # Eğer t2 ve t3 eşitse, skip_10 etiketine atla

    # Eşit değilse, buraya gelir
    j next                # next etiketine atla (10 talimatı atlamak için)

skip_10:
    # Burada 10 talimat atlanacak (skip_10 etiketinden)
    li t4, 200            # t4'ü 200 olarak ayarla (1. talimat)
    li t5, 200            # t5'i 200 olarak ayarla (2. talimat)
    add t6, t4, t5       # t4 ve t5'i topla (3. talimat)
    sub t6, t6, t4       # t6'dan t4'ü çıkar (4. talimat)
    mul t6, t6, t5       # t6'yı t5 ile çarp (5. talimat)
    div t6, t6, t4       # t6'yı t4 ile böl (6. talimat)
    rem t6, t6, t5       # t6'nın t5 ile kalanı (7. talimat)
    and t6, t6, t4       # t6 ve t4'ü AND (8. talimat)
    or t6, t6, t5        # t6 ve t5'i OR (9. talimat)
    xor t6, t6, t4       # t6 ve t4'ü XOR (10. talimat)

next:
    # Döngü sayacını artır
    addi t0, t0, 1       # t0'ı 1 artır
    blt t0, t1, loop     # Eğer t0 < t1 ise, loop etiketine geri dön

    # Döngü tamamlandıktan sonra programı bitir
    nop                  # Program sonu (buraya asla ulaşılmayacak)
