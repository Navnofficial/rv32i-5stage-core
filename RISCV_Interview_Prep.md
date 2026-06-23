# 🎯 RV32I 5-Stage Pipeline — Complete Interview Prep Guide

> **Your project:** A 5-stage in-order pipelined RISC-V (RV32I subset) processor written in Verilog, simulated with Icarus Verilog + GTKWave. It handles data forwarding (EX-MEM and MEM-WB forwarding), control hazards (branch flush), and has a hazard unit with load-use stall detection.

---

## 📋 Table of Contents

1. [The Big Picture — What You Built](#1-the-big-picture)
2. [RISC-V ISA Fundamentals](#2-risc-v-isa-fundamentals)
3. [Instruction Encoding Formats](#3-instruction-encoding-formats)
4. [The 5 Pipeline Stages — Deep Dive](#4-the-5-pipeline-stages)
5. [Pipeline Registers & Signal Flow](#5-pipeline-registers--signal-flow)
6. [Control Unit — Main & ALU Decoder](#6-control-unit--main--alu-decoder)
7. [ALU Design](#7-alu-design)
8. [Hazard Handling (The Hardest Part)](#8-hazard-handling)
9. [Data Memory & Register File](#9-data-memory--register-file)
10. [Verification & Testbench](#10-verification--testbench)
11. [Known Limitations & Design Decisions](#11-known-limitations--design-decisions)
12. [Expected Interview Q&A — 60+ Questions](#12-expected-interview-qa)

---

## 1. The Big Picture

### What You Built in One Sentence
> *"I designed and verified a 5-stage in-order pipelined RISC-V processor in Verilog, supporting a subset of the RV32I ISA, with full data forwarding to resolve RAW hazards and branch flush for control hazards."*

### Architecture Summary

```
  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
  │  FETCH   │───▶│  DECODE  │───▶│ EXECUTE  │───▶│  MEMORY  │───▶│  WRITE   │
  │   (IF)   │    │   (ID)   │    │   (EX)   │    │  (MEM)   │    │  BACK    │
  │          │    │          │    │          │    │          │    │  (WB)    │
  └──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
       │               │               │                │               │
    IF/ID Reg       ID/EX Reg       EX/MEM Reg       MEM/WB Reg    Reg File Write
       
  ◄─────────────────── Forwarding Paths (MEM→EX, WB→EX) ──────────────────────
  ◄────────────────── Branch Flush (EX flushes IF and ID) ─────────────────────
```

**Key Files:**
| File | Role |
|------|------|
| `Pipeline_Full.v` / `Pipeline_Top.v` | Top-level wiring of all 5 stages |
| `Fetch_Cycle.v` | IF stage + IF/ID pipeline register |
| `Decode_Cycle.v` | ID stage + ID/EX pipeline register |
| `Execute_Cycle.v` | EX stage + EX/MEM pipeline register |
| `Memory_Cycle.v` | MEM stage + MEM/WB pipeline register |
| `Write_Back_Cycle.v` | WB stage (purely combinational) |
| `Hazard_unit.v` | Forwarding signals + load-use stall |
| `Main_Decoder.v` | Opcode → coarse control signals |
| `ALU_Decoder.v` | funct3/funct7 → ALUControl |
| `Sign_Extend.v` | All 5 immediate formats |
| `ALU.v` | 10-operation arithmetic/logic unit |

---

## 2. RISC-V ISA Fundamentals

### Why RISC-V?
- **Open standard** — no licensing fees, academia/industry use it freely.
- **RISC philosophy** — fixed 32-bit instruction width, load-store architecture (only `lw`/`sw` touch memory, all others use registers).
- **RV32I** = the base integer ISA, 32-bit registers, 32 general-purpose registers (x0–x31), where **x0 is always hardwired to 0**.

### The 32 Registers

| Register | ABI Name | Role |
|----------|----------|------|
| x0 | zero | Always 0, writes ignored |
| x1 | ra | Return address |
| x2 | sp | Stack pointer |
| x5–x7 | t0–t2 | Temporaries |
| x8 | s0/fp | Saved reg / frame pointer |
| x10–x17 | a0–a7 | Function arguments & return values |
| x18–x27 | s2–s11 | Saved registers (callee-saved) |
| x28–x31 | t3–t6 | Temporaries |

### Load-Store Architecture
- **Only `lw`/`sw`/`lb`/`sb`/`lh`/`sh`** access data memory.
- All ALU operations (`add`, `sub`, `and`, etc.) work exclusively on registers.
- This simplifies the pipeline: memory access is isolated to the MEM stage.

---

## 3. Instruction Encoding Formats

All RV32I instructions are exactly **32 bits wide**. There are 6 formats:

### R-Type (Register-Register operations)
```
 31      25 24   20 19   15 14  12 11    7 6      0
┌──────────┬───────┬───────┬──────┬───────┬───────┐
│  funct7  │  rs2  │  rs1  │funct3│   rd  │opcode │
│  [31:25] │[24:20]│[19:15]│[14:12]│[11:7]│ [6:0] │
└──────────┴───────┴───────┴──────┴───────┴───────┘
  7 bits    5 bits  5 bits  3 bits  5 bits  7 bits
```
**Used for:** `add`, `sub`, `and`, `or`, `xor`, `slt`, `sltu`, `sll`, `srl`, `sra`

**In your code (Decode_Cycle.v):**
- `rs1` → `InstrD[19:15]` → Register file read port A1
- `rs2` → `InstrD[24:20]` → Register file read port A2
- `rd`  → `InstrD[11:7]`  → Destination register

### I-Type (Immediate + ALU / Load)
```
 31          20 19   15 14  12 11    7 6      0
┌─────────────┬───────┬──────┬───────┬───────┐
│   imm[11:0] │  rs1  │funct3│   rd  │opcode │
└─────────────┴───────┴──────┴───────┴───────┘
   12 bits      5 bits  3 bits  5 bits  7 bits
```
**Used for:** `addi`, `lw`, `jalr`, `andi`, `ori`, `xori`, `slti`, `sltiu`, shifts  
**Sign extension:** `{{20{In[31]}}, In[31:20]}` — top bit replicated 20 times

### S-Type (Store)
```
 31      25 24   20 19   15 14  12 11    7 6      0
┌──────────┬───────┬───────┬──────┬───────┬───────┐
│imm[11:5] │  rs2  │  rs1  │funct3│imm[4:0]│opcode│
└──────────┴───────┴───────┴──────┴───────┴───────┘
```
**Why split?** The `rd` field is repurposed for the upper immediate bits.  
**In Sign_Extend.v:** `{{20{In[31]}}, In[31:25], In[11:7]}`

### B-Type (Branch)
```
 31   30    25 24  20 19  15 14 12 11  8  7   6    0
┌──┬─────────┬──────┬──────┬─────┬─────┬──┬───────┐
│im│imm[10:5]│  rs2 │  rs1 │fct3 │im[4:1]│im│opcode│
│[12]        │      │      │     │      │[11]│      │
└──┴─────────┴──────┴──────┴─────┴─────┴──┴───────┘
```
**Why shuffled?** To maximize bit overlap with other formats (hardware sharing).  
**In Sign_Extend.v:** `{{20{In[31]}}, In[7], In[30:25], In[11:8], 1'b0}`  
**Note the appended `1'b0`** — branches always target even addresses (halfword aligned minimum).

### J-Type (JAL)
```
Imm[20|10:1|11|19:12] scrambled across bits [31:12]
```
**In Sign_Extend.v:** `{{12{In[31]}}, In[19:12], In[20], In[30:21], 1'b0}`  
**Range:** ±1 MB from current PC

### U-Type (LUI / AUIPC)
```
 31             12 11    7 6      0
┌────────────────┬───────┬───────┐
│   imm[31:12]   │   rd  │opcode │
└────────────────┴───────┴───────┘
```
**In Sign_Extend.v:** `{In[31:12], 12'b0}` — lower 12 bits zeroed out.

---

## 4. The 5 Pipeline Stages

### Stage 1: Fetch (IF) — `fetch_cycle` module

**What happens:**
1. PC register outputs current PC address (`PCF`).
2. Instruction memory reads `mem[PCF[31:2]]` (word-aligned, ignores bottom 2 bits).
3. PC Adder computes `PCF + 4` → `PCPlus4F`.
4. MUX selects between `PCPlus4F` (sequential) and `PCTargetE` (branch target) based on `PCSrcE`.
5. On clock edge: stores `InstrF`, `PCF`, `PCPlus4F` into IF/ID pipeline register.

**Reset / Flush behavior:**
```verilog
if (rst == 1'b0 || PCSrcE) begin
    InstrF_reg   <= 32'h0000_0000;  // NOP inserted
    PCF_reg      <= 32'h0000_0000;
    PCPlus4F_reg <= 32'h0000_0000;
end
```
> When `PCSrcE=1` (branch taken), the IF/ID register is zeroed — the wrongly-fetched instruction becomes a NOP bubble.

**Key signals coming out of Fetch:**
- `InstrD` — the 32-bit instruction word
- `PCD` — the PC at which this instruction was fetched
- `PCPlus4D` — PC + 4 (used by JAL/JALR to store return address)

---

### Stage 2: Decode (ID) — `decode_cycle` module

**What happens:**
1. **Control Unit** decodes `InstrD[6:0]` (opcode) → generates all control signals.
2. **Register File** reads two source registers: `Rs1=InstrD[19:15]`, `Rs2=InstrD[24:20]`.
3. **Sign Extender** creates 32-bit immediate from instruction bits `[31:7]`.
4. On clock edge: stores control signals + data into ID/EX pipeline register.

**Write-Back hookup (Register File):**
The register file write happens in WB but the decode stage passes the write signals:
```verilog
Register_File Reg_file(
    .WE3(RegWriteW),   // Write enable from WB stage
    .WD3(ResultW),     // Data from WB stage
    .A3(RDW),          // Destination register from WB stage
    .A1(InstrD[19:15]),// Read port 1 = rs1
    .A2(InstrD[24:20]) // Read port 2 = rs2
);
```

**Flush on branch:**
```verilog
if (rst == 1'b0 || PCSrcE) begin
    // All ID/EX registers zeroed → NOP bubble propagates
end
```

---

### Stage 3: Execute (EX) — `execute_cycle` module

**What happens:**
1. **Forwarding MUXes (3:1):** Select `SrcAE` and `SrcBE` from:
   - `00` → Register file output (no hazard)
   - `01` → `ResultW` from WB stage (WB forwarding)
   - `10` → `ALUResultM` from MEM stage (MEM forwarding)
2. **ALUSrc MUX (2:1):** Selects between forwarded `Rs2` and `Imm_Ext_E` as ALU B-operand.
3. **ALU** computes the result using `ALUControl`.
4. **Branch adder:** Computes `PCE + Imm_Ext_E` → `PCTargetE` (branch destination).
5. **Branch decision:** `PCSrcE = ZeroE & BranchE` → if ALU subtraction = 0, branch is taken.
6. On clock edge: stores results into EX/MEM pipeline register.

**Critical signal: `PCSrcE`**
```verilog
assign PCSrcE = ZeroE & BranchE;
```
This single bit triggers:
- PC to jump to `PCTargetE`
- IF/ID register flush (NOP in IF)
- ID/EX register flush (NOP in ID)

---

### Stage 4: Memory (MEM) — `memory_cycle` module

**What happens:**
1. **Data Memory** access:
   - If `MemWriteM=1`: write `WriteDataM` to `mem[ALUResultM[31:2]]`
   - Always: read `mem[ALUResultM[31:2]]` → `ReadDataM`
2. On clock edge: stores results into MEM/WB pipeline register.

**Memory addressing:**
```verilog
mem[A[31:2]] // Word-aligned: bits [1:0] ignored
```
This means only **32-bit word** accesses are supported in the base version. Address must be 4-byte aligned.

---

### Stage 5: Write Back (WB) — `write_back_cycle` module

**What happens (purely combinational — no register!):**
```verilog
Mux WB_mux(
    .a(ALUResultW),  // ALU result (for R-type, I-ALU)
    .b(ReadDataW),   // Memory data (for lw)
    .s(ResultSrcW),  // 0=ALU, 1=Memory
    .c(ResultW)      // → goes back to Register File WD3
);
```
`ResultW` is fed back all the way to:
- Register file write port (WD3)
- Forwarding MUX in EX stage (for WB→EX forwarding)

---

## 5. Pipeline Registers & Signal Flow

### Complete Signal Name Convention

| Suffix | Stage |
|--------|-------|
| `F` | Fetch (combinational, before register) |
| `D` | Decode (output of IF/ID register) |
| `E` | Execute (output of ID/EX register) |
| `M` | Memory (output of EX/MEM register) |
| `W` | Write Back (output of MEM/WB register) |

### Tracing a Signal: `add x3, x1, x2`

| Cycle | Stage | What Happens |
|-------|-------|-------------|
| 1 | IF | Instruction fetched from `mem[PC>>2]` |
| 2 | ID | Opcode decoded, x1 and x2 read from register file, `ALUOp=2'b10`, `RegWrite=1` |
| 3 | EX | ALU computes x1+x2, result in `ALUResultE` |
| 4 | MEM | No memory op, result passes through |
| 5 | WB | `ResultW = ALUResultW` written back to x3 in register file |

---

## 6. Control Unit — Main & ALU Decoder

### Two-Level Decoding

```
        [6:0] opcode
             │
      ┌──────▼───────┐
      │ Main Decoder │  → RegWrite, ALUSrc, MemWrite, ResultSrc, Branch, Jump, ImmSrc, ALUOp
      └──────────────┘
      
        [14:12] funct3
        [31:25] funct7
        [6:0]   opcode
             │
      ┌──────▼──────────┐
      │   ALU Decoder   │  → ALUControl [3:0]
      └─────────────────┘
```

### Main Decoder Truth Table

| Op (binary) | Instruction | RegWrite | ImmSrc | ALUSrc | MemWrite | ResultSrc | Branch | Jump | ALUOp |
|-------------|-------------|----------|--------|--------|----------|-----------|--------|------|-------|
| `0110011` | R-type | 1 | — | 0 | 0 | 00 | 0 | 0 | 10 |
| `0010011` | I-ALU | 1 | 000 | 1 | 0 | 00 | 0 | 0 | 10 |
| `0000011` | Load | 1 | 000 | 1 | 0 | 01 | 0 | 0 | 00 |
| `0100011` | Store | 0 | 001 | 1 | 1 | 00 | 0 | 0 | 00 |
| `1100011` | Branch | 0 | 010 | 0 | 0 | 00 | 1 | 0 | 01 |
| `1101111` | JAL | 1 | 011 | 1 | 0 | 10 | 0 | 1 | 00 |
| `1100111` | JALR | 1 | 000 | 1 | 0 | 10 | 0 | 1 | 00 |
| `0110111` | LUI | 1 | 100 | 1 | 0 | 00 | 0 | 0 | 00 |
| `0010111` | AUIPC | 1 | 100 | 1 | 0 | 00 | 0 | 0 | 00 |

### ALU Decoder Logic

```verilog
assign ALUControl = 
    (ALUOp == 2'b00)                                              ? 4'b0000 : // ADD (lw/sw/lui/jal)
    (ALUOp == 2'b01)                                              ? 4'b0001 : // SUB (branch compare)
    ((ALUOp==2'b10) & (funct3==3'b000) & ({op[5],funct7[5]}==2'b11)) ? 4'b0001 : // SUB
    ((ALUOp==2'b10) & (funct3==3'b000))                          ? 4'b0000 : // ADD/ADDI
    ((ALUOp==2'b10) & (funct3==3'b010))                          ? 4'b0101 : // SLT
    ((ALUOp==2'b10) & (funct3==3'b110))                          ? 4'b0011 : // OR
    ((ALUOp==2'b10) & (funct3==3'b111))                          ? 4'b0010 : // AND
    // ... XOR, SLTU, SLL, SRL, SRA also covered
                                                                    4'b0000 ;
```

**Key insight:** The `{op[5], funct7[5]} == 2'b11` distinguishes `sub` from `add`:
- `add`: `op=0110011`, `funct7=0000000` → `{1,0}=10` → NOT `11` → ADD
- `sub`: `op=0110011`, `funct7=0100000` → `{1,1}=11` → SUB

---

## 7. ALU Design

### Operations

| ALUControl | Operation | Implementation |
|------------|-----------|----------------|
| `0000` | ADD | `A + B` |
| `0001` | SUB | `A + (~B) + 1` (2's complement) |
| `0010` | AND | `A & B` |
| `0011` | OR | `A \| B` |
| `0100` | XOR | `A ^ B` |
| `0101` | SLT | `{31'b0, sign_compare}` |
| `0110` | SLTU | `{31'b0, ~Cout}` |
| `0111` | SLL | `A << B[4:0]` |
| `1000` | SRL | `A >> B[4:0]` |
| `1001` | SRA | `$signed(A) >>> B[4:0]` |

### Status Flags
```verilog
assign Zero     = &(~Result);          // All bits zero → NOR reduction
assign Negative = Result[31];          // MSB = sign bit
assign Carry    = Cout (for ADD/SUB);  // Unsigned overflow
assign OverFlow = signed overflow detection; // Two's complement overflow
```

### SLT Implementation (Important!)
```verilog
assign SLT_result = {{31{1'b0}}, (A[31] ^ B[31]) ? A[31] : Sum[31]};
```
- If signs differ: negative operand is smaller → result is `A[31]`
- If signs same: check subtraction sign bit → `Sum[31]`

### Why SUB uses addition?
`A - B = A + (~B) + 1` — Two's complement negation. Using an adder for both ADD and SUB saves hardware (just one adder, controlled by `ALUControl[0]`).

---

## 8. Hazard Handling

This is the **most interview-critical** section. Know it cold.

### 8.1 — What is a Hazard?
A hazard occurs when an instruction can't execute in its designated pipeline stage because of a dependency on a previous instruction that hasn't finished yet.

**Three types:**
1. **Structural hazard** — two instructions need the same hardware resource simultaneously (not an issue in your design due to separate instruction/data memories).
2. **Data hazard (RAW)** — Read After Write: instruction B needs a value that instruction A hasn't written yet.
3. **Control hazard** — branch decision isn't known until EX, but IF and ID have already fetched/decoded wrong instructions.

---

### 8.2 — Data Hazard Forwarding

#### The Problem
```assembly
add x3, x1, x2   # Writes x3 in WB (cycle 5)
add x4, x3, x5   # Reads x3 in EX (cycle 3) ← STALE VALUE!
```
x3 isn't written until cycle 5, but the second instruction reads it in cycle 3. Without forwarding, it reads the old (wrong) value.

#### The Solution: Forwarding (Bypassing)

Your `hazard_unit.v` detects this and drives 3:1 MUXes in the EX stage:

```verilog
// MEM-to-EX forwarding (higher priority)
assign ForwardAE =
    ((RegWriteM) && (RD_M != 5'h0) && (RD_M == Rs1_E)) ? 2'b10 :
// WB-to-EX forwarding
    ((RegWriteW) && (RD_W != 5'h0) && (RD_W == Rs1_E)) ? 2'b01 :
                                                           2'b00 ;
```

#### Forwarding MUX in Execute Stage
```verilog
Mux3x1 mux_forward_A(
    .a(RD1_E),        // 2'b00: use register file value (no hazard)
    .b(ResultW),      // 2'b01: forward from WB stage
    .c(ALUResultM_In),// 2'b10: forward from MEM stage
    .s(ForwardAE),
    .d(SrcAE)
);
```

#### Why MEM forwarding takes priority over WB?
If `x3` is being written in BOTH MEM (current instruction) and WB (older instruction), we want the **most recent** value → MEM wins.

#### Forwarding Scenarios

| Scenario | Cycles apart | Forward signal | Source |
|----------|-------------|----------------|--------|
| `add x3,..` → immediately `use x3` | 1 cycle | `2'b10` | MEM stage `ALUResultM` |
| `add x3,..` → NOP → `use x3` | 2 cycles | `2'b01` | WB stage `ResultW` |
| `add x3,..` → NOP → NOP → `use x3` | 3+ cycles | `2'b00` | Register file (already written) |

---

### 8.3 — Load-Use Hazard (Stall)

#### The Problem
```assembly
lw  x3, 0(x0)  # Data available AFTER MEM stage (cycle 4)
add x4, x3, x5 # Needs x3 in EX (cycle 3) ← ONE CYCLE TOO EARLY!
```
Forwarding alone can't fix this — the loaded data doesn't exist yet when it's needed.

#### Detection Logic
```verilog
wire lwStall = (ResultSrcE == 2'b01) &&   // EX stage has a load instruction
               ((RD_E == Rs1_D) || (RD_E == Rs2_D));  // destination matches ID's sources
```
`ResultSrcE == 2'b01` identifies a `lw` (load) in EX stage.

#### Solution: Stall + Bubble
```verilog
assign StallF = lwStall;   // Freeze PC (don't advance)
assign StallD = lwStall;   // Freeze IF/ID register (keep same instruction)
assign FlushD = PCSrcE | lwStall;  // Insert NOP into ID/EX register
```

**Stall mechanism:**
1. **PC frozen** → Fetch stage re-fetches the same instruction
2. **IF/ID frozen** → Decode stage holds the same dependent instruction
3. **NOP bubble** → Inserted into EX stage (ID/EX zeroed)
4. **Load completes** → Next cycle, MEM forwarding provides the loaded value

**Timeline with stall:**
```
Cycle:    1     2     3     4     5     6     7
LW:      IF    ID    EX   MEM    WB
ADD:      -    IF    ID  **NOP** EX   MEM    WB
                     ↑ stall ↑    ↑ forward from MEM ↑
```

> [!IMPORTANT]
> The load-use stall is **implemented** in `Hazard_unit.v` with `StallF`, `StallD`, `FlushD` signals. However, the `Pipeline_Full.v` (the older monolithic version) does NOT have these stall ports wired up yet — the newer `Pipeline_Top.v` uses the separate module files where stall is properly connected.

---

### 8.4 — Control Hazard (Branch Flush)

#### The Problem
```assembly
beq x1, x2, target  # Branch decision made in EX (cycle 3)
add x5, x3, x4      # Already in ID (cycle 2) — WRONG instruction!
or  x6, x7, x8      # Already in IF (cycle 1) — WRONG instruction!
```

#### Solution: Flush on Taken Branch
```verilog
assign PCSrcE = ZeroE & BranchE;  // Branch taken signal from EX stage
```
When `PCSrcE=1`:
- **Fetch stage:** IF/ID register zeroed → NOP bubble
- **Decode stage:** ID/EX register zeroed → NOP bubble
- **PC:** jumps to `PCTargetE = PCE + Imm_Ext_E`

**2-cycle branch penalty:**
```
Cycle:    1     2     3     4
BEQ:      IF    ID    EX   MEM
Bad1:      -    IF    ID  [FLUSHED → NOP]
Bad2:      -     -    IF  [FLUSHED → NOP]
Target:    -     -     -    IF  ← correct fetch
```

**Current limitation:** Only `BEQ` supported. Branch is detected by `PCSrcE = ZeroE & BranchE` — only checks Zero flag. All other branches (`BNE`, `BLT`, etc.) require a separate branch comparator.

> [!NOTE]
> This is called **"assume not taken"** branch prediction — the pipeline always fetches sequentially and squashes only if branch is actually taken. It's the simplest strategy.

---

## 9. Data Memory & Register File

### Instruction Memory
```verilog
reg [31:0] mem [1023:0];          // 1024 words × 32 bits = 4 KB
assign RD = mem[A[31:2]];        // Word-addressed: A[1:0] ignored
initial begin
    $readmemh("memfile.hex", mem); // Loads hex program at simulation start
end
```
- **Read:** Combinational (asynchronous) — output available same cycle as address
- **Write:** Not supported (ROM — instruction memory is read-only)
- **Address bits [31:2]:** Since each instruction is 4 bytes, the byte address divided by 4 gives the word index

### Data Memory
```verilog
reg [31:0] mem [1023:0];          // 4 KB RAM
always @ (posedge clk) begin
    if(WE) mem[A[31:2]] <= WD;   // Synchronous write (on clock edge)
end
assign RD = mem[A[31:2]];        // Asynchronous read (combinational)
```
- **Write:** Synchronous (clocked) — `sw` writes on rising clock edge in MEM stage
- **Read:** Asynchronous — `lw` reads combinationally; result captured in MEM/WB register

### Register File
```verilog
reg [31:0] Register [31:0];      // 32 registers × 32 bits
always @ (posedge clk) begin
    if(WE3 & (A3 != 5'b00000))   // x0 is never written!
        Register[A3] <= WD3;
end
assign RD1 = (A1 == 5'b00000) ? 32'd0 : Register[A1]; // x0 always reads 0
assign RD2 = (A2 == 5'b00000) ? 32'd0 : Register[A2];
```
- **Dual-read, single-write**
- **x0 protection:** Write enable checks `A3 != 5'b00000`, reads from x0 return hardwired 0

---

## 10. Verification & Testbench

### Test Program Highlights (from `memfile_notes.txt`)

```assembly
addi x1, x0, 5     # x1 = 5
addi x2, x0, 3     # x2 = 3
add  x3, x1, x2    # x3 = 8  ← Tests R-type + EX-MEM forwarding
sub  x4, x1, x2    # x4 = 2
lui  x5, 0xF       # x5 = 0x0000F000  ← Tests LUI
jal  x15, +12      # x15 = PC+4, jump forward  ← Tests JAL
beq  x1, x1, +12   # Taken branch  ← Tests branch + flush
lw   x27, 0(x0)    # x27 = 8  ← Tests memory load
lw   x29, 0(x0)    # ─┐ Load-use hazard pair
add  x30, x29, x29 # ─┘ x30 = 16  ← Tests stall
jal  x0, 0         # Infinite loop (halt)
```

### Hazard Test Strategy
- **Data forwarding test:** `addi x1`, immediately `add x3, x1, x2` — tests MEM-to-EX forwarding
- **Load-use test:** `lw x29` immediately followed by `add x30, x29, x29` — tests stall + MEM forwarding
- **Branch test:** Canary register `x30` — if branch misfires, it gets overwritten with `99`; final check is `x30 == 16`

### Tools Used
- **Icarus Verilog (iverilog)** — open-source Verilog simulator
- **GTKWave** — waveform viewer for `.vcd` files
- **`$dumpfile` / `$dumpvars`** — Verilog system tasks to generate VCD
- **`$readmemh`** — loads hex program into instruction memory

### Simulation Command
```bash
iverilog -o dump.vvp Pipeline_Top.v Pipeline_Top_tb.v
vvp dump.vvp
gtkwave Pipeline_dump.vcd
```

---

## 11. Known Limitations & Design Decisions

### What's Missing / Why

| Gap | Root Cause | How to Fix |
|-----|-----------|-----------|
| Only `BEQ` branch | `PCSrcE = ZeroE & BranchE` — only checks Zero flag | Add `Branch_Comparator` for all 6 branch types using funct3 |
| No byte/halfword memory | Data memory uses `A[31:2]` (word index only) | Add `funct3`-based byte/halfword read-write logic with masking |
| No shift instructions (in older ALU) | `ALUControl` was only 3 bits originally | Expanded to 4-bit `ALUControl` in updated `ALU.v` |
| No `JAL`/`JALR` in old version | No J-type immediate, no PC mux path | Added in newer `Main_Decoder.v` with `Jump`, `ALUSrcA`, `ResultSrc=2'b10` |
| No `LUI`/`AUIPC` in old version | No U-type immediate | Added with `ALUSrcA=2'b01/10` and U-type in `Sign_Extend.v` |

### Design Decisions Worth Discussing

1. **Why async reset (active-low)?**  
   `negedge rst` → Reset takes effect immediately on falling edge, not waiting for the next clock. Ensures deterministic power-on state.

2. **Why are pipeline registers inside each stage module?**  
   Instead of standalone register modules between stages, each stage module contains its own output registers. This makes the stage self-contained and easier to test individually.

3. **Why use `A[31:2]` for memory addressing?**  
   RV32I uses byte addresses. Since each word is 4 bytes, dividing by 4 (right-shift 2) gives the word index. This is implicit word addressing.

4. **Why does the register file write on the negative clock edge?** *(or positive in your design)*  
   In your design, write is on `posedge clk`. The forwarding paths handle the case where the same cycle has a WB write and an EX read of the same register.

5. **Why MEM forwarding has higher priority than WB forwarding?**  
   If both MEM and WB want to forward to the same EX source register, MEM has the more recent value (from the instruction that executed last). Older WB value is stale relative to MEM.

---

## 12. Expected Interview Q&A

### 🔴 Fundamentals

**Q1: What does "in-order pipeline" mean?**  
**A:** Instructions enter and execute the pipeline in program order. No instruction is allowed to overtake another. This simplifies hazard detection but means one slow instruction can block all subsequent ones.

**Q2: What is the difference between a 1-cycle and 5-stage pipeline in terms of CPI?**  
**A:** In an ideal case with no hazards, both achieve the same throughput — 1 instruction per cycle (CPI=1). However, the pipeline achieves this with 5 instructions in-flight simultaneously, running at a much higher clock frequency. Single-cycle must run at the speed of the slowest instruction.

**Q3: What is the critical path in a single-cycle processor?**  
**A:** The longest combinational path — typically `IF → ID → EX → MEM → WB` all in one cycle. The clock period must accommodate the entire path, often dominated by the memory access time.

**Q4: Why does pipelining not reduce latency for a single instruction?**  
**A:** A single instruction still takes 5 clock cycles (one per stage). Pipelining improves throughput (instructions/sec), not latency. The benefit appears when multiple instructions are in-flight.

---

### 🟡 RISC-V ISA

**Q5: Why is x0 hardwired to zero?**  
**A:** It enables useful pseudo-instructions: `mv x1, x2` = `addi x1, x2, 0`; `nop` = `addi x0, x0, 0`; negation = `sub x1, x0, x2`. Simplifies the ISA without adding special-case hardware for most operations.

**Q6: What is the difference between `slt` and `sltu`?**  
**A:** `slt` treats operands as signed 2's complement integers. `sltu` treats them as unsigned. For example, `0xFFFFFFFF` is -1 in signed and 4294967295 in unsigned — `slt x0 < 0xFFFFFFFF` is TRUE, but `sltu x0 < 0xFFFFFFFF` is also TRUE (0 < very large number).

**Q7: Why are B-type immediate bits scrambled?**  
**A:** To maximize bit-field overlap with other instruction formats. In particular, `rd[4:1]` in B-type maps to `imm[4:1]`, and `rs2` in B-type is in the same position as in R and S types. This reduces routing complexity in hardware.

**Q8: What is the difference between `lw` and `lb`?**  
**A:** `lw` loads a 32-bit word. `lb` loads a single byte (8 bits) and sign-extends it to 32 bits. `lbu` loads a byte and zero-extends. Your current hardware only supports `lw` (word-only memory).

**Q9: How does `lui` work?**  
**A:** "Load Upper Immediate" — places a 20-bit immediate into the upper 20 bits of `rd`, with the lower 12 bits zeroed. Used with `addi` to construct arbitrary 32-bit constants: `lui x1, 0xDEAD; addi x1, x1, 0xBEF` → `x1 = 0xDEADBEF`.

**Q10: What is `auipc` used for?**  
**A:** "Add Upper Immediate to PC" — adds a 20-bit immediate (shifted left 12) to the current PC. Used for PC-relative addressing, enabling position-independent code. The `call` pseudo-instruction uses `auipc` + `jalr`.

---

### 🟡 Pipeline Architecture

**Q11: Why do we need pipeline registers between stages?**  
**A:** Without them, signals from one stage would combinationally propagate into the next stage, creating a single-cycle critical path. Pipeline registers (flip-flops) isolate stages so each can run at its own maximum speed.

**Q12: What signals are stored in the IF/ID register?**  
**A:** `InstrF` (the fetched instruction), `PCF` (the PC), and `PCPlus4F` (PC+4 for return address).

**Q13: How is the PC updated on every cycle?**  
**A:** 
```verilog
always @(posedge clk or negedge rst)
    PC <= PC_Next; // where PC_Next = PCSrcE ? PCTargetE : PCPlus4F
```
The MUX selects between PC+4 (sequential) and the branch target.

**Q14: Why does Write Back have no register (purely combinational)?**  
**A:** WB only selects between ALU result and memory data using a MUX. The actual register file write happens on the clock edge inside the Register File module, not in WB itself. The combinational path just routes the signal.

**Q15: How does the branch target address get computed?**  
**A:** In the Execute stage: `PCTargetE = PCE + Imm_Ext_E`. The `PCE` is the PC that was stored in the ID/EX pipeline register (the PC of the branch instruction itself).

---

### 🔴 Hazard Handling

**Q16: What is a RAW hazard? Give an example from your code.**  
**A:** Read After Write — a later instruction reads a register before an earlier instruction has written to it.  
Example: `add x3, x1, x2` followed immediately by `add x5, x3, x4`. The second instruction needs x3 in EX (cycle 3), but the first writes x3 in WB (cycle 5).

**Q17: Explain your forwarding unit logic.**  
**A:** The hazard unit compares the destination register (`RD_M`, `RD_W`) of instructions in MEM and WB stages against the source registers (`Rs1_E`, `Rs2_E`) of the instruction in EX. When a match is found and the writing instruction has `RegWrite=1`, it drives the 3:1 forwarding MUX to bypass the register file with the forwarded value.

**Q18: Why do you check `RD != 5'h00` in the forwarding conditions?**  
**A:** Writing to x0 is a no-op (x0 is hardwired to 0). If an instruction writes to x0, we should NOT forward that zero — it could override a legitimate non-zero register value that happens to be used by the dependent instruction. This prevents spurious forwarding.

**Q19: What happens during a load-use hazard if you don't stall?**  
**A:** The dependent instruction reads from the forwarding MUX, but the MEM forwarding path isn't ready yet (the load is still in MEM when the dependent instruction is in EX). The MUX selects the old, stale value from the register file → **silent data corruption**.

**Q20: Describe exactly what happens during a load-use stall.**  
**A:**
1. Hazard unit detects: `ResultSrcE == 2'b01` (load in EX) AND `RD_E == Rs1_D || RD_E == Rs2_D`
2. `StallF = 1` → PC register doesn't update → Fetch stage re-fetches the same instruction
3. `StallD = 1` → IF/ID register is frozen → Decode stage holds the same dependent instruction
4. `FlushD = 1` → ID/EX register is zeroed → NOP bubble enters Execute stage
5. Next cycle: Load moves to MEM, dependent instruction is still in ID, bubble is in EX
6. Next cycle after that: Load is in WB, dependent instruction is in EX, MEM forwarding provides the loaded value

**Q21: How many cycles does a taken branch penalty cost?**  
**A:** 2 cycles. The branch decision is made at the end of the Execute stage (cycle 3 for the branch). By then, IF (cycle 1) and ID (cycle 2) have already processed two wrong instructions. Both must be flushed.

**Q22: When is `PCSrcE` asserted?**  
**A:** `PCSrcE = ZeroE & BranchE`. `ZeroE` is the Zero flag from the ALU (result of comparing rs1 and rs2 via subtraction). `BranchE` comes from the ID/EX pipeline register — it was set by the Main Decoder when it detected a B-type opcode.

**Q23: What is the difference between a flush and a stall?**  
**A:** 
- **Flush:** Replace pipeline register contents with zeros/NOPs. Used for branch mispredictions or control hazards. Discards instructions.
- **Stall:** Freeze one or more pipeline registers so the same instruction stays in place. Used for load-use hazards. Does NOT discard instructions.

**Q24: Can forwarding completely eliminate all data hazards?**  
**A:** No. Forwarding can resolve EX-MEM and MEM-WB RAW hazards. But the load-use hazard (lw followed immediately by a dependent instruction) requires a 1-cycle stall because the data physically isn't computed until the end of the MEM stage — one cycle after it's needed.

---

### 🟡 Control & ALU

**Q25: Why is the control unit split into Main Decoder and ALU Decoder?**  
**A:** Clean separation of concerns. The Main Decoder makes coarse decisions based on the opcode alone (does this instruction write a register? access memory? branch?). The ALU Decoder then fine-tunes the ALU operation using funct3 and funct7. This two-level hierarchy is cleaner and more extensible.

**Q26: What does `ALUSrc` control?**  
**A:** The B-operand of the ALU. `ALUSrc=0` → use `Rs2` (register operand, for R-type). `ALUSrc=1` → use sign-extended immediate (for I-type, loads, stores, JAL).

**Q27: What does `ResultSrc` control?**  
**A:** The write-back MUX in the WB stage. `ResultSrc=00` → write ALU result (R-type, I-ALU). `ResultSrc=01` → write memory data (lw). `ResultSrc=10` → write PC+4 (JAL/JALR return address).

**Q28: How does the ALU compute SLT (set less than)?**  
**A:** It subtracts B from A. The result is 1 if A < B (signed), 0 otherwise.  
```verilog
SLT_result = {{31{1'b0}}, (A[31] ^ B[31]) ? A[31] : Sum[31]};
```
If signs differ → A is negative → A < B → result = A[31] (=1).  
If signs same → subtraction sign bit tells us → result = Sum[31].

**Q29: How is subtraction performed using an adder?**  
**A:** By two's complement: `A - B = A + (~B) + 1`. The ALU uses `ALUControl[0]` to choose between `A + B` and `A + (~B) + 1` in a single expression.

**Q30: What does `ImmSrc` do?**  
**A:** It selects which immediate encoding format to use in `Sign_Extend`. `3'b000`=I-type, `3'b001`=S-type, `3'b010`=B-type, `3'b011`=J-type, `3'b100`=U-type. Each format extracts bits differently from the instruction word.

---

### 🟡 Verilog / HDL

**Q31: What is the difference between `reg` and `wire` in Verilog?**  
**A:** `wire` is combinational — it just connects signals. `reg` holds a value and is used inside `always` blocks. A `reg` doesn't necessarily mean a flip-flop — it becomes sequential only if assigned inside a clocked `always` block.

**Q32: What is the difference between blocking (`=`) and non-blocking (`<=`) assignments?**  
**A:** Blocking executes sequentially within the always block (like a software assignment). Non-blocking schedules the assignment to happen at the end of the time step — all right-hand sides are evaluated first, then all left-hand sides are updated. Non-blocking is used for sequential logic (flip-flops) to avoid race conditions.

**Q33: Explain `$readmemh`.**  
**A:** A Verilog system task that reads a hexadecimal file and loads values into a memory array at simulation start. In your design: `$readmemh("memfile.hex", mem)` loads the test program into instruction memory.

**Q34: What is a VCD file?**  
**A:** Value Change Dump — a standard format for recording signal transitions during simulation. Generated by `$dumpvars` in your testbench, then opened with GTKWave for visual waveform analysis.

**Q35: What does `assign c = (s==1'b1) ? b : a;` synthesize to?**  
**A:** A 2:1 multiplexer. In hardware, this becomes a MUX gate. `s` is the select line, `a` and `b` are the data inputs, `c` is the output.

**Q36: Why use `always @(*)` instead of listing sensitivity list?**  
**A:** `@(*)` (or `@*`) automatically includes all signals read inside the block in the sensitivity list. This prevents simulation bugs caused by forgetting to list a signal. For combinational logic, always use `@(*)`.

**Q37: What is a race condition in Verilog simulation?**  
**A:** When two processes update and read the same signal in the same time step, the result depends on simulator scheduling order. Non-blocking assignments (`<=`) prevent this in sequential logic by separating the read phase from the write phase.

---

### 🔴 Design Trade-offs

**Q38: Why is branch resolution done in EX and not ID?**  
**A:** To compute the branch target, you need `PCE + sign_extended_immediate` — which requires the sign extender (in ID) results to propagate to the adder. More importantly, the comparison (ZeroE) requires the ALU, which is in EX. Moving branch resolution to ID would require adding a separate early comparator in ID, which is exactly what branch predictors and more advanced pipelines do.

**Q39: What would you change to support all 6 branch types?**  
**A:** Add a `Branch_Comparator` module in the EX stage that takes `SrcAE`, `SrcBE`, and `BranchTypeE` (from funct3), and outputs the correct branch condition instead of just `ZeroE`. Change `PCSrcE = BranchTaken & BranchE` where `BranchTaken` comes from the comparator.

**Q40: What is the cost of the 2-cycle branch penalty on CPI?**  
**A:** `CPI = 1 + (branch_frequency × 2)`. If 20% of instructions are taken branches: `CPI = 1 + 0.2 × 2 = 1.4`. This is why branch prediction matters — modern processors predict branches to reduce this penalty.

**Q41: How would you implement a branch predictor to reduce the 2-cycle penalty?**  
**A:** A simple "always predict not-taken" (your current approach) costs 2 cycles when wrong. A 1-bit predictor uses a register per branch instruction to remember if it was taken last time — reduces misprediction on loops. A 2-bit predictor uses 2-bit saturating counters — more hysteresis, better accuracy.

**Q42: Why is instruction memory separate from data memory (Harvard Architecture)?**  
**A:** Allows simultaneous read from instruction memory (IF stage) and read/write to data memory (MEM stage) in the same clock cycle. A single memory (von Neumann) would create a structural hazard — IF and MEM would compete for the same memory port.

**Q43: What would break if you removed the pipeline registers?**  
**A:** The design would collapse to a single-cycle processor. All combinational logic would create a massive critical path from IF through WB, forcing a very slow clock. Also, multiple instructions can't be in-flight simultaneously.

**Q44: Your register file writes on `posedge clk`. When is the written value available for reading?**  
**A:** The value appears at the read outputs in the NEXT clock cycle (since writes are synchronous). Within the same cycle, a read of the just-written register returns the OLD value. This is handled by forwarding (WB forwarding in the hazard unit provides the new value).

---

### 🔴 Specific Code Questions

**Q45: Walk me through what happens when `lw x3, 4(x0)` executes.**  
**A:**
1. **IF:** Fetch `0000011` opcode instruction from I-Memory
2. **ID:** Main Decoder: `RegWrite=1, ALUSrc=1, MemWrite=0, ResultSrc=01, Branch=0, ALUOp=00`. Register file reads x0 (=0). Sign extender produces `0x00000004` (I-type immediate).
3. **EX:** ALU computes `0 + 4 = 4` (address). `PCSrcE=0`. ALU control = `0000` (ADD) because `ALUOp=2'b00`.
4. **MEM:** Data memory reads `mem[4>>2] = mem[1]`. `ReadDataM` = memory contents.
5. **WB:** `ResultSrcW=01` → MUX selects `ReadDataW`. Writes to x3 in register file.

**Q46: How does your design handle the instruction `addi x0, x0, 0` (NOP)?**  
**A:** The register file write enable is `WE3 = RegWriteW = 1` (addi writes), but `A3 = x0`. The write is guarded: `if(WE3 & (A3 != 5'b00000))` — the condition fails, so nothing is written. The instruction simply passes through all stages doing no observable work.

**Q47: What value does `Sign_Extend` output for B-type instruction `beq x1, x2, -4`?**  
**A:** The offset -4 in B-type encoding:  
-4 in binary (13-bit signed, since B-type has 13-bit range) = `1 1111111100`  
Bits: `imm[12]=1, imm[11]=1, imm[10:5]=111111, imm[4:1]=1100, imm[0]=0(implicit)`  
Sign extended to 32 bits: `0xFFFFFFFC` (-4 in two's complement)

**Q48: In the forwarding unit, what is the condition when BOTH `RegWriteM` and `RegWriteW` are true, and both `RD_M` and `RD_W` equal `Rs1_E`?**  
**A:** MEM forwarding wins because MEM has the MORE RECENT value. The priority is: MEM > WB > register file. The ternary chain checks MEM first.

**Q49: What does the `Adder` module used for branch target computation receive as inputs?**  
**A:** `a = PCE` (the PC of the branch instruction, passed through the ID/EX register) and `b = Imm_Ext_E` (the sign-extended B-type immediate, also from ID/EX register). Output is `PCTargetE = PCE + Imm_Ext_E`.

**Q50: Why is `WriteDataE_reg <= SrcBE_interim` and not `SrcBE` (the post-ALUSrc-MUX value)?**  
**A:** For a `sw` instruction, `SrcBE_interim` is the forwarded register value (Rs2 after forwarding MUX, before the ALUSrc MUX selects the immediate). This is the DATA to be stored. `SrcBE` (post-MUX) would be the immediate — which is the ADDRESS offset, not the data. We want to store the register content, not the immediate.

---

### 🟡 Performance

**Q51: What is ideal CPI and when is it achieved?**  
**A:** CPI = 1.0 when there are no hazards. Every cycle, one instruction completes. This is achieved when instructions have no data dependencies within 1-2 cycles and no taken branches.

**Q52: What is the CPI for a program with 30% taken branches?**  
**A:** `CPI = 1 + 0.30 × 2 = 1.6` (each taken branch costs 2 flush cycles).

**Q53: What would `lw x3, 0(x0)` followed immediately by `add x4, x3, x5` give for CPI for those two instructions?**  
**A:** 3 cycles for 2 instructions = CPI of 1.5 (one stall cycle added). Ideal would be 1.0.

**Q54: How would you calculate the clock frequency limit?**  
**A:** `Tclk > Tsetup + max(Tprop_stage) + Thold` where `Tprop_stage` is the worst-case combinational delay through the longest stage (typically EX: forwarding MUX → ALU → result MUX → EX/MEM register setup).

---

### 🟢 Open-Ended Design Questions

**Q55: How would you add support for `jal` and `jalr`?**  
**A:** 
- Add J-type immediate to `Sign_Extend` ✅ (already done in updated version)
- `JAL`: `ResultSrc=10` (write PC+4 as return address), `ALUSrcA=10` (A=PC), `ALUSrc=1` (B=J-imm), `Jump=1`
- `JALR`: Same as JAL but `ALUSrcA=00` (A=rs1), target = rs1 + sign_ext(imm)
- Add `PCSrcE = BranchE & BranchTaken | JumpE` to trigger PC redirect

**Q56: How would you add pipeline stall support for multi-cycle operations (e.g., division)?**  
**A:** Add a `ready` signal from the execute unit. When `ready=0`, assert `StallF` and `StallD` to freeze all earlier stages, and also stall EX itself. The pipeline waits until the operation completes, then resumes.

**Q57: What is out-of-order execution and how is it different from your design?**  
**A:** Your processor is **in-order** — instructions execute in program order. Out-of-order (OOO) processors use a reorder buffer (ROB) and reservation stations to allow later independent instructions to execute while earlier ones stall. This dramatically improves IPC but requires vastly more complex hardware.

**Q58: What is Tomasulo's algorithm?**  
**A:** A hardware algorithm for out-of-order execution that uses register renaming (via reservation stations) to eliminate WAR (Write After Read) and WAW (Write After Write) hazards, and tracks which results are available. It's used in modern Intel/AMD microprocessors.

**Q59: How does your design differ from MIPS?**  
**A:** 
- RISC-V has a cleaner, more regular encoding
- RISC-V has no branch delay slot (MIPS does)
- RISC-V uses a software convention (x0=zero) instead of a hardware zero register named differently
- RISC-V opcode space is designed for future extensions (C, M, F, D, V, etc.)

**Q60: What would you do differently if you were to redo this project?**  
**A (good answer):** 
- Implement formal verification alongside simulation
- Add a proper branch predictor (2-bit saturating counter) to reduce the 2-cycle branch penalty
- Complete the load-use stall in the monolithic `Pipeline_Full.v`
- Add support for all branch types (`BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`) via a branch comparator
- Add byte/halfword memory access with funct3-based steering

---

## 🚀 Cheat Sheet — Numbers to Remember

| Metric | Value |
|--------|-------|
| Instruction width | 32 bits |
| Register width | 32 bits |
| Number of registers | 32 (x0–x31) |
| Pipeline stages | 5 (IF, ID, EX, MEM, WB) |
| Instruction memory | 4 KB (1024 × 32-bit words) |
| Data memory | 4 KB (1024 × 32-bit words) |
| Ideal CPI | 1.0 |
| Branch penalty | 2 cycles |
| Load-use penalty | 1 cycle (with stall) |
| Branch penalty without predictor | 2 cycles for every taken branch |
| ALU operations supported | 10 (ADD, SUB, AND, OR, XOR, SLT, SLTU, SLL, SRL, SRA) |
| Forwarding paths | 2 (MEM→EX, WB→EX) |
| Opcode bits | [6:0] |
| funct3 bits | [14:12] |
| funct7 bits | [31:25] |
| rd bits | [11:7] |
| rs1 bits | [19:15] |
| rs2 bits | [24:20] |

---

## 🎤 How to Talk About Your Project (Opening Statement)

> *"I built a 5-stage in-order pipelined RISC-V processor in Verilog, implementing a subset of the RV32I ISA. The pipeline has five stages — Fetch, Decode, Execute, Memory, and Write Back — with pipeline registers between each stage to allow multiple instructions to be in-flight simultaneously, achieving a CPI of 1 under ideal conditions.*
>
> *The most interesting part was handling data hazards. I implemented a forwarding unit that detects RAW hazards and bypasses stale register file values with results from the MEM and WB stages, feeding them directly to the EX stage inputs. For load-use hazards, where forwarding alone isn't enough, I implemented a stall mechanism that freezes the PC and the IF/ID register for one cycle while inserting a NOP bubble.*
>
> *For control hazards, I handle taken branches by flushing the two incorrectly-fetched instructions when `PCSrcE` is asserted at the end of the Execute stage.*
>
> *I verified the design using Icarus Verilog, with a test suite covering arithmetic, loads/stores, data forwarding, branch behavior, and the load-use hazard scenario, and inspected waveforms in GTKWave."*

---

*Good luck in your interview! You built something real — own it with confidence.* 🏆
