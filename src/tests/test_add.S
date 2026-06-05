.section .text
.global _start
_start:

    # Test 1: 5 + 3 = 8
    addi x1, x0, 5
    addi x2, x0, 3
    add  x3, x1, x2

    # Test 2: -1 + 1 = 0
    addi x1, x0, -1
    addi x2, x0, 1
    add  x4, x1, x2

    # Test 3: 0 + 0 = 0
    addi x1, x0, 0
    addi x2, x0, 0
    add  x5, x1, x2

    # Test 4: 100 + 200 = 300
    addi x1, x0, 100
    addi x2, x0, 200
    add  x6, x1, x2

    # halt
loop:
    beq x0, x0, loop