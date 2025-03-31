################## Settings ##################

set WildcardFilter [lsearch -not -all -inline $WildcardFilter Memory]
set WildcardFilter [lsearch -not -all -inline $WildcardFilter Nets]
set WildcardFilter [lsearch -not -all -inline $WildcardFilter Variable]
set WildcardFilter [lsearch -not -all -inline $WildcardFilter Constant]
set WildcardFilter [lsearch -not -all -inline $WildcardFilter Parameter]
set WildcardFilter [lsearch -not -all -inline $WildcardFilter SpecParam]
set WildcardFilter [lsearch -not -all -inline $WildcardFilter Generic]

set WildcardSizeThreshold 163840
configure wave -namecolwidth 250
configure wave -valuecolwidth 50
configure wave -justifyvalue left
configure wave -signalnamewidth 1


add wave -position insertpoint -radix hexadecimal -group "WRAPPER"  vsim:/tb_wrapper/teknofest_wrapper/soc/decode/reg_file/registers
add wave -position insertpoint -radix hexadecimal -group "WRAPPER"  vsim:/tb_wrapper/teknofest_wrapper/soc/memory/uart_inst/uart_tx/tx_buffer

add wave -position insertpoint -radix hexadecimal -group "WRAPPER"  -group "CSR" vsim:/tb_wrapper/teknofest_wrapper/soc/execution/u_cs_reg_file/*

################## Wrapper ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group in       vsim:/tb_wrapper/teknofest_wrapper/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group out      vsim:/tb_wrapper/teknofest_wrapper/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group internal vsim:/tb_wrapper/teknofest_wrapper/*

################## MAIN MEMORY ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group "MAIN MEMORY" -group in       vsim:/tb_wrapper/teknofest_wrapper/main_memory/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group "MAIN MEMORY" -group out      vsim:/tb_wrapper/teknofest_wrapper/main_memory/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group "MAIN MEMORY" -group internal vsim:/tb_wrapper/teknofest_wrapper/main_memory/*
add wave -position insertpoint -radix hexadecimal  -group "WRAPPER" -group "UART" vsim:/tb_wrapper/teknofest_wrapper/main_memory/simpleuart/*

################## SOC ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group "SOC" -group in       vsim:/tb_wrapper/teknofest_wrapper/soc/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group "SOC" -group out      vsim:/tb_wrapper/teknofest_wrapper/soc/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group "SOC" -group internal vsim:/tb_wrapper/teknofest_wrapper/soc/*

add wave -position insertpoint -radix hexadecimal  -group "WRAPPER" -group "SOC"  -group "FETCH1" -group internal vsim:/tb_wrapper/teknofest_wrapper/soc/fetch/*
add wave -position insertpoint -radix hexadecimal  -group "WRAPPER" -group "SOC"  -group "DECODE2" -group internal vsim:/tb_wrapper/teknofest_wrapper/soc/decode/*
add wave -position insertpoint -radix hexadecimal  -group "WRAPPER" -group "SOC"  -group "EXECUTION3" -group internal vsim:/tb_wrapper/teknofest_wrapper/soc/execution/*
add wave -position insertpoint -radix hexadecimal  -group "WRAPPER" -group "SOC"  -group "MEMORY4" -group internal vsim:/tb_wrapper/teknofest_wrapper/soc/memory/*
add wave -position insertpoint -radix hexadecimal  -group "WRAPPER" -group "SOC"  -group "WRITEBACK5" -group internal vsim:/tb_wrapper/teknofest_wrapper/soc/writeback/*

################## BRANCH PREDICTION ##################
add wave -position insertpoint  \
-radix hexadecimal          -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "BRANCH PREDICTION" \
vsim:/tb_wrapper/teknofest_wrapper/soc/ex_pc_target_last \
vsim:/tb_wrapper/teknofest_wrapper/soc/ex_pc_sel \


add wave -position insertpoint -radix hexadecimal    -in          -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "BRANCH PREDICTION"     -group in        vsim:/tb_wrapper/teknofest_wrapper/soc/fetch/branch_prediction/*
add wave -position insertpoint -radix hexadecimal    -out         -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "BRANCH PREDICTION"     -group out       vsim:/tb_wrapper/teknofest_wrapper/soc/fetch/branch_prediction/*
add wave -position insertpoint -radix hexadecimal    -internal    -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "BRANCH PREDICTION"     -group internal  vsim:/tb_wrapper/teknofest_wrapper/soc/fetch/branch_prediction/*
add wave -position insertpoint -radix hexadecimal     -in         -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "BRANCH PREDICTION"  -group "RAS"  -group in         vsim:/tb_wrapper/teknofest_wrapper/soc/fetch/branch_prediction/ras/*
add wave -position insertpoint -radix hexadecimal     -out        -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "BRANCH PREDICTION"  -group "RAS"  -group out        vsim:/tb_wrapper/teknofest_wrapper/soc/fetch/branch_prediction/ras/*
add wave -position insertpoint -radix hexadecimal     -internal   -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "BRANCH PREDICTION"  -group "RAS"  -group internal   vsim:/tb_wrapper/teknofest_wrapper/soc/fetch/branch_prediction/ras/*
add wave -position insertpoint -radix hexadecimal        -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "IPMA"                    vsim:/tb_wrapper/teknofest_wrapper/soc/fetch/ipma/*


################## ALIGN BUFFER ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "ALIGN BUFFER" -group in       vsim:/tb_wrapper/teknofest_wrapper/soc/fetch/gray_align_buffer/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "ALIGN BUFFER" -group out      vsim:/tb_wrapper/teknofest_wrapper/soc/fetch/gray_align_buffer/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "ALIGN BUFFER" -group internal vsim:/tb_wrapper/teknofest_wrapper/soc/fetch/gray_align_buffer/*

################## ICACHE TOP ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "ICACHE" -group in       vsim:/tb_wrapper/teknofest_wrapper/soc/fetch/icache/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "ICACHE" -group out      vsim:/tb_wrapper/teknofest_wrapper/soc/fetch/icache/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "ICACHE" -group internal vsim:/tb_wrapper/teknofest_wrapper/soc/fetch/icache/*

################## COMPRESSED DECODER ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "COMP DECODER" -group in       vsim:/tb_wrapper/teknofest_wrapper/soc/fetch/compressed_decoder/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "COMP DECODER" -group out      vsim:/tb_wrapper/teknofest_wrapper/soc/fetch/compressed_decoder/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "COMP DECODER" -group internal vsim:/tb_wrapper/teknofest_wrapper/soc/fetch/compressed_decoder/*

################## CONTROL UNIT ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group "SOC"  -group "DECODE2" -group "CONTROL UNIT" -group in       vsim:/tb_wrapper/teknofest_wrapper/soc/decode/control_unit/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group "SOC"  -group "DECODE2" -group "CONTROL UNIT" -group out      vsim:/tb_wrapper/teknofest_wrapper/soc/decode/control_unit/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group "SOC"  -group "DECODE2" -group "CONTROL UNIT" -group internal vsim:/tb_wrapper/teknofest_wrapper/soc/decode/control_unit/*

################## REG FILE ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group "SOC"  -group "DECODE2" -group "REG FILE" -group in       vsim:/tb_wrapper/teknofest_wrapper/soc/decode/reg_file/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group "SOC"  -group "DECODE2" -group "REG FILE" -group out      vsim:/tb_wrapper/teknofest_wrapper/soc/decode/reg_file/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group "SOC"  -group "DECODE2" -group "REG FILE" -group internal vsim:/tb_wrapper/teknofest_wrapper/soc/decode/reg_file/*

################## EXTEND ##################
add wave -position insertpoint -radix hexadecimal        -group "WRAPPER" -group "SOC"  -group "DECODE2" -group "EXTEND" -group in       vsim:/tb_wrapper/teknofest_wrapper/soc/decode/extend/*

################## ALU ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group "SOC"  -group "EXECUTION3" -group "ALU" -group in       vsim:/tb_wrapper/teknofest_wrapper/soc/execution/alu/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group "SOC"  -group "EXECUTION3" -group "ALU" -group out      vsim:/tb_wrapper/teknofest_wrapper/soc/execution/alu/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group "SOC"  -group "EXECUTION3" -group "ALU" -group internal vsim:/tb_wrapper/teknofest_wrapper/soc/execution/alu/*

################## CS_RF ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group "SOC"  -group "EXECUTION3" -group "CSR" -group in       vsim:/tb_wrapper/teknofest_wrapper/soc/execution/u_cs_reg_file/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group "SOC"  -group "EXECUTION3" -group "CSR" -group out      vsim:/tb_wrapper/teknofest_wrapper/soc/execution/u_cs_reg_file/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group "SOC"  -group "EXECUTION3" -group "CSR" -group internal vsim:/tb_wrapper/teknofest_wrapper/soc/execution/u_cs_reg_file/*


################## DCACHE ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group "SOC"  -group "MEMORY4" -group "DCACHE" -group in       vsim:/tb_wrapper/teknofest_wrapper/soc/memory/dcache/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group "SOC"  -group "MEMORY4" -group "DCACHE" -group out      vsim:/tb_wrapper/teknofest_wrapper/soc/memory/dcache/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group "SOC"  -group "MEMORY4" -group "DCACHE" -group internal vsim:/tb_wrapper/teknofest_wrapper/soc/memory/dcache/*
#add wave -position insertpoint -radix hexadecimal           -group "WRAPPER" -group "SOC"  -group "MEMORY4" -group "DPMA"                   vsim:/tb_wrapper/teknofest_wrapper/soc/memory/dpma/*

################## UART ##################
add wave -position insertpoint -radix hexadecimal  -group "WRAPPER" -group "SOC"  -group "MEMORY4" -group "UART"   vsim:/tb_wrapper/teknofest_wrapper/soc/memory/uart_inst/*
add wave -position insertpoint -radix hexadecimal  -group "WRAPPER" -group "SOC"  -group "MEMORY4" -group "UART"  -group "UART_TX" vsim:/tb_wrapper/teknofest_wrapper/soc/memory/uart_inst/uart_tx/*
add wave -position insertpoint -radix hexadecimal  -group "WRAPPER" -group "SOC"  -group "MEMORY4" -group "UART"  -group "UART_RX" vsim:/tb_wrapper/teknofest_wrapper/soc/memory/uart_inst/uart_rx/*

################## ARBITER ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group "SOC"  -group "ARBITER" -group in       vsim:/tb_wrapper/teknofest_wrapper/soc/memory_arbiter/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group "SOC"  -group "ARBITER" -group out      vsim:/tb_wrapper/teknofest_wrapper/soc/memory_arbiter/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group "SOC"  -group "ARBITER" -group internal vsim:/tb_wrapper/teknofest_wrapper/soc/memory_arbiter/*

################## HAZARD ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group "SOC"  -group "HAZARD" -group in       vsim:/tb_wrapper/teknofest_wrapper/soc/hazard_unit/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group "SOC"  -group "HAZARD" -group out      vsim:/tb_wrapper/teknofest_wrapper/soc/hazard_unit/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group "SOC"  -group "HAZARD" -group internal vsim:/tb_wrapper/teknofest_wrapper/soc/hazard_unit/*


run 10000ns
wave zoom full