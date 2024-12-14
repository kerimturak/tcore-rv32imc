# Decode Stage Documentation

The **Decode Stage** in the TCore RISC-V Processor is a critical component responsible for interpreting instructions, extracting operands, and generating control signals. This stage bridges the gap between instruction fetching and execution, ensuring that instructions are properly decoded and prepared for execution.

## Key Functionalities

1. **Instruction Decoding**:
   - Interprets the opcode, function fields (`funct3`, `funct7`), and other instruction components to determine the operation type and required actions.

2. **Operand Fetching**:
   - Retrieves source operands (`rs1`, `rs2`) from the register file.
   - Supports data forwarding from writeback to resolve dependencies.

3. **Immediate Extraction**:
   - Generates immediate values based on instruction type (e.g., I-type, S-type, B-type).

4. **Control Signal Generation**:
   - Produces control signals required by subsequent pipeline stages (e.g., ALU control, memory access, writeback control).

---

## Module Composition

### 1. **Register File**
- **Functionality**: Stores and provides access to 32 general-purpose registers.

### 2. **Control Unit**
- **Functionality**: Decodes the opcode and function fields to generate control signals.

### 3. **Immediate Extension Unit**
- **Functionality**: Extracts and extends immediate values based on instruction type.


## Internal Signals and Logic

### Forwarding Logic
- **Inputs**:
  - `fwd_a_i`, `fwd_b_i`: Forwarding enable signals for source operands.
  - `wb_data_i`: Data forwarded from writeback.
- **Outputs**:
  - `r1_data_o`, `r2_data_o`: Final source operands after forwarding.

### Control Signals
- `alu_in1_sel`, `alu_in2_sel`: Select ALU inputs.
- `result_src`: Determines the source of the writeback result.
- `imm_sel`: Specifies the type of immediate to generate.
- `pc_sel`: Selects the next PC value.
- `rf_rw_en`, `wr_en`: Enables register file read/write operations.