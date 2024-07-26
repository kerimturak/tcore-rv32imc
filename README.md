# Overview
TCORE is a simple core project based on the RISC-V architecture, supporting the RV32IMC ISA. As it is currently in the development stage, it may contain quite a few bugs. It is written in SystemVerilog HDL, with a particular focus on a configurable memory system and parametric coding logic.
# Features
- Base RISC-V ISA: I-M, C extensions
- Level-1 caches
- Gray Align Buffer
- Slow multiplication and division
- UART
# Architecture
![alt text](./doc/CPU.svg)


# Goal Checklist
- [] Scripts to automate processes
- [] Pass the official RISC-V International tests
- [] Add formal verification
- [] Add branch predictor
- [] Full custimazable
- [] Machine mode csr support
- [] Documentation page EN/TR
- [] Supported ISA Configuration
- [] OpenSource ASIC Synthesis


# Score
1000 Iterations at 50 MHz

| Core Configuration   | CoreMark/MHz |
|---------------------|--------------|
| RV32I               | 0.74         |
| RV32IC              | 0.76         |
| RV32IMC             | 1.10         |

