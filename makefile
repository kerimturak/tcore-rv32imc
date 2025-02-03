# 🔹 İşlemci ve Test Dizini (Tam Yollar)
HOME_DIR = /home/kerim
TCORE_DIR = $(HOME_DIR)/tcore-rv32imc
ISA_TESTS_DIR = $(HOME_DIR)/riscv/tests/riscv-tests/isa
HEX_FILES = $(wildcard $(ISA_TESTS_DIR)/*.hex)

# 🔹 ModelSim/QuestaSim Ayarları
INC_FILE = $(TCORE_DIR)/rtl/include/
SUPPRESS_CMD = -suppress vlog-2583 -suppress vopt-8386 -suppress vlog-2275 -svinputport=relaxed
VLOG_OPTS = -sv ${SUPPRESS_CMD} +acc +incdir+${INC_FILE}
DEFINE_MACROS = +define+

# 🔹 SystemVerilog & Verilog Kaynak Dosyaları
SV_SOURCES =  $(TCORE_DIR)/rtl/pkg/tcore_param.sv \
              $(wildcard $(TCORE_DIR)/rtl/core/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/core/branch_prediction/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/core/cache/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/core/mul_div/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/core/mul_div/wallace8x8/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/periph/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/ram/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/wrapper/*.sv) \
              $(wildcard $(TCORE_DIR)/rtl/wrapper/*.v)

# 🔹 Test Bench ve Wrapper
TB_FILE = $(TCORE_DIR)/rtl/tb/tb_wrapper.v
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
CHECK_SCRIPT = $(TCORE_DIR)/check_pass_fail.py
DUMP_PARSER = $(TCORE_DIR)/dump_parser.py

# 🔹 RAM İçin Sabit Test Yükleme Dosyası
MEM_FILE = $(TCORE_DIR)/coremark_baremetal_static.mem

# 🔹 Simülasyon Süresi
SIM_TIME = 50000ns

# 🔹 Varsayılan hedef (Tüm testleri çalıştır)
all: compile test_all

# 🔹 Tüm Hex Testlerini Çalıştır ve PASS/FAIL Kontrolü Yap
test_all: $(HEX_FILES)
	@echo "🔄 Running all RISC-V tests..."
	@rm -f test_results.txt sim_log.txt  # Önceki test ve logları temizle
	@for hexfile in $^; do \
		echo "▶ Running test with $$hexfile..."; \
		make single_test TEST_FILE=$$hexfile; \
	done
	@echo "✅ All tests completed! Check test_results.txt for results."

# 🔹 Tek Bir Testi Çalıştır (Simülatör Çıktısını Ayrı Log'a Yaz, Test İsmini Dahil Et)
single_test:
	@echo "🔍 Running test: $(TEST_FILE)"
	@rm -f $(MEM_FILE)  # Önceki RAM dosyasını temizle
	@cp "$(TEST_FILE)" "$(MEM_FILE)"  # RAM'e yeni test yükle
	@make simulate > sim_log.txt 2>&1  # Simülatör çıktısını log dosyasına yönlendir
	@python3 $(DUMP_PARSER) $(TEST_FILE:.hex=.dump) > /dev/null 2>&1  # Dump dosyasını işle
	@echo -n "[ $(notdir $(TEST_FILE)) ]: " >> test_results.txt  # 🔹 Test ismini ekle
	@python3 $(CHECK_SCRIPT) $(PASS_FAIL_ADDR) $(FETCH_LOG) | tee -a test_results.txt  # 🔹 SADECE PASS/FAIL EKLE

# 🔹 ModelSim/QuestaSim ile Simülasyon Çalıştırma
simulate: compile
	$(VSIM) -c $(LIBRARY).$(TOP_LEVEL) -do "run $(SIM_TIME); quit" -t ns -autofindloop -detectzerodelayloop -iterationlimit=5k -voptargs=+acc=npr

# 🔹 SystemVerilog & Verilog Derleme
$(WORK_DIR):
	$(VLIB) $(WORK_DIR)

compile: $(WORK_DIR)
	$(VLOG) -work $(WORK_DIR) $(VLOG_OPTS) $(SV_SOURCES) $(TB_FILE) $(DEFINE_MACROS)

# 🔹 Optimizasyon (İsteğe Bağlı)
optimize: compile
	$(VOPT) -o $(WORK_DIR).$(TOP_LEVEL) $(LIBRARY).$(TOP_LEVEL)

# 🔹 Dump'tan PASS ve FAIL Adreslerini Çıkar
extract:
	python3 $(DUMP_PARSER) $(DUMP_FILE)

# 🔹 Test Sonucunu Kontrol Et
check: extract
	python3 $(CHECK_SCRIPT) $(PASS_FAIL_ADDR) $(FETCH_LOG)

# 🔹 Geçici Dosyaları Temizle
clean:
	rm -rf $(WORK_DIR)
	rm -f transcript vsim.wlf modelsim.ini test_results.txt fetch_log.txt pass_fail_addr.txt sim_log.txt
