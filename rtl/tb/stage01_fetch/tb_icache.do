onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group PARAMS /tb_icache/dut/CACHE_SIZE
add wave -noupdate -group PARAMS /tb_icache/dut/BLK_SIZE
add wave -noupdate -group PARAMS /tb_icache/dut/XLEN
add wave -noupdate -group PARAMS /tb_icache/dut/NUM_WAY
add wave -noupdate -group PARAMS /tb_icache/dut/NUM_SET
add wave -noupdate -group PARAMS /tb_icache/dut/IDX_WIDTH
add wave -noupdate -group PARAMS /tb_icache/dut/BOFFSET
add wave -noupdate -group PARAMS /tb_icache/dut/WOFFSET
add wave -noupdate -group PARAMS /tb_icache/dut/TAG_SIZE
add wave -noupdate -radix hexadecimal /tb_icache/dut/clk_i
add wave -noupdate -radix hexadecimal /tb_icache/dut/rst_ni
add wave -noupdate -radix hexadecimal /tb_icache/dut/flush_i
add wave -noupdate -radix hexadecimal -childformat {{/tb_icache/dut/cache_req_i.valid -radix hexadecimal} {/tb_icache/dut/cache_req_i.ready -radix hexadecimal} {/tb_icache/dut/cache_req_i.addr -radix hexadecimal} {/tb_icache/dut/cache_req_i.uncached -radix hexadecimal}} -expand -subitemconfig {/tb_icache/dut/cache_req_i.valid {-height 18 -radix hexadecimal} /tb_icache/dut/cache_req_i.ready {-height 18 -radix hexadecimal} /tb_icache/dut/cache_req_i.addr {-height 18 -radix hexadecimal} /tb_icache/dut/cache_req_i.uncached {-height 18 -radix hexadecimal}} /tb_icache/dut/cache_req_i
add wave -noupdate -radix hexadecimal -childformat {{/tb_icache/dut/cache_res_o.valid -radix hexadecimal} {/tb_icache/dut/cache_res_o.ready -radix hexadecimal} {/tb_icache/dut/cache_res_o.miss -radix hexadecimal} {/tb_icache/dut/cache_res_o.blk -radix hexadecimal}} -expand -subitemconfig {/tb_icache/dut/cache_res_o.valid {-height 18 -radix hexadecimal} /tb_icache/dut/cache_res_o.ready {-height 18 -radix hexadecimal} /tb_icache/dut/cache_res_o.miss {-height 18 -radix hexadecimal} /tb_icache/dut/cache_res_o.blk {-height 18 -radix hexadecimal}} /tb_icache/dut/cache_res_o
add wave -noupdate -radix hexadecimal /tb_icache/dut/lowX_res_i
add wave -noupdate -radix hexadecimal /tb_icache/dut/lowX_req_o
add wave -noupdate -radix hexadecimal /tb_icache/dut/flush
add wave -noupdate -radix hexadecimal /tb_icache/dut/flush_index
add wave -noupdate -radix hexadecimal /tb_icache/dut/cache_req_q
add wave -noupdate -radix hexadecimal /tb_icache/dut/rd_idx
add wave -noupdate -radix hexadecimal /tb_icache/dut/wr_idx
add wave -noupdate -radix hexadecimal /tb_icache/dut/cache_idx
add wave -noupdate -radix hexadecimal /tb_icache/dut/cache_miss
add wave -noupdate -radix hexadecimal /tb_icache/dut/cache_hit
add wave -noupdate -radix hexadecimal /tb_icache/dut/cache_wr_en
add wave -noupdate -radix hexadecimal /tb_icache/dut/evict_way
add wave -noupdate -radix hexadecimal /tb_icache/dut/cache_valid_vec
add wave -noupdate -radix hexadecimal /tb_icache/dut/cache_hit_vec
add wave -noupdate -radix hexadecimal /tb_icache/dut/updated_node
add wave -noupdate -radix hexadecimal /tb_icache/dut/cache_select_data
add wave -noupdate -radix hexadecimal /tb_icache/dut/dsram
add wave -noupdate -radix hexadecimal /tb_icache/dut/tsram
add wave -noupdate -radix hexadecimal /tb_icache/dut/nsram
add wave -noupdate /tb_icache/dut/lookup_ack
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {39907 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {66175 ps} {139675 ps}
