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



add wave -position insertpoint -radix hexadecimal -group "WRAPPER"  sim:/tb_wrapper/teknofest_wrapper/soc/decode/reg_file/registers
add wave -position insertpoint -radix hexadecimal -group "WRAPPER"  sim:/tb_wrapper/teknofest_wrapper/soc/memory/uart_inst/uart_tx/tx_buffer

################## Wrapper ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group in       sim:/tb_wrapper/teknofest_wrapper/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group out      sim:/tb_wrapper/teknofest_wrapper/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group internal sim:/tb_wrapper/teknofest_wrapper/*

################## MAIN MEMORY ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group "MAIN MEMORY" -group in       sim:/tb_wrapper/teknofest_wrapper/main_memory/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group "MAIN MEMORY" -group out      sim:/tb_wrapper/teknofest_wrapper/main_memory/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group "MAIN MEMORY" -group internal sim:/tb_wrapper/teknofest_wrapper/main_memory/*
add wave -position insertpoint -radix hexadecimal  -group "WRAPPER" -group "UART" sim:/tb_wrapper/teknofest_wrapper/main_memory/simpleuart/*

################## SOC ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group "SOC" -group in       sim:/tb_wrapper/teknofest_wrapper/soc/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group "SOC" -group out      sim:/tb_wrapper/teknofest_wrapper/soc/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group "SOC" -group internal sim:/tb_wrapper/teknofest_wrapper/soc/*

add wave -position insertpoint -radix hexadecimal  -group "WRAPPER" -group "SOC"  -group "FETCH1" -group internal sim:/tb_wrapper/teknofest_wrapper/soc/fetch/*
add wave -position insertpoint -radix hexadecimal  -group "WRAPPER" -group "SOC"  -group "DECODE2" -group internal sim:/tb_wrapper/teknofest_wrapper/soc/decode/*
add wave -position insertpoint -radix hexadecimal  -group "WRAPPER" -group "SOC"  -group "EXECUTION3" -group internal sim:/tb_wrapper/teknofest_wrapper/soc/execution/*
add wave -position insertpoint -radix hexadecimal  -group "WRAPPER" -group "SOC"  -group "MEMORY4" -group internal sim:/tb_wrapper/teknofest_wrapper/soc/memory/*
add wave -position insertpoint -radix hexadecimal  -group "WRAPPER" -group "SOC"  -group "WRITEBACK5" -group internal sim:/tb_wrapper/teknofest_wrapper/soc/writeback/*

################## BRANCH PREDICTION ##################
add wave -position insertpoint  \
-radix hexadecimal          -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "BRANCH PREDICTION" \
sim:/tb_wrapper/teknofest_wrapper/soc/fe_spec \
sim:/tb_wrapper/teknofest_wrapper/soc/de_spec \
sim:/tb_wrapper/teknofest_wrapper/soc/ex_pc_target_last \
sim:/tb_wrapper/teknofest_wrapper/soc/ex_pc_sel \
sim:/tb_wrapper/teknofest_wrapper/soc/ex_spec


add wave -position insertpoint -radix hexadecimal    -in          -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "BRANCH PREDICTION"     -group in        sim:/tb_wrapper/teknofest_wrapper/soc/fetch/branch_prediction/*
add wave -position insertpoint -radix hexadecimal    -out         -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "BRANCH PREDICTION"     -group out       sim:/tb_wrapper/teknofest_wrapper/soc/fetch/branch_prediction/*
add wave -position insertpoint -radix hexadecimal    -internal    -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "BRANCH PREDICTION"     -group internal  sim:/tb_wrapper/teknofest_wrapper/soc/fetch/branch_prediction/*
add wave -position insertpoint -radix hexadecimal     -in         -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "BRANCH PREDICTION"  -group "RAS"  -group in         sim:/tb_wrapper/teknofest_wrapper/soc/fetch/branch_prediction/ras/*
add wave -position insertpoint -radix hexadecimal     -out        -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "BRANCH PREDICTION"  -group "RAS"  -group out        sim:/tb_wrapper/teknofest_wrapper/soc/fetch/branch_prediction/ras/*
add wave -position insertpoint -radix hexadecimal     -internal   -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "BRANCH PREDICTION"  -group "RAS"  -group internal   sim:/tb_wrapper/teknofest_wrapper/soc/fetch/branch_prediction/ras/*
add wave -position insertpoint -radix hexadecimal        -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "IPMA"                    sim:/tb_wrapper/teknofest_wrapper/soc/fetch/ipma/*


################## ALIGN BUFFER ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "ALIGN BUFFER" -group in       sim:/tb_wrapper/teknofest_wrapper/soc/fetch/gray_align_buffer/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "ALIGN BUFFER" -group out      sim:/tb_wrapper/teknofest_wrapper/soc/fetch/gray_align_buffer/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "ALIGN BUFFER" -group internal sim:/tb_wrapper/teknofest_wrapper/soc/fetch/gray_align_buffer/*

################## ICACHE TOP ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "ICACHE" -group in       sim:/tb_wrapper/teknofest_wrapper/soc/fetch/icache/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "ICACHE" -group out      sim:/tb_wrapper/teknofest_wrapper/soc/fetch/icache/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "ICACHE" -group internal sim:/tb_wrapper/teknofest_wrapper/soc/fetch/icache/*

################## COMPRESSED DECODER ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "COMP DECODER" -group in       sim:/tb_wrapper/teknofest_wrapper/soc/fetch/compressed_decoder/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "COMP DECODER" -group out      sim:/tb_wrapper/teknofest_wrapper/soc/fetch/compressed_decoder/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group "SOC"  -group "FETCH1" -group "COMP DECODER" -group internal sim:/tb_wrapper/teknofest_wrapper/soc/fetch/compressed_decoder/*

################## CONTROL UNIT ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group "SOC"  -group "DECODE2" -group "CONTROL UNIT" -group in       sim:/tb_wrapper/teknofest_wrapper/soc/decode/control_unit/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group "SOC"  -group "DECODE2" -group "CONTROL UNIT" -group out      sim:/tb_wrapper/teknofest_wrapper/soc/decode/control_unit/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group "SOC"  -group "DECODE2" -group "CONTROL UNIT" -group internal sim:/tb_wrapper/teknofest_wrapper/soc/decode/control_unit/*

################## REG FILE ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group "SOC"  -group "DECODE2" -group "REG FILE" -group in       sim:/tb_wrapper/teknofest_wrapper/soc/decode/reg_file/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group "SOC"  -group "DECODE2" -group "REG FILE" -group out      sim:/tb_wrapper/teknofest_wrapper/soc/decode/reg_file/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group "SOC"  -group "DECODE2" -group "REG FILE" -group internal sim:/tb_wrapper/teknofest_wrapper/soc/decode/reg_file/*

################## EXTEND ##################
add wave -position insertpoint -radix hexadecimal        -group "WRAPPER" -group "SOC"  -group "DECODE2" -group "EXTEND" -group in       sim:/tb_wrapper/teknofest_wrapper/soc/decode/extend/*

################## ALU ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group "SOC"  -group "EXECUTION3" -group "ALU" -group in       sim:/tb_wrapper/teknofest_wrapper/soc/execution/alu/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group "SOC"  -group "EXECUTION3" -group "ALU" -group out      sim:/tb_wrapper/teknofest_wrapper/soc/execution/alu/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group "SOC"  -group "EXECUTION3" -group "ALU" -group internal sim:/tb_wrapper/teknofest_wrapper/soc/execution/alu/*

################## DCACHE ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group "SOC"  -group "MEMORY4" -group "DCACHE" -group in       sim:/tb_wrapper/teknofest_wrapper/soc/memory/dcache/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group "SOC"  -group "MEMORY4" -group "DCACHE" -group out      sim:/tb_wrapper/teknofest_wrapper/soc/memory/dcache/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group "SOC"  -group "MEMORY4" -group "DCACHE" -group internal sim:/tb_wrapper/teknofest_wrapper/soc/memory/dcache/*
#add wave -position insertpoint -radix hexadecimal           -group "WRAPPER" -group "SOC"  -group "MEMORY4" -group "DPMA"                   sim:/tb_wrapper/teknofest_wrapper/soc/memory/dpma/*

################## UART ##################
add wave -position insertpoint -radix hexadecimal  -group "WRAPPER" -group "SOC"  -group "MEMORY4" -group "UART"   sim:/tb_wrapper/teknofest_wrapper/soc/memory/uart_inst/*
add wave -position insertpoint -radix hexadecimal  -group "WRAPPER" -group "SOC"  -group "MEMORY4" -group "UART"  -group "UART_TX" sim:/tb_wrapper/teknofest_wrapper/soc/memory/uart_inst/uart_tx/*
add wave -position insertpoint -radix hexadecimal  -group "WRAPPER" -group "SOC"  -group "MEMORY4" -group "UART"  -group "UART_RX" sim:/tb_wrapper/teknofest_wrapper/soc/memory/uart_inst/uart_rx/*

################## ARBITER ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group "SOC"  -group "ARBITER" -group in       sim:/tb_wrapper/teknofest_wrapper/soc/memory_arbiter/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group "SOC"  -group "ARBITER" -group out      sim:/tb_wrapper/teknofest_wrapper/soc/memory_arbiter/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group "SOC"  -group "ARBITER" -group internal sim:/tb_wrapper/teknofest_wrapper/soc/memory_arbiter/*

################## HAZARD ##################
add wave -position insertpoint -radix hexadecimal -in       -group "WRAPPER" -group "SOC"  -group "HAZARD" -group in       sim:/tb_wrapper/teknofest_wrapper/soc/hazard_unit/*
add wave -position insertpoint -radix hexadecimal -out      -group "WRAPPER" -group "SOC"  -group "HAZARD" -group out      sim:/tb_wrapper/teknofest_wrapper/soc/hazard_unit/*
add wave -position insertpoint -radix hexadecimal -internal -group "WRAPPER" -group "SOC"  -group "HAZARD" -group internal sim:/tb_wrapper/teknofest_wrapper/soc/hazard_unit/*


run 10000ns
wave zoom full