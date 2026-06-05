# Comprehensive Test Suite for 5-Stage Pipelined RV32I Core

## Step 1: Instructions Found in Verilog

### From `Main_Decoder.v` — Opcode Support

| Opcode      | Type        | Instructions                                 |
|-------------|-------------|----------------------------------------------|
| `0110011`   | R-type      | add, sub, and, or, xor, slt, sltu, sll, srl, sra |
| `0010011`   | I-type ALU  | addi, andi, ori, xori, slti, sltiu, slli, srli, srai |
| `0000011`   | Load        | lw, lh, lb, lhu, lbu                        |
| `0100011`   | Store       | sw, sh, sb                                   |
| `1100011`   | Branch      | beq, bne, blt, bge, bltu, bgeu              |
| `1101111`   | J-type      | jal                                          |
| `1100111`   | I-type Jump | jalr                                         |
| `0110111`   | U-type      | lui                                          |
| `0010111`   | U-type      | auipc                                        |

### From `ALU_Decoder.v` — ALUControl Mapping

| ALUControl | Operation | Used by                        |
|------------|-----------|--------------------------------|
| `0000`     | ADD       | add, addi, lw, sw, lui, auipc  |
| `0001`     | SUB       | sub, branches                  |
| `0010`     | AND       | and, andi                      |
| `0011`     | OR        | or, ori                        |
| `0100`     | XOR       | xor, xori                      |
| `0101`     | SLT       | slt, slti                      |
| `0110`     | SLTU      | sltu, sltiu                    |
| `0111`     | SLL       | sll, slli                      |
| `1000`     | SRL       | srl, srli                      |
| `1001`     | SRA       | sra, srai                      |

### From `Branch_Comparator.v` — Branch Conditions

| funct3 | Branch |
|--------|--------|
| `000`  | BEQ    |
| `001`  | BNE    |
| `100`  | BLT    |
| `101`  | BGE    |
| `110`  | BLTU   |
| `111`  | BGEU   |

### From `Data_Memory.v` — Memory Width Support

| funct3 | Load  | Store |
|--------|-------|-------|
| `000`  | LB    | SB    |
| `001`  | LH    | SH    |
| `010`  | LW    | SW    |
| `100`  | LBU   | —     |
| `101`  | LHU   | —     |

---

## Step 2: Test Plan — Instruction → Register Mapping

