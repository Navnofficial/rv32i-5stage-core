# ==============================================================
# test_full.S — Full RV32I Test for 5-Stage Pipeline
# ==============================================================
# Every supported instruction is tested.
# Each result goes to a UNIQUE register (no overwrites).
# x30 is a canary: should end as 16. If any branch fails, it
# becomes 99.
#
# Assemble: riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 \
#           -nostdlib -Ttext=0x0 -o test_full.elf test_full.S
# Extract:  riscv64-unknown-elf-objcopy -O binary test_full.elf test_full.bin
# Convert:  python3 bin2hex.py test_full.bin memfile.hex
# ==============================================================

    .text
    .globl _start

_start:
# ==============================================================
# PART 1: I-type ALU — base values
# ==============================================================
    addi  x1,  x0,  5           # x1  = 5
    addi  x2,  x0,  3           # x2  = 3

# ==============================================================
# PART 2: R-type ALU
# ==============================================================
    add   x3,  x1,  x2          # x3  = 8    (5+3)
    sub   x4,  x1,  x2          # x4  = 2    (5-3)
    and   x5,  x1,  x2          # x5  = 1    (0b101 & 0b011)
    or    x6,  x1,  x2          # x6  = 7    (0b101 | 0b011)
    xor   x7,  x1,  x2          # x7  = 6    (0b101 ^ 0b011)
    slt   x8,  x2,  x1          # x8  = 1    (3 < 5 = true)
    sltu  x9,  x2,  x1          # x9  = 1    (3 <u 5 = true)
    sll   x10, x1,  x2          # x10 = 40   (5 << 3)
    srl   x11, x1,  x2          # x11 = 0    (5 >> 3)

# -1 in x12 for SRA test
    addi  x12, x0,  -1          # x12 = 0xFFFFFFFF

    sra   x13, x12, x2          # x13 = 0xFFFFFFFF (arith >> 3)

# ==============================================================
# PART 3: I-type ALU (non-addi)
# ==============================================================
    andi  x14, x1,  3           # x14 = 1    (5 & 3)
    ori   x15, x1,  3           # x15 = 7    (5 | 3)
    xori  x16, x1,  3           # x16 = 6    (5 ^ 3)
    slti  x17, x2,  5           # x17 = 1    (3 < 5)
    sltiu x18, x2,  5           # x18 = 1    (3 <u 5)
    slli  x19, x1,  1           # x19 = 10   (5 << 1)
    srli  x20, x1,  1           # x20 = 2    (5 >> 1)
    srai  x21, x12, 1           # x21 = 0xFFFFFFFF  (-1 >>> 1 = -1)

# ==============================================================
# PART 4: U-type
# ==============================================================
    lui   x22, 0xDEADB          # x22 = 0xDEADB000
    auipc x23, 0                # x23 = PC of this instruction

# ==============================================================
# PART 5: Store (prepare data in memory for load tests)
# ==============================================================
    sw    x3,  0(x0)             # mem[0..3]  = 8  (word)
    sb    x1,  4(x0)             # mem[4]     = 5  (byte)
    sh    x1,  8(x0)             # mem[8..9]  = 5  (halfword)

# ==============================================================
# PART 6: JAL — jump to subroutine, set x29=42, return via JALR
# ==============================================================
    jal   x1,  sub_func         # x1 = PC+4 (link address)
    # --- execution continues here after JALR return ---

# ==============================================================
# PART 7: Branch tests
# Each branch skips over an "addi x30, x0, 99" (canary kill).
# If the branch is NOT taken, x30 = 99 = FAIL.
# ==============================================================

# --- BEQ: x3==x3 (8==8), should be taken ---
test_beq:
    beq   x3,  x3,  beq_pass
    addi  x30, x0,  99          # FAIL path
beq_pass:

# --- BNE: x1!=x2 (different values), should be taken ---
test_bne:
    bne   x3,  x2,  bne_pass
    addi  x30, x0,  99          # FAIL path
bne_pass:

# --- BLT: x2<x1 (3<5 signed), should be taken ---
test_blt:
    blt   x2,  x1,  blt_pass
    addi  x30, x0,  99          # FAIL path
blt_pass:

# --- BGE: x1>=x2 (5>=3 signed), should be taken ---
test_bge:
    bge   x1,  x2,  bge_pass
    addi  x30, x0,  99          # FAIL path
bge_pass:

# --- BLTU: x2<x1 (3<u5 unsigned), should be taken ---
test_bltu:
    bltu  x2,  x1,  bltu_pass
    addi  x30, x0,  99          # FAIL path
bltu_pass:

# --- BGEU: x1>=x2 (5>=u3 unsigned), should be taken ---
test_bgeu:
    bgeu  x1,  x2,  bgeu_pass
    addi  x30, x0,  99          # FAIL path
bgeu_pass:

# ==============================================================
# PART 8: Load tests (read back what was stored in PART 5)
# ==============================================================
    lw    x24, 0(x0)             # x24 = 8   (word from mem[0])
    lb    x25, 4(x0)             # x25 = 5   (signed byte from mem[4])
    lbu   x26, 4(x0)            # x26 = 5   (unsigned byte from mem[4])
    lh    x27, 8(x0)             # x27 = 5   (signed half from mem[8])
    lhu   x28, 8(x0)            # x28 = 5   (unsigned half from mem[8])

# ==============================================================
# PART 9: Load-use hazard test
# lw immediately followed by add that uses the loaded value.
# The hazard unit must stall 1 cycle.
# ==============================================================
    lw    x31, 0(x0)             # x31 = 8   (load from mem[0])
    add   x30, x31, x24         # x30 = 8+8 = 16  (load-use: must stall)

# ==============================================================
# PART 10: Halt — infinite loop
# ==============================================================
halt:
    jal   x0,  halt             # loop forever (x0 discarded)

# ==============================================================
# Subroutine for JAL/JALR test
# Sets x29 = 42, then returns to caller via JALR
# ==============================================================
sub_func:
    addi  x29, x0,  42          # x29 = 42
    jalr  x0,  x1,  0           # return to link address in x1
