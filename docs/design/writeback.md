# Writeback Stage Documentation

The **Writeback Stage** in the TCore RISC-V Processor finalizes the execution of instructions by writing results back to the register file or preparing data for further processing. It is the last stage in the pipeline, ensuring that computation results are stored correctly for subsequent use.

## Key Functionalities

1. **Result Selection**:
   - Determines the source of data to be written back to the register file.
   - Handles different data sources, such as ALU results, memory data, or program counter increments.

2. **Register Writeback**:
   - Writes the selected data to the destination register in the register file.
   - Ensures that write operations are disabled during pipeline stalls to prevent corruption.

---

## Module Composition

### 1. **Result Multiplexer**
- **Functionality**: Selects the appropriate result to write back based on control signals.
- **Inputs**:
  - `data_sel_i`: Control signal for selecting the data source.
  - `alu_result_i`: Result from the Execute stage.
  - `read_data_i`: Data loaded from memory.
  - `pc2_i`, `pc4_i`: Incremented program counter values.
  - `is_comp_i`: Indicates compressed instruction format.
- **Outputs**:
  - `wb_data_o`: Final writeback data.
