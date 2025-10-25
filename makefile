# ============================================================
# 🔹 TCORE RISC-V Processor — Unified Makefile (ModelSim + Verilator)
# ============================================================

TCORE_DIR        = .
ISA_TESTS_DIR    = $(TCORE_DIR)/tests/riscv-tests/isa
IMPERAS_HEX_DIR  = $(TCORE_DIR)/tests/imperas-riscv-tests/work/rv32i_m/I/hex \
                   $(TCORE_DIR)/tests/imperas-riscv-tests/work/rv32i_m/M/hex \
                   $(TCORE_DIR)/tests/imperas-riscv-tests/work/rv32i_m/C/hex
ARCH_HEX_DIR     = $(TCORE_DIR)/tests/riscv-arch-test/work/rv32i_m/I/hex \
                   $(TCORE_DIR)/tests/riscv-arch-test/work/rv32i_m/M/hex \
                   $(TCORE_DIR)/tests/riscv-arch-test/work/rv32i_m/C/hex

HEX_FILES = $(wildcard $(IMPERAS_HEX_DIR)/*.hex) \
            $(wildcard $(ARCH_HEX_DIR)/*.hex) \
            $(wildcard $(ISA_TESTS_DIR)/*.hex)

INC_FILE = $(TCORE_DIR)/rtl/include/
SUPPRESS_CMD = -suppress vlog-2583 -suppress vopt-8386 -suppress vlog-2275 -svinputport=relaxed
VLOG_OPTS = -sv ${SUPPRESS_CMD} +acc=npr +incdir+${INC_FILE} -work $(WORK_DIR) -mfcu -quiet

SV_SOURCES =  $(TCORE_DIR)/rtl/pkg/tcore_param.sv \
              $(wildcard $(TCORE_DIR)/rtl/core/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/core/branch_prediction/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/core/cache/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/core/mul_div/wallace32x32/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/core/mul_div/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/core/mul_div/wallace8x8/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/periph/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/ram/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/wrapper/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/wrapper/*.v)

TB_FILE     = $(TCORE_DIR)/rtl/tb/tb_wrapper.v
TOP_LEVEL   = tb_wrapper
VERILATOR_TOP_LEVEL   = teknofest_wrapper
LIBRARY     = work
WORK_DIR    = work
MEM_FILE    = $(TCORE_DIR)/test.mem
FETCH_LOG   = fetch_log.txt
PASS_FAIL_ADDR = pass_fail_addr.txt
CHECK_SCRIPT   = $(TCORE_DIR)/sw/check_pass_fail.py
DUMP_PARSER    = $(TCORE_DIR)/sw/dump_parser.py
SIM_TIME    = 20000ns

# ============================================================
# 🔹 MODEL SIM TARGETS
# ============================================================

VSIM = vsim
VLOG = vlog
VOPT = vopt
VLIB = vlib

all: compile test_all

test_all: $(HEX_FILES)
	@echo "🔄 Running all RISC-V tests sequentially (ModelSim)..."
	@rm -f test_results.txt sim_log.txt
	@for hexfile in $(HEX_FILES); do \
		echo "▶ Running test with $$hexfile..."; \
		make -s single_test TEST_FILE="$$hexfile"; \
	done
	@echo "✅ All tests completed! Check test_results.txt for results."

single_test:
	@echo "🔍 Running test: $(TEST_FILE)"
	@rm -f $(MEM_FILE)
	@cp "$(TEST_FILE)" "$(MEM_FILE)"
	@make -s simulate
	@python3 $(DUMP_PARSER) $(TEST_FILE:.hex=.dump) > /dev/null 2>&1
	@echo -n "[ $(notdir $(TEST_FILE)) ]: " >> test_results.txt
	@python3 $(CHECK_SCRIPT) $(PASS_FAIL_ADDR) $(FETCH_LOG) | tee -a test_results.txt

simulate: compile
	$(VSIM) -c $(LIBRARY).$(TOP_LEVEL) -do "run $(SIM_TIME); quit" -t ns -voptargs=+acc=npr

compile: $(WORK_DIR)
	$(VLOG) -work $(WORK_DIR) $(VLOG_OPTS) $(SV_SOURCES) $(TB_FILE)

$(WORK_DIR):
	$(VLIB) $(WORK_DIR)

clean:
	rm -rf $(WORK_DIR) obj_dir *.log *.vcd *.fst test_results.txt $(FETCH_LOG) $(PASS_FAIL_ADDR)
	rm -f transcript vsim.wlf modelsim.ini sim_log.txt

# ============================================================
# 🔹 VERILATOR TARGETS
# ============================================================

VERILATOR_TB = $(TCORE_DIR)/rtl/tb/tb_wrapper.cpp
# ⚙️ Verilator derleme
compile_verilator:
	@echo "⚙️  Compiling with Verilator (v5.040 safe mode, no fatal warnings)..."
	verilator -O3 --cc $(SV_SOURCES) \
		--exe $(VERILATOR_TB) \
		--top-module $(VERILATOR_TOP_LEVEL) \
		--trace --trace-vcd --trace-structs \
		-I$(TCORE_DIR)/rtl/include --timing \
		--build -j $(shell nproc) \
		-Wno-LATCH -Wno-UNOPTFLAT -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC \
		-Wno-CASEINCOMPLETE -Wno-PINMISSING -Wno-PINCONNECTEMPTY \
		-Wno-DECLFILENAME -Wno-IMPORTSTAR -Wno-VARHIDDEN \
		-Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-EOFNEWLINE \
		-Wno-INITIALDLY -Wno-PROCASSINIT -Wno-GENUNNAMED \
		--error-limit 0

# ▶ Tek test çalıştırma
verilator:
	@echo "🔍 Running Verilator simulation..."
	@./obj_dir/V$(VERILATOR_TOP_LEVEL)

single_test_verilator:
	@echo "🔍 Running test with Verilator: $(TEST_FILE)"
	@rm -f $(MEM_FILE)
	@cp "$(TEST_FILE)" "$(MEM_FILE)"
	@make -s compile_verilator
	@./obj_dir/V$(VERILATOR_TOP_LEVEL) > verilator_run.log
	@python3 $(DUMP_PARSER) $(TEST_FILE:.hex=.dump) > /dev/null 2>&1
	@echo -n "[ $(notdir $(TEST_FILE)) ] (Verilator): " >> test_results.txt
	@python3 $(CHECK_SCRIPT) $(PASS_FAIL_ADDR) $(FETCH_LOG) | tee -a test_results.txt

# ▶ Tüm testleri sırayla çalıştır
verilator_all: $(HEX_FILES)
	@echo "🚀 Running all tests sequentially (Verilator)..."
	@rm -f test_results.txt
	@for hexfile in $(HEX_FILES); do \
		echo "▶ Running test with $$hexfile..."; \
		make -s single_test_verilator TEST_FILE="$$hexfile"; \
	done
	@echo "✅ Verilator batch tests done! Check test_results.txt."

# ▶ Dump üretimi (gtkwave / vsim için)
verilator_dump:
	@echo "🧠 Running Verilator with waveform dump..."
	@./obj_dir/V$(VERILATOR_TOP_LEVEL) > verilator_run.log
	@echo "💾 Dump ready: dump.vcd  →  use gtkwave or vsim -view dump.vcd"

# ▶ Verilator simülasyonu (derleme + koşum)
verilator_sim:
	@echo "🚀 Building and running Verilator simulation..."
	@make -s compile_verilator
	@./obj_dir/V$(VERILATOR_TOP_LEVEL) 500000 > verilator_run.log
	@echo "💾 Dump generated → waveform.vcd"
	@echo "👀 To view:  gtkwave waveform.vcd &"


.PHONY: all compile simulate verilator verilator_all single_test single_test_verilator clean