| #  | Instruction            | Dest Reg | Expected Value | Test Category       |
|----|------------------------|----------|----------------|---------------------|
| 1  | `addi x1, x0, 5`      | x1       | 5              | I-type ALU          |
| 2  | `addi x2, x0, 3`      | x2       | 3              | I-type ALU          |
| 3  | `add x3, x1, x2`      | x3       | 8              | R-type              |
| 4  | `sub x4, x1, x2`      | x4       | 2              | R-type (SUB)        |
| 5  | `and x5, x1, x2`      | x5       | 1              | R-type              |
| 6  | `or x6, x1, x2`       | x6       | 7              | R-type              |
| 7  | `xor x7, x1, x2`      | x7       | 6              | R-type              |
| 8  | `slt x8, x2, x1`      | x8       | 1 (3<5)        | R-type              |
| 9  | `sltu x9, x2, x1`     | x9       | 1              | R-type              |
| 10 | `sll x10, x1, x2`     | x10      | 40 (5<<3)      | R-type              |
| 11 | `srl x11, x1, x2`     | x11      | 0 (5>>3)       | R-type              |
| 12 | `addi x12, x0, -1`    | x12      | 0xFFFFFFFF     | I-type negative     |
| 13 | `sra x13, x12, x2`    | x13      | 0xFFFFFFFF     | R-type (arith shft) |
| 14 | `andi x14, x1, 3`     | x14      | 1              | I-type ALU          |
| 15 | `ori x15, x1, 3`      | x15      | 7              | I-type ALU          |
| 16 | `xori x16, x1, 3`     | x16      | 6              | I-type ALU          |
| 17 | `slti x17, x2, 5`     | x17      | 1              | I-type ALU          |
| 18 | `sltiu x18, x2, 5`    | x18      | 1              | I-type ALU          |
| 19 | `slli x19, x1, 1`     | x19      | 10             | I-type shift        |
| 20 | `srli x20, x1, 1`     | x20      | 2              | I-type shift        |
| 21 | `srai x21, x12, 1`    | x21      | 0xFFFFFFFF     | I-type arith shift  |
| 22 | `lui x22, 0xDEAD`     | x22      | 0xDEAD000 (*)  | U-type              |
| 23 | `auipc x23, 0`        | x23      | PC@instr 22    | U-type              |
| 24 | `sw x3, 0(x0)`        | mem[0]   | 8              | Store word          |
| 25 | `sb x1, 4(x0)`        | mem[4]   | 5              | Store byte          |
| 26 | `sh x1, 8(x0)`        | mem[8]   | 5              | Store halfword      |
| 27 | `lw x24, 0(x0)`       | x24      | 8              | Load word           |
| 28 | `lb x25, 4(x0)`       | x25      | 5              | Load byte (signed)  |
| 29 | `lbu x26, 4(x0)`      | x26      | 5              | Load byte unsigned  |
| 30 | `lh x27, 8(x0)`       | x27      | 5              | Load halfword       |
| 31 | `lhu x28, 8(x0)`      | x28      | 5              | Load halfword unsig |
| 32 | `jal x1, sub_func`    | x1       | PC+4 (link)    | JAL                 |
| —  | (2 NOPs in delay)      |          |                |                     |
| 33 | `jalr x0, x1, 0`      | —        | return to link | JALR                |
| —  | (subroutine sets x29)  | x29      | 42             | JAL subroutine      |
| 34 | `beq x1, x1, +6`      | skip2nop | — (taken)      | BEQ (taken)         |
| 35 | `addi x30, x0, 99`    | x30      | 99 ONLY IF FAIL| BEQ not-taken path  |
| 36 | `bne x1, x2, +6`      | skip2nop | — (taken)      | BNE (taken)         |
| 37 | `addi x30, x0, 99`    | x30      | 99 ONLY IF FAIL| BNE not-taken path  |
| 38 | `blt x2, x1, +6`      | skip2nop | — (3<5, taken) | BLT (taken)         |
| 39 | `addi x30, x0, 99`    | x30      | 99 ONLY IF FAIL| BLT not-taken path  |
| 40 | `bge x1, x2, +6`      | skip2nop | — (5≥3, taken) | BGE (taken)         |
| 41 | `addi x30, x0, 99`    | x30      | 99 ONLY IF FAIL| BGE not-taken path  |
| 42 | `bltu x2, x1, +6`     | skip2nop | — (taken)      | BLTU (taken)        |
| 43 | `addi x30, x0, 99`    | x30      | 99 ONLY IF FAIL| BLTU not-taken path |
| 44 | `bgeu x1, x2, +6`     | skip2nop | — (taken)      | BGEU (taken)        |
| 45 | `addi x30, x0, 99`    | x30      | 99 ONLY IF FAIL| BGEU not-taken path |
| 46 | `lw x31, 0(x0)`       | x31      | 8              | Load-use hazard     |
| 47 | `add x30, x31, x24`   | x30      | 16 (8+8)       | Use after load      |
| 48 | `j halt`               | —        | infinite loop  | Halt                |

> [!NOTE]
> (*) `lui x22, 0xDEAD` → `x22 = 0x0DEAD000`. The upper 20 bits are `0x0DEAD`, shifted left 12 → `0x0DEAD000`.

> [!IMPORTANT]
> **x30** is used as a "canary" — it should end up as `16` (from the load-use test). If any branch FAILS to take, it gets overwritten to `99`, providing a clear FAIL signal.

## Step 3: Assembly Program

See `test_full.S` — created alongside this plan.

## Step 4: Testbench

See `Pipeline_Top_tb.v` — created alongside this plan.

## Verification Plan

1. Hand-assemble `test_full.S` → `memfile.hex` using a Python script
2. Compile: `iverilog -o dump.vvp Pipeline_Top.v Pipeline_Top_tb.v`
3. Simulate: `vvp dump.vvp`
4. Check console for PASS/FAIL
5. Open `Pipeline_dump.vcd` in GTKWave for waveform verification
