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
- [X] Add branch predictor
- [] Pass the official RISC-V International tests
- [] Machine mode csr support
- [] Documentation page EN/TR
- [] OpenSource ASIC Synthesis


# Score

## CoreMark
1000 Iterations at 50 MHz

| Core Configuration   | CoreMark/MHz | Iteration |
|--------------------- |--------------|--------------|
| RV32I                | 0.82         | 1000         |
| RV32IC               | 0.82         | 1000         |
| RV32IMC              | 2.20         | 1100         |

## Branch Prediction

| Type   | 	Accuracy |
|--------------------- |--------------|
| Forward always backward never                | 0.79         |
| Gshare               | 0.85         |

