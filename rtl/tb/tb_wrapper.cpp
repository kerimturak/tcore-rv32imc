#include "Vtb_wrapper.h"       // Verilator tarafından üretilen top module header'ı
#include "verilated.h"
#ifdef TRACE
#include "verilated_vcd_c.h"
#endif

vluint64_t main_time = 0;       // Simülasyon zamanı (ns cinsinden)

double sc_time_stamp() {       // Verilator simülasyonu için gereklidir
    return main_time;
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtb_wrapper* top = new Vtb_wrapper;

    #ifdef TRACE
    // VCD dalga dosyası oluşturma (isteğe bağlı)
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("dump.vcd");
    #endif

    // Basit bir simülasyon döngüsü (örnek: 200 ns çalıştır)
    for (main_time = 0; main_time < 200; main_time++) {
        // Saat sinyali üretimi (örnek: 10 ns per dönem)
        top->clk_i = ((main_time % 10) < 5) ? 0 : 1;
        if (main_time == 20) {
            top->rst_ni = 1; // 20 ns sonra reset'i aktif et
        }
        top->eval();
        #ifdef TRACE
        tfp->dump(main_time);
        #endif
    }

    #ifdef TRACE
    tfp->close();
    delete tfp;
    #endif

    delete top;
    return 0;
}
