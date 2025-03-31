# 🔹 İşlemci ve Test Dizini (Tam Yollar)
HOME_DIR         = /home/kerim
TCORE_DIR        = $(HOME_DIR)/tcore-rv32imc

# ISA testlerinin bulunduğu dizin
ISA_TESTS_DIR    = $(TCORE_DIR)/tests/riscv-tests/isa

# Imperas ve riscv-arch-test tabanlı HEX dosyalarının bulunduğu dizinler
IMPERAS_HEX_DIR  = $(TCORE_DIR)/tests/imperas-riscv-tests/work/rv32i_m/I/hex \
									 $(TCORE_DIR)/tests/imperas-riscv-tests/work/rv32i_m/M/hex \
									 $(TCORE_DIR)/tests/imperas-riscv-tests/work/rv32i_m/C/hex
ARCH_HEX_DIR     = $(TCORE_DIR)/tests/riscv-arch-test/work/rv32i_m/I/hex \
									 $(TCORE_DIR)/tests/riscv-arch-test/work/rv32i_m/M/hex \
									 $(TCORE_DIR)/tests/riscv-arch-test/work/rv32i_m/C/hex

# Tüm HEX dosyalarını bir araya getiren değişken:
HEX_FILES = $(wildcard $(IMPERAS_HEX_DIR)/*.hex) \
            $(wildcard $(ARCH_HEX_DIR)/*.hex) \
            $(wildcard $(ISA_TESTS_DIR)/*.hex)


# 🔹 ModelSim/QuestaSim Ayarları (Hızlandırma İçin Optimize Edildi)
INC_FILE = $(TCORE_DIR)/rtl/include/
SUPPRESS_CMD = -suppress vlog-2583 -suppress vopt-8386 -suppress vlog-2275 -svinputport=relaxed
VLOG_OPTS = -sv ${SUPPRESS_CMD} +acc=npr +incdir+${INC_FILE} -work $(WORK_DIR) -mfcu -quiet
DEFINE_MACROS = +define+

# 🔹 SystemVerilog & Verilog Kaynak Dosyaları
SV_SOURCES =  $(TCORE_DIR)/rtl/pkg/tcore_param.sv \
              $(wildcard $(TCORE_DIR)/rtl/core/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/core/pmp_pma/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/core/stage01_fetch/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/core/stage02_decode/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/core/stage03_execute/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/core/stage03_execute/mul_div/wallace32x32/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/core/stage03_execute/mul_div/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/core/stage03_execute/mul_div/wallace8x8/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/core/stage04_memory/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/core/stage05_writeback/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/core/mmu/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/periph/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/ram/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/wrapper/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/wrapper/*.v)

# 🔹 Test Bench ve Wrapper (ModelSim için)
TB_FILE = $(TCORE_DIR)/rtl/tb/tb_wrapper.sv
TOP_LEVEL = tb_wrapper
LIBRARY = work
VSIM = vsim
VLOG = vlog
VOPT = vopt
VLIB = vlib
WORK_DIR = work

# 🔹 Dump & Fetch Log Dosyaları
FETCH_LOG = fetch_log.txt
PASS_FAIL_ADDR = pass_fail_addr.txt
CHECK_SCRIPT = $(TCORE_DIR)/sw/check_pass_fail.py
DUMP_PARSER = $(TCORE_DIR)/sw/dump_parser.py

# 🔹 RAM İçin Sabit Test Yükleme Dosyası
MEM_FILE = $(TCORE_DIR)/coremark_baremetal_static.mem
# 🔹 Simülasyon Süresi (ModelSim için)
SIM_TIME = 20000ns

# ----------------------------------------------------------------------
# Hedefler: ModelSim/QuestaSim ile çalıştırma
# ----------------------------------------------------------------------

# Varsayılan hedef (Tüm testleri ModelSim ile çalıştır)
all: compile test_all

# Tüm Hex testlerini sıralı çalıştır (ModelSim)
test_all: $(HEX_FILES)
	@echo "🔄 Running all RISC-V tests sequentially (ModelSim)..."
	@rm -f test_results.txt sim_log.txt  # Önceki test ve logları temizle
	@for hexfile in $(HEX_FILES); do \
		echo "▶ Running test with $$hexfile..."; \
		make -f makefile single_test TEST_FILE="$$hexfile"; \
	done
	@echo "✅ All tests completed! Check test_results.txt for results."

# Tek bir testin çalıştırılması (ModelSim)
single_test:
	@echo "🔍 Running test: $(TEST_FILE)"
	@rm -f $(MEM_FILE)  # Önceki RAM dosyasını temizle
	@cp "$(TEST_FILE)" "$(MEM_FILE)"  # RAM'e yeni test yükle
	@make simulate > /dev/null 2>&1  # Batch modda simülasyonu sessiz çalıştır
	@python3 $(DUMP_PARSER) $(TEST_FILE:.hex=.dump) > /dev/null 2>&1  # Dump dosyasını sessizce işle
	@echo -n "[ $(notdir $(TEST_FILE)) ]: " >> test_results.txt  # Test ismini yaz
	@python3 $(CHECK_SCRIPT) $(PASS_FAIL_ADDR) $(FETCH_LOG) | tee -a test_results.txt  # PASS/FAIL durumunu ekle

# ModelSim/QuestaSim ile Batch modda simülasyon
simulate: compile
	$(VSIM) -c $(LIBRARY).$(TOP_LEVEL) -do "run $(SIM_TIME); quit" -t ns -voptargs=+acc=npr

# ModelSim/QuestaSim ile GUI modunda simülasyon (Eski yöntem)
simulate_gui: compile
	$(VSIM) $(LIBRARY).$(TOP_LEVEL) -do "questa.do" -t ns -voptargs=+acc=npr

# ----------------------------------------------------------------------
# Yeni Hedefler: Verilator ile çalıştırma
# ----------------------------------------------------------------------
# Not: Verilator kullanabilmek için tasarımınızın synthesizable olması
# ve C++ testbench dosyanızın (örneğin, tb_wrapper.cpp) mevcut olması gerekir.
# Aşağıda, Verilator ile simülasyon yapacak hedefler eklenmiştir.

# Verilator ile derleme için C++ testbench dosyasının yolu (düzenleyin gerekirse)
VERILATOR_TB = $(TCORE_DIR)/tb_wrapper.cpp

# Verilator ile simülasyonu derleyip çalıştırma
simulate_verilator: compile_verilator
	@echo "🔍 Running simulation with Verilator..."
	@./obj_dir/V$(TOP_LEVEL) | tee -a test_results.txt

# Verilator ile derleme
compile_verilator:
	@echo "Compiling design with Verilator..."
	verilator --cc $(SV_SOURCES) $(TB_FILE) --exe $(VERILATOR_TB) --top-module $(TOP_LEVEL) --trace --trace-fst --trace-structs --build -I$(TCORE_DIR)/rtl/include --timing

# Tek bir testin Verilator ile çalıştırılması
single_test_verilator:
	@echo "🔍 Running test with Verilator: $(TEST_FILE)"
	@rm -f $(MEM_FILE)
	@cp "$(TEST_FILE)" "$(MEM_FILE)"
	@make simulate_verilator
	@python3 $(DUMP_PARSER) $(TEST_FILE:.hex=.dump) > /dev/null 2>&1
	@echo -n "[ $(notdir $(TEST_FILE)) ] (Verilator): " >> test_results.txt
	@python3 $(CHECK_SCRIPT) $(PASS_FAIL_ADDR) $(FETCH_LOG) | tee -a test_results.txt

# ----------------------------------------------------------------------
# Derleme (ModelSim/QuestaSim için)
$(WORK_DIR):
	$(VLIB) $(WORK_DIR)

compile: $(WORK_DIR)
	$(VLOG) -work $(WORK_DIR) $(VLOG_OPTS) $(SV_SOURCES) $(TB_FILE) $(DEFINE_MACROS)
	#$(VOPT) $(VOPT_OPTS) $(LIBRARY).$(TOP_LEVEL)

# ----------------------------------------------------------------------
# Optimizasyon (isteğe bağlı, ModelSim/QuestaSim için)
#optimize: compile
#	$(VOPT) -o $(WORK_DIR).$(TOP_LEVEL) $(LIBRARY).$(TOP_LEVEL)

# ----------------------------------------------------------------------
# Dump'tan PASS ve FAIL Adreslerini Çıkar
extract:
	python3 $(DUMP_PARSER) $(DUMP_FILE) > /dev/null 2>&1

# Test Sonucunu Kontrol Et
check: extract
	python3 $(CHECK_SCRIPT) $(PASS_FAIL_ADDR) $(FETCH_LOG) > /dev/null 2>&1

# ----------------------------------------------------------------------
# Temizlik
clean:
	rm -rf $(WORK_DIR)
	rm -f transcript vsim.wlf modelsim.ini test_results.txt fetch_log.txt pass_fail_addr.txt sim_log.txt

.PHONY: all compile simulate simulate_gui simulate_verilator single_test single_test_verilator optimize extract check clean
