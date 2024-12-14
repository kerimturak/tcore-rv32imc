# Execution Stage Documentation

The **Execution Stage** in the TCore RISC-V Processor performs arithmetic and logical operations, branching decisions, and other computations required for instruction execution. This stage is central to the processor's operation, as it produces results based on decoded instructions.

## Key Functionalities

1. **Arithmetic and Logical Operations**:
   - Executes operations like addition, subtraction, bitwise logic, shifts, and comparisons using the ALU.

2. **Multiplication and Division**:
   - Supports both single-cycle and multi-cycle implementations for multiplication and division.
   - Handles signed and unsigned integer operations.

3. **Branch Evaluation**:
   - Determines the outcome of branch instructions.
   - Calculates target addresses for jumps and branches.

4. **Pipeline Integration**:
   - Generates output data and control signals to be passed to subsequent pipeline stages.

---

## Module Composition

### 1. **Arithmetic Logic Unit (ALU)**
- **Functionality**: Executes arithmetic, logical, and shift operations.

### 2. **Multiplier and Divider**
- **Functionality**: Executes multiplication and division operations.
  - `alu_stall_o`: Indicates ongoing multi-cycle operations.

### Status Flags
- `zero_o`: Indicates if the result is zero.
- `slt_o`: Set if the first operand is less than the second (signed).
- `sltu_o`: Set if the first operand is less than the second (unsigned).
