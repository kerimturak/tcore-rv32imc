#include "Vteknofest_wrapper.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <cstdlib>  // for atoi

vluint64_t main_time = 0;  // global simulation time
double sc_time_stamp() { return main_time; }

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    // Instance
    Vteknofest_wrapper *top = new Vteknofest_wrapper;

    // Trace setup (VCD format)
    VerilatedVcdC *tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("waveform.vcd");

    // Simulation length (parametric)
    uint64_t max_cycles = 1000000;  // default: 1M
    if (argc > 1) {
        max_cycles = std::strtoull(argv[1], nullptr, 10);
        std::cout << "⚙️  Custom simulation length set to " << max_cycles << " cycles." << std::endl;
    } else {
        std::cout << "⚙️  Using default simulation length of 1,000,000 cycles." << std::endl;
    }

    // Initialize signals
    top->clk_i = 0;
    top->rst_ni = 0;
    top->program_rx_i = 1;
    top->uart_rx_i = 1;

    // Reset pulse
    for (int i = 0; i < 20; i++) {  // ~100 ns reset duration
        top->clk_i = !top->clk_i;
        top->eval();
        tfp->dump(main_time++);
    }
    top->rst_ni = 1;

    std::cout << "🚀 Starting Verilator simulation..." << std::endl;

    // Main simulation loop
    while (!Verilated::gotFinish() && main_time < max_cycles) {
        top->clk_i = !top->clk_i;
        top->eval();
        tfp->dump(main_time++);

        // Optional progress message
        if (main_time % 100000 == 0)
            std::cout << "⏱️  Cycle: " << main_time << std::endl;
    }

    tfp->close();
    std::cout << "✅ Simulation finished after " << main_time << " cycles." << std::endl;

    delete tfp;
    delete top;
    return 0;
}
