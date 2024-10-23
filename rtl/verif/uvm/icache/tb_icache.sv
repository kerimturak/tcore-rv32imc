`timescale 1ns / 1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
import tcore_param::*;

class transaction extends uvm_sequence_item;
    rand  icache_req_t cache_req_i;
    icache_res_t cache_res_o;
    bit        icache_miss_o;
    rand  ilowX_res_t  lowX_res_i;
    ilowX_req_t  lowX_req_o;

  function new(input string path = "transaction");
    super.new(path);
  endfunction

`uvm_object_utils_begin(transaction)
`uvm_field_int(cache_req_i, UVM_DEFAULT)
`uvm_field_int(cache_res_o, UVM_DEFAULT)
`uvm_field_int(icache_miss_o, UVM_DEFAULT)
`uvm_field_int(lowX_res_i, UVM_DEFAULT)
`uvm_field_int(lowX_req_o, UVM_DEFAULT)
`uvm_object_utils_end

endclass

class generator extends uvm_sequence #(transaction);
`uvm_object_utils(generator)

  transaction t;

  function new(input string path = "generator");
    super.new(path);
  endfunction

  virtual task body();
  t = transaction::type_id::create("t");
  repeat(3) begin
      start_item(t);
      t.randomize();
      finish_item(t);
  end
  endtask
endclass

  class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver)
  
      function new(input string path = "driver", uvm_component parent = null);
        super.new(path, parent);
      endfunction

      transaction tc;
      virtual icache_if vif;

      virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tc = transaction::type_id::create("tc");
          if(!uvm_config_db #(virtual icache_if)::get(this,"","vif",vif)) 
      `uvm_error("DRV","Unable to access uvm_config_db");
      endfunction

      virtual task run_phase(uvm_phase phase);
      forever begin
  
    seq_item_port.get_next_item(tc);
        vif.cache_req_i <= tc.cache_req_i;
        vif.lowX_res_i  <= tc.lowX_res_i ;
     // `uvm_info("DRV", $sformatf("Trigger DUT a: %0d ,b :  %0d",tc.a, tc.b), UVM_NONE); 
    seq_item_port.item_done();
    #10;  
      end
      endtask
  endclass



class monitor extends uvm_monitor;
`uvm_component_utils(monitor)
 
uvm_analysis_port #(transaction) send;
 
  function new(input string path = "monitor", uvm_component parent = null);
    super.new(path, parent);
    send = new("send", this);
  endfunction
 
  transaction t;
  virtual icache_if vif;
 
  virtual function void build_phase(uvm_phase phase);
   super.build_phase(phase);
    t = transaction::type_id::create("t");
    
   if(!uvm_config_db #(virtual icache_if)::get(this,"","vif",vif)) 
   `uvm_error("MON","Unable to access uvm_config_db");
  endfunction
 
    virtual task run_phase(uvm_phase phase);
    forever begin
    #10;
    t.cache_req_i <= vif.cache_req_i;
    t.lowX_res_i  <= vif.lowX_res_i ;
    //`uvm_info("MON", $sformatf("Data send to Scoreboard a : %0d , b : %0d and y : %0d", t.a,t.b,t.y), UVM_NONE);
    send.write(t);
    end
    endtask
endclass

class scoreboard extends uvm_scoreboard;
`uvm_component_utils(scoreboard)
 
uvm_analysis_imp #(transaction,scoreboard) recv;
 
transaction tr;
 
  function new(input string path = "scoreboard", uvm_component parent = null);
    super.new(path, parent);
    recv = new("recv", this);
  endfunction
 
  virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
    tr = transaction::type_id::create("tr");
  endfunction
 
  virtual function void write(input transaction t);
   tr = t;
  //`uvm_info("SCO",$sformatf("Data rcvd from Monitor a: %0d , b : %0d and y : %0d",tr.a,tr.b,tr.y), UVM_NONE);
  
    if(tr.cache_res_o == tr.lowX_res_i)
       `uvm_info("SCO","Test Passed", UVM_NONE)
   else
       `uvm_info("SCO","Test Failed", UVM_NONE);
   endfunction
endclass



class agent extends uvm_agent;
`uvm_component_utils(agent)
 
 
function new(input string inst = "AGENT", uvm_component c);
super.new(inst, c);
endfunction
 
monitor m;
driver d;
uvm_sequencer #(transaction) seqr;
 
 
virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
  m = monitor::type_id::create("m",this);
  d = driver::type_id::create("d",this);
  seqr = uvm_sequencer #(transaction)::type_id::create("seqr",this);
endfunction
 
 
virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
  d.seq_item_port.connect(seqr.seq_item_export);
endfunction
endclass


class env extends uvm_env;
`uvm_component_utils(env)
 
 
function new(input string inst = "ENV", uvm_component c);
super.new(inst, c);
endfunction
 
scoreboard s;
agent a;
 
virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
  s = scoreboard::type_id::create("s",this);
  a = agent::type_id::create("a",this);
endfunction
 
 
virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
a.m.send.connect(s.recv);
endfunction
 
endclass



class test extends uvm_test;
`uvm_component_utils(test)
 
 
function new(input string inst = "TEST", uvm_component c);
super.new(inst, c);
endfunction
 
generator gen;
env e;
 
virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
  gen = generator::type_id::create("gen");
  e = env::type_id::create("e",this);
endfunction
 
virtual task run_phase(uvm_phase phase);
   phase.raise_objection(this);
   gen.start(e.a.seqr);
   #50;
   phase.drop_objection(this);
endtask
endclass


module tb_icache();

  icache_if vif();

    icache tb_icache(
    .clk_i(vif.clk_i),
    .rst_ni(vif.rst_ni),
    .cache_req_i(vif.cache_req_i),
    .cache_res_o(vif.cache_res_o),
    .icache_miss_o(vif.icache_miss_o),
    .lowX_res_i(vif.lowX_res_i),
    .lowX_req_o(vif.lowX_req_o)
);

initial begin
  vif.clk_i = 0;
  vif.rst_ni = 1;
end  
  
  always #10 vif.clk_i = ~vif.clk_i;

initial begin  
  uvm_config_db #(virtual icache_if)::set(null, "uvm_test_top.e.a*", "vif", vif);
  run_test("test");
end
endmodule