#!/usr/bin/env python3
"""
hand_assemble.py — Hand-assemble test_full.S to memfile.hex
Generates the hex file for the Instruction Memory ($readmemh format).
Each line = one 32-bit word (8 hex digits), word-addressed.
"""

import struct

instructions = []

def R(funct7, rs2, rs1, funct3, rd, opcode=0b0110011):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def I(imm12, rs1, funct3, rd, opcode):
    imm = imm12 & 0xFFF
    return (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def S(imm12, rs2, rs1, funct3):
    imm = imm12 & 0xFFF
    return ((imm >> 5) << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | ((imm & 0x1F) << 7) | 0b0100011

def B(imm13, rs2, rs1, funct3):
    """imm13 is the signed byte offset (must be even)"""
    imm = imm13 & 0x1FFF
    b12  = (imm >> 12) & 1
    b11  = (imm >> 11) & 1
    b10_5 = (imm >> 5) & 0x3F
    b4_1  = (imm >> 1) & 0xF
    return (b12 << 31) | (b10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (b4_1 << 8) | (b11 << 7) | 0b1100011

def U(imm20, rd, opcode):
    return ((imm20 & 0xFFFFF) << 12) | (rd << 7) | opcode

def J(imm21, rd):
    """imm21 is the signed byte offset (must be even)"""
    imm = imm21 & 0x1FFFFF
    b20   = (imm >> 20) & 1
    b19_12 = (imm >> 12) & 0xFF
    b11   = (imm >> 11) & 1
    b10_1 = (imm >> 1) & 0x3FF
    return (b20 << 31) | (b10_1 << 21) | (b11 << 20) | (b19_12 << 12) | (rd << 7) | 0b1101111

# Keep track of PC (byte address)
pc = 0
def emit(instr, comment=""):
    global pc
    instructions.append((pc, instr, comment))
    pc += 4

# ====================== PART 1: I-type base ======================
emit(I(5,   0, 0b000, 1,  0b0010011), "addi x1, x0, 5")     # 0x00
emit(I(3,   0, 0b000, 2,  0b0010011), "addi x2, x0, 3")     # 0x04

# ====================== PART 2: R-type ==========================
emit(R(0b0000000, 2, 1, 0b000, 3),  "add  x3, x1, x2")      # 0x08
emit(R(0b0100000, 2, 1, 0b000, 4),  "sub  x4, x1, x2")      # 0x0C
emit(R(0b0000000, 2, 1, 0b111, 5),  "and  x5, x1, x2")      # 0x10
emit(R(0b0000000, 2, 1, 0b110, 6),  "or   x6, x1, x2")      # 0x14
emit(R(0b0000000, 2, 1, 0b100, 7),  "xor  x7, x1, x2")      # 0x18
emit(R(0b0000000, 1, 2, 0b010, 8),  "slt  x8, x2, x1")      # 0x1C
emit(R(0b0000000, 1, 2, 0b011, 9),  "sltu x9, x2, x1")      # 0x20
emit(R(0b0000000, 2, 1, 0b001, 10), "sll  x10, x1, x2")     # 0x24
emit(R(0b0000000, 2, 1, 0b101, 11), "srl  x11, x1, x2")     # 0x28

# x12 = -1 for SRA test
emit(I((-1) & 0xFFF, 0, 0b000, 12, 0b0010011), "addi x12, x0, -1")  # 0x2C

emit(R(0b0100000, 2, 12, 0b101, 13), "sra x13, x12, x2")    # 0x30

# ====================== PART 3: I-type ALU =====================
emit(I(3,   1, 0b111, 14, 0b0010011), "andi x14, x1, 3")    # 0x34
emit(I(3,   1, 0b110, 15, 0b0010011), "ori  x15, x1, 3")    # 0x38
emit(I(3,   1, 0b100, 16, 0b0010011), "xori x16, x1, 3")    # 0x3C
emit(I(5,   2, 0b010, 17, 0b0010011), "slti x17, x2, 5")    # 0x40
emit(I(5,   2, 0b011, 18, 0b0010011), "sltiu x18, x2, 5")   # 0x44
emit(I(1,   1, 0b001, 19, 0b0010011), "slli x19, x1, 1")    # 0x48
emit(I(1,   1, 0b101, 20, 0b0010011), "srli x20, x1, 1")    # 0x4C
# srai x21, x12, 1 → imm = 0x401 (funct7[5]=1, shamt=1)
emit(I(0x401, 12, 0b101, 21, 0b0010011), "srai x21, x12, 1")# 0x50

# ====================== PART 4: U-type =========================
emit(U(0xDEADB, 22, 0b0110111), "lui   x22, 0xDEADB")       # 0x54
emit(U(0x00000, 23, 0b0010111), "auipc x23, 0")              # 0x58

# ====================== PART 5: Store ==========================
emit(S(0,  3, 0, 0b010), "sw x3, 0(x0)")                     # 0x5C
emit(S(4,  1, 0, 0b000), "sb x1, 4(x0)")                     # 0x60
emit(S(8,  1, 0, 0b001), "sh x1, 8(x0)")                     # 0x64

# ====================== PART 6: JAL + subroutine ==============
# jal x1, sub_func
# sub_func is at the END of the program.
# We need to know the exact offset. Let's count forward.
# JAL is at PC=0x68
# After JAL, continue-after-return is at PC=0x6C
# Branches start at 0x6C
# Branch section:
#   6 branches × 2 instructions each (branch + addi) = 12 instructions = 48 bytes
# Load section: 5 loads = 20 bytes
# Load-use: 2 instructions = 8 bytes
# Halt: 1 instruction = 4 bytes
# sub_func starts after halt
#
# Let me lay out PCs precisely:
# 0x68: jal x1, sub_func
# 0x6C: beq x3, x3, +8     (skip 1 instr = +8 bytes)
# 0x70: addi x30, x0, 99   (fail canary)
# 0x74: bne x3, x2, +8     (skip 1 instr)
# 0x78: addi x30, x0, 99
# 0x7C: blt x2, x1, +8
# 0x80: addi x30, x0, 99
# 0x84: bge x1, x2, +8
# 0x88: addi x30, x0, 99
# 0x8C: bltu x2, x1, +8
# 0x90: addi x30, x0, 99
# 0x94: bgeu x1, x2, +8
# 0x98: addi x30, x0, 99
# 0x9C: lw  x24, 0(x0)
# 0xA0: lb  x25, 4(x0)
# 0xA4: lbu x26, 4(x0)
# 0xA8: lh  x27, 8(x0)
# 0xAC: lhu x28, 8(x0)
# 0xB0: lw  x31, 0(x0)    -- load-use
# 0xB4: add x30, x31, x24 -- use after load
# 0xB8: jal x0, 0         -- halt (loop to self)
# 0xBC: addi x29, x0, 42  -- sub_func
# 0xC0: jalr x0, x1, 0    -- return

# JAL at 0x68, target = 0xBC, offset = 0xBC - 0x68 = 0x54 = 84
jal_offset = 0xBC - 0x68  # = 84
emit(J(jal_offset, 1), f"jal x1, sub_func (offset={jal_offset})")  # 0x68

# ====================== PART 7: Branches ======================
# Each branch: taken → skip the next instruction (+8 bytes from branch PC)
branch_skip = 8

# BEQ: x3 == x3 (8==8)
emit(B(branch_skip, 3, 3, 0b000), "beq x3, x3, +8")         # 0x6C
emit(I(99, 0, 0b000, 30, 0b0010011), "addi x30, x0, 99 (BEQ fail)") # 0x70

# BNE: x3 != x2 (8!=3)
emit(B(branch_skip, 2, 3, 0b001), "bne x3, x2, +8")         # 0x74
emit(I(99, 0, 0b000, 30, 0b0010011), "addi x30, x0, 99 (BNE fail)") # 0x78

# BLT: x2 < x1 (3<5 signed)
emit(B(branch_skip, 1, 2, 0b100), "blt x2, x1, +8")         # 0x7C
emit(I(99, 0, 0b000, 30, 0b0010011), "addi x30, x0, 99 (BLT fail)") # 0x80

# BGE: x1 >= x2 (5>=3 signed)
emit(B(branch_skip, 2, 1, 0b101), "bge x1, x2, +8")         # 0x84
emit(I(99, 0, 0b000, 30, 0b0010011), "addi x30, x0, 99 (BGE fail)") # 0x88

# BLTU: x2 <u x1 (3<5 unsigned)
emit(B(branch_skip, 1, 2, 0b110), "bltu x2, x1, +8")        # 0x8C
emit(I(99, 0, 0b000, 30, 0b0010011), "addi x30, x0, 99 (BLTU fail)")# 0x90

# BGEU: x1 >=u x2 (5>=3 unsigned)
emit(B(branch_skip, 2, 1, 0b111), "bgeu x1, x2, +8")        # 0x94
emit(I(99, 0, 0b000, 30, 0b0010011), "addi x30, x0, 99 (BGEU fail)")# 0x98

# ====================== PART 8: Loads ==========================
emit(I(0,  0, 0b010, 24, 0b0000011), "lw  x24, 0(x0)")      # 0x9C
emit(I(4,  0, 0b000, 25, 0b0000011), "lb  x25, 4(x0)")      # 0xA0
emit(I(4,  0, 0b100, 26, 0b0000011), "lbu x26, 4(x0)")      # 0xA4
emit(I(8,  0, 0b001, 27, 0b0000011), "lh  x27, 8(x0)")      # 0xA8
emit(I(8,  0, 0b101, 28, 0b0000011), "lhu x28, 8(x0)")      # 0xAC

# ====================== PART 9: Load-use hazard ================
emit(I(0,  0, 0b010, 31, 0b0000011), "lw  x31, 0(x0)")      # 0xB0
emit(R(0b0000000, 24, 31, 0b000, 30), "add x30, x31, x24")  # 0xB4

# ====================== PART 10: Halt ==========================
# jal x0, 0 (jump to self = infinite loop)
emit(J(0, 0), "jal x0, 0 (halt)")                            # 0xB8

# ====================== Subroutine =============================
emit(I(42, 0, 0b000, 29, 0b0010011), "addi x29, x0, 42")    # 0xBC
emit(I(0,  1, 0b000, 0,  0b1100111), "jalr x0, x1, 0")      # 0xC0

# ====================== Output ================================
with open("memfile.hex", "w") as f:
    f.write("@00000000\n")
    for addr, instr, comment in instructions:
        f.write(f"{instr:08X}\n")

print(f"Generated {len(instructions)} instructions")
print("\nDisassembly:")
for addr, instr, comment in instructions:
    print(f"  0x{addr:04X}:  {instr:08X}  {comment}")
