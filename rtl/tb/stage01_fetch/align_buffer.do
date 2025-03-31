onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group PARAM -radix hexadecimal /tb_align_buffer/dut/CACHE_SIZE
add wave -noupdate -group PARAM -radix hexadecimal /tb_align_buffer/dut/BLK_SIZE
add wave -noupdate -group PARAM -radix hexadecimal /tb_align_buffer/dut/XLEN
add wave -noupdate -group PARAM -radix hexadecimal /tb_align_buffer/dut/NUM_WAY
add wave -noupdate -group PARAM -radix hexadecimal /tb_align_buffer/dut/DATA_WIDTH
add wave -noupdate -group PARAM -radix hexadecimal /tb_align_buffer/dut/NUM_SET
add wave -noupdate -group PARAM -radix hexadecimal /tb_align_buffer/dut/IDX_WIDTH
add wave -noupdate -group PARAM -radix hexadecimal /tb_align_buffer/dut/BOFFSET
add wave -noupdate -group PARAM -radix hexadecimal /tb_align_buffer/dut/WOFFSET
add wave -noupdate -group PARAM -radix hexadecimal /tb_align_buffer/dut/TAG_SIZE
add wave -noupdate -radix hexadecimal /tb_align_buffer/dut/clk_i
add wave -noupdate -radix hexadecimal /tb_align_buffer/dut/rst_ni
add wave -noupdate -radix hexadecimal /tb_align_buffer/dut/flush_i
add wave -noupdate -radix hexadecimal -childformat {{/tb_align_buffer/dut/buff_req_i.valid -radix hexadecimal} {/tb_align_buffer/dut/buff_req_i.ready -radix hexadecimal} {/tb_align_buffer/dut/buff_req_i.addr -radix hexadecimal} {/tb_align_buffer/dut/buff_req_i.uncached -radix hexadecimal}} -expand -subitemconfig {/tb_align_buffer/dut/buff_req_i.valid {-height 18 -radix hexadecimal} /tb_align_buffer/dut/buff_req_i.ready {-height 18 -radix hexadecimal} /tb_align_buffer/dut/buff_req_i.addr {-height 18 -radix hexadecimal} /tb_align_buffer/dut/buff_req_i.uncached {-height 18 -radix hexadecimal}} /tb_align_buffer/dut/buff_req_i
add wave -noupdate -radix hexadecimal -childformat {{/tb_align_buffer/dut/buff_res_o.valid -radix hexadecimal} {/tb_align_buffer/dut/buff_res_o.ready -radix hexadecimal} {/tb_align_buffer/dut/buff_res_o.blk -radix hexadecimal}} -expand -subitemconfig {/tb_align_buffer/dut/buff_res_o.valid {-radix hexadecimal} /tb_align_buffer/dut/buff_res_o.ready {-radix hexadecimal} /tb_align_buffer/dut/buff_res_o.blk {-radix hexadecimal}} /tb_align_buffer/dut/buff_res_o
add wave -noupdate -radix hexadecimal /tb_align_buffer/dut/buffer_miss_o
add wave -noupdate -radix hexadecimal -childformat {{/tb_align_buffer/dut/lowX_res_i.valid -radix hexadecimal} {/tb_align_buffer/dut/lowX_res_i.ready -radix hexadecimal} {/tb_align_buffer/dut/lowX_res_i.blk -radix hexadecimal}} -expand -subitemconfig {/tb_align_buffer/dut/lowX_res_i.valid {-height 18 -radix hexadecimal} /tb_align_buffer/dut/lowX_res_i.ready {-height 18 -radix hexadecimal} /tb_align_buffer/dut/lowX_res_i.blk {-height 18 -radix hexadecimal}} /tb_align_buffer/dut/lowX_res_i
add wave -noupdate -radix hexadecimal -childformat {{/tb_align_buffer/dut/lowX_req_o.valid -radix hexadecimal} {/tb_align_buffer/dut/lowX_req_o.ready -radix hexadecimal} {/tb_align_buffer/dut/lowX_req_o.addr -radix hexadecimal} {/tb_align_buffer/dut/lowX_req_o.uncached -radix hexadecimal}} -expand -subitemconfig {/tb_align_buffer/dut/lowX_req_o.valid {-height 18 -radix hexadecimal} /tb_align_buffer/dut/lowX_req_o.ready {-height 18 -radix hexadecimal} /tb_align_buffer/dut/lowX_req_o.addr {-height 18 -radix hexadecimal} /tb_align_buffer/dut/lowX_req_o.uncached {-height 18 -radix hexadecimal}} /tb_align_buffer/dut/lowX_req_o
add wave -noupdate -radix hexadecimal /tb_align_buffer/dut/even
add wave -noupdate -radix hexadecimal /tb_align_buffer/dut/odd
add wave -noupdate -radix hexadecimal -childformat {{{/tb_align_buffer/dut/miss_state[1]} -radix hexadecimal} {{/tb_align_buffer/dut/miss_state[0]} -radix hexadecimal}} -subitemconfig {{/tb_align_buffer/dut/miss_state[1]} {-height 18 -radix hexadecimal} {/tb_align_buffer/dut/miss_state[0]} {-height 18 -radix hexadecimal}} /tb_align_buffer/dut/miss_state
add wave -noupdate -radix hexadecimal /tb_align_buffer/dut/hit_state
add wave -noupdate -radix hexadecimal /tb_align_buffer/dut/wr_idx
add wave -noupdate -radix hexadecimal /tb_align_buffer/dut/tag_wr_en
add wave -noupdate -radix hexadecimal /tb_align_buffer/dut/data_wr_en
add wave -noupdate -radix hexadecimal /tb_align_buffer/dut/wr_tag
add wave -noupdate -radix hexadecimal /tb_align_buffer/dut/ebram
add wave -noupdate -radix hexadecimal /tb_align_buffer/dut/obram
add wave -noupdate -radix hexadecimal /tb_align_buffer/dut/tag_ram
add wave -noupdate -radix hexadecimal /tb_align_buffer/dut/word_sel
add wave -noupdate -radix hexadecimal /tb_align_buffer/dut/parcel_idx
add wave -noupdate -radix hexadecimal /tb_align_buffer/dut/overflow
add wave -noupdate -radix hexadecimal /tb_align_buffer/dut/unalign
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {138075 ps} 0}
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
WaveRestoreZoom {0 ps} {273 ns}
