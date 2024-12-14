---
hide:
  - navigation
  - toc
search:
  boost: 2 
---

# Welcome to TCore Documentation

TCore is a RISC-V based processor core implementing the RV32IMC instruction set architecture. It is designed to be simple yet configurable, providing a flexible foundation for educational, experimental, and lightweight embedded applications. This documentation will guide you through understanding, configuring, and using TCore effectively.

## Key Features

- **RISC-V RV32IMC ISA**: Supports integer, multiplication/division, and compressed instructions.
- **Configurable Memory System**: Optimized for various embedded applications.
- **Pipeline Design**: Focused on efficient data processing.
- **UART Support**: For communication and debugging.
- **FPGA Friendly**: Designed with FPGA implementation in mind.

## Future Goals

- Adding a branch predictor for performance optimization.
- Achieving compatibility with official RISC-V International test suites.
- Implementing machine mode CSR (Control and Status Registers).
- Providing documentation in both English and Turkish.
- Supporting open-source ASIC synthesis for low-cost custom designs.

## Performance Highlights

- **Core Configurations**: Available for RV32I, RV32IC, and RV32IMC.
- **CoreMark/MHz**: 2.20 for RV32IMC configuration.
- **Branch Prediction Accuracy**: Implements gshare with an 85% accuracy rate.

## Learn More

Visit the [GitHub repository](https://github.com/kerimturak/tcore-rv32imc) for the source code, implementation details, and contribution guidelines. This documentation will be continually updated as TCore evolves to meet its development goals.
