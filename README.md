# 🚀 TCORE: A Simple RISC-V Core

TCORE is a lightweight, high-performance RISC-V core supporting the **RV32IMC_Zicsr_Zifencei** instruction set. Initially developed as an experimental project, TCORE has now reached its final stage and **will no longer be actively developed**. 

It is written in **SystemVerilog**, with a particular focus on a **configurable memory system**, **efficient pipeline structure**, and **parametric design logic**. Despite its simplicity, TCORE successfully passes official **RISC-V compliance tests** and features a fast **Wallace Tree multiplier** for enhanced arithmetic operations.

---

## ✨ Features
- ✅ **ISA Support:** RV32IMC with **Zicsr (CSR)** & **Zifencei (Instruction Fence)**
- ✅ **Level-1 Caches** for improved performance
- ✅ **Gray Align Buffer** for efficient memory alignment
- ✅ **Wallace Tree Multiplier** (32-bit) for high-speed multiplication
- ✅ **Exception Handling Mechanism** with **minimum Machine CSRs** implemented
- ✅ **Branch Prediction Unit** supporting different prediction strategies
- ✅ **UART Interface** for peripheral communication
- ✅ **Fully Passes RISC-V ISA Compliance Tests** (riscv-tests repository)

---

## 🏗️ Architecture Overview
TCORE follows a streamlined **RISC-V microarchitecture**, balancing **efficiency and simplicity**. 

![TCORE CPU Architecture](./docs/CPU.svg)

---

## 🎯 Project Goal Checklist
- ✅ **Branch Predictor Implementation** (Gshare & Forward Always strategies)
- ✅ **Successful Completion of RISC-V Compliance Tests**
- ✅ **Machine Mode CSR Support & Exception Handling**
- ❌ **Comprehensive Documentation (EN/TR)**
- ❌ **Open-Source ASIC Synthesis Initiative**

---

## ⚡ Performance Benchmarks

### 📌 **CoreMark Results**
1000 Iterations at **50 MHz** Clock Frequency:

| Core Configuration   | CoreMark/MHz | Iterations |
|--------------------- |--------------|------------|
| **RV32IMC**          | **2.20**     | **1100**   |


---

## 🛠️ Status: **Project Completed**
TCORE has now reached **its final development stage**. While no further active improvements will be made. 

🔹 **Future Scope?** Open-source ASIC synthesis remains an open challenge, awaiting contributions from the community.  

Feel free to explore, test, or extend TCORE to suit your own RISC-V experiments! 🚀
