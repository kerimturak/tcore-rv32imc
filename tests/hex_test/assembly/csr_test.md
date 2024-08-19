Bu testte, her bir CSR işleminin beklenen sonuçlarını anlamak, testin doğruluğunu değerlendirmekte önemli rol oynar. Aşağıda her bir CSR komutunun sonucu ve bu sonuçları nasıl doğrulayabileceğiniz hakkında bilgi bulabilirsiniz.

### 1. **CSRRW (Control and Status Register Read/Write)**
   ```assembly
   csrrw x1, 0x300, x1
   ```
   - **Açıklama:** `x1`'in değeri `mstatus` CSR'ye yazılır, ve eski `mstatus` değeri `x1`'e yüklenir.
   - **Beklenen Sonuç:** Eğer `mstatus`'un başlangıç değeri `0x0` ise (varsayım olarak), `x1`'e bu değer yazılacak ve `mstatus` CSR `x1`'in başlangıç değeri olan `1` ile güncellenecek.

### 2. **CSRRS (Control and Status Register Read and Set Bits)**
   ```assembly
   csrrs x2, 0x300, x2
   ```
   - **Açıklama:** `x2`'nin değerindeki bitler `mstatus` CSR'de set edilir (bitwise OR işlemi). Eski `mstatus` değeri `x2`'ye yüklenir.
   - **Beklenen Sonuç:** `mstatus`'un güncel değeri `1` olduğundan, `x2`'nin başlangıç değeri olan `2` ile OR'lanır. Bu durumda `mstatus` yeni değeri `3` (1 | 2) olur, ve `x2`'ye önceki `mstatus` değeri olan `1` yazılır.

### 3. **CSRRC (Control and Status Register Read and Clear Bits)**
   ```assembly
   csrrc x3, 0x300, x3
   ```
   - **Açıklama:** `x3`'ün değerindeki bitler `mstatus` CSR'den temizlenir (bitwise AND NOT işlemi). Eski `mstatus` değeri `x3`'e yüklenir.
   - **Beklenen Sonuç:** `mstatus`'un güncel değeri `3` olduğundan, `x3`'ün değeri `3` ile AND NOT yapılır (`3 & ~3 = 0`). Sonuç olarak `mstatus` `0` olur ve `x3`'e önceki `mstatus` değeri olan `3` yazılır.

### 4. **CSRRWI (Control and Status Register Read/Write Immediate)**
   ```assembly
   csrrwi x4, 0x300, 5
   ```
   - **Açıklama:** `5` değeri `mstatus` CSR'ye yazılır, ve eski `mstatus` değeri `x4`'e yüklenir.
   - **Beklenen Sonuç:** `mstatus`'un güncel değeri `0` olduğundan, `mstatus` `5` olarak güncellenir ve `x4`'e önceki `mstatus` değeri olan `0` yazılır.

### 5. **CSRRSI (Control and Status Register Read and Set Immediate)**
   ```assembly
   csrrsi x5, 0x300, 2
   ```
   - **Açıklama:** Immediate değer `2`, `mstatus` CSR'de set edilir. Eski `mstatus` değeri `x5`'e yüklenir.
   - **Beklenen Sonuç:** `mstatus`'un güncel değeri `5` olduğundan, `2` ile OR'lanır (`5 | 2 = 7`). `mstatus` yeni değeri `7` olur ve `x5`'e önceki `mstatus` değeri olan `5` yazılır.

### 6. **CSRRCI (Control and Status Register Read and Clear Immediate)**
   ```assembly
   csrrci x6, 0x300, 1
   ```
   - **Açıklama:** Immediate değer `1`, `mstatus` CSR'den temizlenir. Eski `mstatus` değeri `x6`'ya yüklenir.
   - **Beklenen Sonuç:** `mstatus`'un güncel değeri `7` olduğundan, `1` ile AND NOT yapılır (`7 & ~1 = 6`). `mstatus` yeni değeri `6` olur ve `x6`'ya önceki `mstatus` değeri olan `7` yazılır.

### **Sonuçların Kontrolü**
Bu testin sonuçlarını doğrulamak için:
- **Her bir registerın değerini (x1 - x6)** eğer bir simülatör veya debug aracı kullanıyorsanız, test sonunda bu registerlara bakarak beklenen sonuçlarla karşılaştırın.
- **mstatus CSR değeri**: Testin sonunda `mstatus`'un değeri `6` olmalıdır.

Eğer registerlar ve `mstatus` CSR bu beklenen değerleri gösteriyorsa, CSR komutları işlemcinizde doğru bir şekilde çalışıyor demektir.