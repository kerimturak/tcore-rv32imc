# Memory Stage Documentation

The **Memory Stage** in the TCore RISC-V Processor handles interactions with memory and peripherals, including data reads and writes. It integrates cache mechanisms and memory-mapped I/O to support efficient and accurate data operations.

## Key Functionalities

1. **Memory Access**:
   - Handles read and write requests for data memory.
   - Supports different data sizes (byte, halfword, word) with sign extension for loads.

2. **Data Cache Integration**:
   - Implements a write-back, fully configurable data cache to reduce memory latency.
   - Handles cache misses and manages data consistency with lower-level memory.

3. **Peripheral Access**:
   - Supports memory-mapped I/O for peripherals like UART.

4. **Pipeline Integration**:
   - Interfaces with the Execute and Writeback stages to ensure correct data flow.

---

## Module Composition

### 1. **Data Cache**
- **Functionality**: Caches data for faster memory access.
- **Features**:
  - Write-back policy to reduce write latency.
  - Configurable size and associativity.
  - Replacement policies managed via PLRU.

### 2. **Peripheral Interface**
- **Functionality**: Interfaces with memory-mapped peripherals (e.g., UART).

### 3. **Address Permissions**
- **Functionality**: Determines memory regions and permissions.

---

### Memory Access Logic
- **Read Handling**:
  - Supports byte, halfword, and word accesses.
  - Handles sign extension for load instructions.
- **Write Handling**:
  - Manages write data alignment based on address and data size.
- **Cache Miss Handling**:
  - Requests data from lower-level memory on a cache miss.

### Peripheral Access Logic
- Integrates with peripherals using memory-mapped addresses.
- Controls UART operations for communication.

---