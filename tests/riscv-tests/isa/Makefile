#=======================================================================
# Makefile for riscv-tests/isa (rv32 testleri için .bin ve cache blok ters çevrimi ile .hex üretimi)
#-----------------------------------------------------------------------

# BLOCK_SIZE parametresi (bit cinsinden, örneğin 128 bit)
BLOCK_SIZE ?= 128
# Block size in bytes (hesaplama: BLOCK_SIZE / 8)
BLOCK_BYTES := $(shell echo $$(( $(BLOCK_SIZE) / 8 )))

XLEN ?= 32
src_dir := .

# İlgili Makefrag dosyalarını dahil ediyoruz.
include $(src_dir)/rv32ui/Makefrag
include $(src_dir)/rv32uc/Makefrag
include $(src_dir)/rv32um/Makefrag

default: all

#--------------------------------------------------------------------
# Build rules
#--------------------------------------------------------------------

RISCV_PREFIX ?= riscv$(XLEN)-unknown-elf-
RISCV_GCC ?= $(RISCV_PREFIX)gcc
RISCV_GCC_OPTS ?= -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles
RISCV_OBJDUMP ?= $(RISCV_PREFIX)objdump --disassemble-all --disassemble-zeroes --section=.text --section=.text.startup --section=.text.init --section=.data
RISCV_SIM ?= spike

# Bin ve hex dosyalarını üretmek için objcopy tanımı
RISCV_OBJCOPY ?= $(RISCV_PREFIX)objcopy

vpath %.S $(src_dir)

%.dump: %
	$(RISCV_OBJDUMP) $< > $@

%.out32: %
	$(RISCV_SIM) --isa=rv32imc_zicsr_zifencei --misaligned $< 2> $@

# compile_template fonksiyonu (sadece p testleri için)
# Her test için önce ELF, sonra .bin dosyası oluşturulup,
# sonrasında get_static_hex.py ile BLOCK_BYTES (örn. 16 byte) bazında ters çevrilmiş .hex dosyası üretiliyor.
define compile_template

$$($(1)_p_tests): $(1)-p-%: $(1)/%.S
	$$(RISCV_GCC) $(2) $$(RISCV_GCC_OPTS) -I$(src_dir)/../env/p -I$(src_dir)/macros/scalar -T$(src_dir)/../env/p/link.ld $$< -o $$@
	$$(RISCV_OBJCOPY) $$@ -O binary $$@.bin
	python3 get_static_hex.py -b $(BLOCK_BYTES) $$@.bin > $$@.hex
$(1)_tests += $$($(1)_p_tests)

$(1)_tests_dump = $$(addsuffix .dump, $$($(1)_tests))
$(1): $$($(1)_tests_dump)

.PHONY: $(1)

COMPILER_SUPPORTS_$(1) := $$(shell $$(RISCV_GCC) $(2) -c -x c /dev/null -o /dev/null 2> /dev/null; echo $$$$?)
ifeq ($$(COMPILER_SUPPORTS_$(1)),0)
tests += $$($(1)_tests)
endif

endef

# rv32ui, rv32uc ve rv32um testleri için compile_template çağrısı
$(eval $(call compile_template,rv32ui,-march=rv32imc_zicsr_zifencei -mabi=ilp32))
$(eval $(call compile_template,rv32uc,-march=rv32imc_zicsr_zifencei -mabi=ilp32))
$(eval $(call compile_template,rv32um,-march=rv32imc_zicsr_zifencei -mabi=ilp32))

# Testlerin dump ve çıktı dosyaları
tests_dump = $(addsuffix .dump, $(tests))
tests32_out = $(addsuffix .out32, $(filter rv32%,$(tests)))

run: $(tests32_out)

# Temizlenecek dosyalar: .bin ve .hex dosyaları da dahil
junk += $(tests) $(tests_dump) $(tests32_out) $(wildcard *.bin) $(wildcard *.hex)

all: $(tests_dump)

clean:
	rm -rf $(junk) $(wildcard *.elf) $(wildcard *.hex)
