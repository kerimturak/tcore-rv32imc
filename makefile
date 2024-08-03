# Makefile for ModelSim simulation with SystemVerilog
INC_FILE = ./rtl/include/

SUPPRESS_CMD =-suppress vlog-2583 -suppress vopt-8386 -suppress vlog-2275 -svinputport=relaxed
VLOG_OPTS = -sv ${SUPPRESS_CMD} +acc +incdir+${INC_FILE}
DEFINE_MACROS = +define+

# SystemVerilog source files
TB_FILE = ./rtl/tb/tb_wrapper.v
SV_SOURCES = 	./rtl/pkg/tcore_param.sv \
				./rtl/core/* \
				./rtl/core/branch_prediction/* \
				./rtl/core/cache/* \
				./rtl/core/mul_div/* \
				./rtl/core/mul_div/wallace8x8/* \
				./rtl/core/mul_div/wallace32x32/* \
				./rtl/periph/* \
				./rtl/ram/* \
				./rtl/wrapper/*.*v \

# Top level module for simulation
TOP_LEVEL = tb_wrapper

# Simulation library
LIBRARY = work

# Simulation time (optional)
SIM_TIME = 24000ns

# ModelSim commands
VSIM = vsim
VLOG = vlog
VOPT = vopt
VLIB = vlib

# Simulation work directory
WORK_DIR = work

# Optimized library
OPTIMIZED_LIB = work_optimized

# Default target
all: compile simulate

# Create the work library
$(WORK_DIR):
	$(VLIB) $(WORK_DIR)

# Compile SystemVerilog files
compile: $(WORK_DIR)
	$(VLOG) -work $(WORK_DIR) $(VLOG_OPTS) $(SV_SOURCES) $(TB_FILE) $(DEFINE_MACROS)
#$(VOPT) ${SUPPRESS_CMD} +acc work.${TOP_LEVEL} -o ${TOP_LEVEL}_opt

# Optimize compiled design
optimize: compile
	$(VOPT) -o $(OPTIMIZED_LIB).$(TOP_LEVEL) $(LIBRARY).$(TOP_LEVEL)

# Run simulation
simulate: compile
	$(VSIM)  $(LIBRARY).$(TOP_LEVEL) -do "questa.do" -t ns -autofindloop -detectzerodelayloop -iterationlimit=5k -voptargs=+acc=npr
# Clean generated files
clean:
	rm -rf $(WORK_DIR)
	rm -f transcript
	rm -f vsim.wlf
	rm -f modelsim.ini

.PHONY: all compile simulate clean
