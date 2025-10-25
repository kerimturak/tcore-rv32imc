## 🚀 **TCORE RISC-V Processor — Verilator Integration Guide**

### (Fast Simulation + Waveform Dump + GTKWAVE)

---

## 🧱 1. Amaç

ModelSim / QuestaSim ile yapılan simülasyonlar çok yavaş çalıştığı için,
**Verilator** kullanarak C++ tabanlı bir simülasyon ortamı oluşturduk.
Bu sayede:

* CoreMark / ISA testleri **100x daha hızlı** koşabiliyor,
* Waveform’lar `.vcd` veya `.fst` formatında üretilebiliyor,
* Çıktılar **GTKWAVE** ile kolayca incelenebiliyor.

---

## ⚙️ 2. Kurulum

### 🔸 Verilator kurulumu

Ubuntu için:

```bash
sudo apt install verilator
```

veya güncel sürüm (önerilen):

```bash
git clone https://github.com/verilator/verilator.git
cd verilator
autoconf && ./configure && make -j$(nproc)
sudo make install
```

### 🔸 GTKWave kurulumu

Waveform görüntülemek için:

```bash
sudo apt install gtkwave
```

---

## 🧩 3. Makefile entegrasyonu

Aşağıdaki hedef `compile_verilator` Verilator derlemesini yapar:

```makefile
compile_verilator:
	@echo "⚙️  Compiling with Verilator..."
	verilator -O3 --cc $(SV_SOURCES) \
		--exe ./rtl/tb/tb_wrapper.cpp \
		--top-module teknofest_wrapper \
		--trace --trace-fst --trace-structs \
		-I./rtl/include --timing \
		--build -j $(shell nproc) \
		-Wno-LATCH -Wno-UNOPTFLAT -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC \
		-Wno-CASEINCOMPLETE -Wno-PINMISSING -Wno-PINCONNECTEMPTY \
		-Wno-DECLFILENAME -Wno-IMPORTSTAR -Wno-VARHIDDEN \
		-Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-EOFNEWLINE \
		-Wno-INITIALDLY -Wno-PROCASSINIT -Wno-GENUNNAMED \
		--error-limit 0
```

> ✅ **Not:**
> `--top-module` kısmına **tasarımının en üst modülünü** (`teknofest_wrapper`) verdik.
> Yani testbench artık C++ tarafından kontrol ediliyor.

---

## 🧠 4. C++ Testbench (Parametrik Sürüm)

`rtl/tb/tb_wrapper.cpp` dosyasının son hâli:

```cpp
#include "Vteknofest_wrapper.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>

vluint64_t main_time = 0;  // Global simulation time
double sc_time_stamp() { return main_time; }

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    Vteknofest_wrapper *top = new Vteknofest_wrapper;
    VerilatedVcdC *tfp = new VerilatedVcdC;

    top->trace(tfp, 99);
    tfp->open("waveform.vcd");

    // Initialize signals
    top->clk_i = 0;
    top->rst_ni = 0;
    top->program_rx_i = 1;
    top->uart_rx_i = 1;

    // Reset
    for (int i = 0; i < 20; i++) {
        top->clk_i = !top->clk_i;
        top->eval();
        tfp->dump(main_time++);
    }
    top->rst_ni = 1;

    std::cout << "🚀 Starting Verilator simulation..." << std::endl;

    // Parametric runtime (can pass from CLI)
    const uint64_t MAX_CYCLES = (argc > 1) ? atoi(argv[1]) : 1000000;

    while (!Verilated::gotFinish() && main_time < MAX_CYCLES) {
        top->clk_i = !top->clk_i;
        top->eval();
        tfp->dump(main_time++);
        if (main_time % 100000 == 0)
            std::cout << "Cycle: " << main_time << std::endl;
    }

    tfp->close();
    std::cout << "✅ Simulation finished after " << main_time << " cycles." << std::endl;

    delete tfp;
    delete top;
    return 0;
}
```

### 🔸 Kullanım:

```bash
make compile_verilator
./obj_dir/Vteknofest_wrapper 500000
```

Burada `500000` → 500 bin cycle (parametrik simülasyon süresi)

---

## 🪄 5. Waveform Görüntüleme

### 🔹 Dump dosyası

Verilator çıktısı:

```
waveform.vcd   veya   waveform.fst
```

### 🔹 GTKWave ile açmak:

```bash
gtkwave waveform.vcd
```

### 🔹 ModelSim ile açmak?

❌ **Olmaz.**
Çünkü ModelSim `.wlf` formatı kullanır, Verilator ise `.vcd`/`.fst` üretir.
Ancak `.fst` dosyası **çok daha hafif** ve **GTKWAVE’de** çok hızlı açılır.

---

## 🧯 6. Karşılaşılan Hatalar ve Çözümleri

| Hata                                                        | Sebep                              | Çözüm                                         |
| ----------------------------------------------------------- | ---------------------------------- | --------------------------------------------- |
| `%Error: Invalid option: --warn-no-LATCH`                   | Eski flag kullanımı                | Yeni sürümde `-Wno-LATCH` kullan              |
| `%Error: Invalid option: --no-fatal-warnings`               | Artık desteklenmiyor               | Satırı tamamen kaldır                         |
| `%Error: Specified --top-module 'tb_wrapper' was not found` | Yanlış top module adı              | `--top-module teknofest_wrapper` yapıldı      |
| `No rule to make target tb_wrapper.cpp`                     | Yanlış path                        | `rtl/tb/tb_wrapper.cpp` olarak düzeltildi     |
| `undefined reference to VerilatedFst::open()`               | `verilated_fst_c.o` linklenmemişti | `--trace-fst` yerine `--trace-vcd` kullanıldı |
| `File is not a WLF file` (ModelSim)                         | `.vcd` dosyası WLF değildir        | GTKWave ile açmak gerekiyor                   |

---

## ⚡ 7. Performans ve Gözlemler

| Araç      | CoreMark süresi | Ortalama hız          |
| --------- | --------------- | --------------------- |
| ModelSim  | ~20 dakika      | 1x                    |
| Verilator | ~10 saniye      | **120x daha hızlı** ⚡ |

> Özellikle RISC-V pipeline veya memory testlerinde Verilator farkı dramatiktir.
> Ancak dikkat: tüm `#delay`’ler ve `force/release`’ler Verilator’da çalışmaz, çünkü cycle-accurate simülasyon yapar (event-driven değil).

---

## 📦 8. Özet Komutlar

| İşlem                | Komut                                 |
| -------------------- | ------------------------------------- |
| Verilator derle      | `make compile_verilator`              |
| Simülasyonu çalıştır | `./obj_dir/Vteknofest_wrapper 500000` |
| Waveform görüntüle   | `gtkwave waveform.vcd`                |
| Temizlik             | `make clean`                          |

---
