# Processor Core: TCore Introduction

![alt text](../CPU.svg)

TCore is a custom RISC-V processor core supporting the RV32I, M, and C extensions. Designed with a balance of simplicity and flexibility, TCore offers unique features tailored to address common challenges in processor design. Below is a detailed introduction to its architecture and capabilities:

## Key Features and Innovations

- **Parametric Cache Design**:
  TCore features fully parametric and straightforward caches. To address alignment issues with compressed instructions, a Gray buffer system inspired by Gray’s Cache architecture has been integrated.

- **Branch Prediction**:
  Both static and dynamic branch prediction options are available as configurable parameters. This provides flexibility based on performance requirements and use cases.

- **Pipeline Design**:
  TCore utilizes a 5-stage pipeline. Register files operate on the positive clock edge, enabling 3-stage data forwarding from Writeback, Memory, and Decode stages. This setup efficiently resolves data dependencies.

- **Multiplication Algorithms**:
  The ALU supports multiple multiplication algorithms, including Wallace and Dadda trees, configurable via parameters. These algorithms are generated using a higher-level language, C++, for improved maintainability. Additionally, sequential multiplication is available as an alternative for specific use cases.

- **Division Algorithm**:
  A classic long division approach is implemented. Larger multipliers required for optimized cycle count have been excluded to maintain simplicity and resource efficiency.

## Memory and Peripheral Access

- **Memory Stage**:
  The Memory stage handles both data cache operations and peripheral access. A simple PMA (Physical Memory Attributes) module, as specified in the RISC-V spec, has been implemented for peripheral handling.

- **Peripheral Communication**:
  Currently, the system does not utilize a bus for peripheral communication. However, future updates may introduce bus integration. The sole peripheral supported at this stage is a UART, with plans to expand support to additional peripherals in future revisions.

- **Writeback Stage**:
  The Writeback stage is optional and can be parametrically included or excluded based on design requirements.

## Advanced Features

- **Return Address Stack (RAS)**:
  A RISC-V compliant RAS structure has been implemented to enhance performance.

- **Cache Hierarchy**:
  While Level 1 caches are currently implemented, the data cache has been designed with Level 2 compatibility in mind for future scalability.

---

This introduction outlines TCore's innovative approach to processor design, balancing RISC-V compliance with custom enhancements. For more details, visit the [GitHub repository](https://github.com/kerimturak/tcore-rv32imc).
