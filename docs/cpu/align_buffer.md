Harika, aşağıya tasarımınızda **128-bit block size** kullanıldığında ne gibi değişiklikler olduğunu da sade ve net şekilde ekledim. Bu bölümü dökümantasyonun sonuna "📏 Design with 128-bit Block Size" başlığıyla ekledim:

---

# Align Buffer - Documentation

## 🧠 Purpose

The `align_buffer` module is designed for fetching and aligning **RISC-V compressed instructions** (16-bit) into **32-bit instruction words**. It solves the problem of **unaligned accesses**, where a 32-bit instruction may cross cache line boundaries.

## ⚙️ How It Works

Instructions are stored in 16-bit chunks called **parcels**. Each cache block holds multiple parcels, and these are split into two banks:

- **Odd Bank** → Stores lower 16 bits of 32-bit instructions  
- **Even Bank** → Stores upper 16 bits

This separation allows fetching unaligned instructions by reading across two blocks if needed.

---

### 📦 Address Breakdown

Each instruction fetch uses the Program Counter (PC):

```
31      10      9      2     1     0
+--------+------+-----+-----+-----+
|  Tag   |Index |Word |Byte |Align|
+--------+------+-----+-----+-----+
```

- **Index:** selects the cache set  
- **PC[1]:** tells if the instruction is aligned (`0`) or unaligned (`1`)  
- If `PC[1] == 1`, instruction crosses to next cache line → fetch from **odd** and **even**

---

### 📐 Visual Overview

```plaintext
         Program Counter
               |
     +---------+-----------+
     |                     |
   Index               Index + 1 (if unaligned)
     |                     |
     v                     v
+-----------+       +-------------+
| Odd Bank  |       | Even Bank   |
|-----------|       |-------------|
| 0x20 A[15:0]       | A[31:16]    |
| 0x40 B[15:0]       | B[31:16]    |
| ...                | ...         |
+-----------+       +-------------+
        \             /
         \           /
        Concatenate (32-bit)
             ↓
         To decoder
```

---

## 🧩 Internal Logic (Simplified)

- **Unaligned detection:**  
  If `PC[1] == 1` and access crosses block boundary → fetch from both banks

- **Tag comparison:**  
  Tag RAM holds valid bits and tags per set. Each bank compares its tag to detect hit/miss.

- **Write logic:**  
  If a miss occurs, new data from lower-level memory (`lowX_res_i`) is written into the corresponding bank.

- **Data output:**  
  Parcels from even/odd are concatenated into a full 32-bit instruction and sent to decoder.

---

## 💾 Memory Interface

If data is not found (miss), a request is sent to lower memory using `lowX_req_o`.  
After a valid response (`lowX_res_i`), data is stored and delivered.

---

## ✅ Why This Design?

- Handles both 16-bit and 32-bit instruction fetches  
- Supports unaligned accesses efficiently  
- Works like a small instruction cache optimized for compressed instructions  
- Modular and scalable (e.g., set-associative support in future)

---

## 📏 Design with 128-bit Block Size

In our design, each cache block is **128 bits wide**, meaning:

- Each block holds **four 32-bit instructions** or **eight 16-bit parcels**.
- The address decoding (`BOFFSET`) is adjusted accordingly to select 128-bit aligned blocks.
- **Parcel index** and **word selection** logic are derived from bits `[4:2]` of the address.
- Having more parcels per block reduces the number of cache accesses:
  - **More instructions are covered per fetch**
  - **Better utilization of fetched data**
- However, **unaligned accesses** can still span two 128-bit blocks.  
  In that case, the buffer fetches from **odd** and **even** banks and combines parcels.

### ✅ Result:
- Efficient support for compressed instructions  
- Fewer lower-memory requests  
- High hit rate in instruction buffer due to larger block coverage

---

İstersen bu dökümanı `.md` veya `.pdf` olarak da düzenleyip paylaşabilirim. Bir frontend doküman sayfasına gömmek istersen ona göre de formatlayabiliriz. Hazır mısın export etmeye?