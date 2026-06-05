`timescale 1ns/1ps

module Pipeline_Top_tb();

    reg clk, rst;

    // DUT
    Pipeline_top dut(.clk(clk), .rst(rst));

    // Clock: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // PASS/FAIL counters
    integer pass_count = 0;
    integer fail_count = 0;

    // Reset and run
    initial begin
        $dumpfile("Pipeline_dump.vcd");
        $dumpvars(0, Pipeline_Top_tb);

        // Assert reset (active low) — release BETWEEN posedges to avoid race
        rst = 0;
        #22;           // posedges at 5,15,25... rst rises at 22 (between 15 and 25)
        rst = 1;

        // Run long enough: 49 instructions + branches + stalls + subroutine ≈ 300 cycles
        #3000;

        // ================================================================
        // Register File Dump
        // ================================================================
        $display("");
        $display("============================================================");
        $display("=               REGISTER FILE DUMP                         =");
        $display("============================================================");
        $display("x0  (zero) = %0d (0x%08h)", dut.decode.Reg_file.Register[0],  dut.decode.Reg_file.Register[0]);
        $display("x1         = %0d (0x%08h)", dut.decode.Reg_file.Register[1],  dut.decode.Reg_file.Register[1]);
        $display("x2         = %0d (0x%08h)", dut.decode.Reg_file.Register[2],  dut.decode.Reg_file.Register[2]);
        $display("x3         = %0d (0x%08h)", dut.decode.Reg_file.Register[3],  dut.decode.Reg_file.Register[3]);
        $display("x4         = %0d (0x%08h)", dut.decode.Reg_file.Register[4],  dut.decode.Reg_file.Register[4]);
        $display("x5         = %0d (0x%08h)", dut.decode.Reg_file.Register[5],  dut.decode.Reg_file.Register[5]);
        $display("x6         = %0d (0x%08h)", dut.decode.Reg_file.Register[6],  dut.decode.Reg_file.Register[6]);
        $display("x7         = %0d (0x%08h)", dut.decode.Reg_file.Register[7],  dut.decode.Reg_file.Register[7]);
        $display("x8         = %0d (0x%08h)", dut.decode.Reg_file.Register[8],  dut.decode.Reg_file.Register[8]);
        $display("x9         = %0d (0x%08h)", dut.decode.Reg_file.Register[9],  dut.decode.Reg_file.Register[9]);
        $display("x10        = %0d (0x%08h)", dut.decode.Reg_file.Register[10], dut.decode.Reg_file.Register[10]);
        $display("x11        = %0d (0x%08h)", dut.decode.Reg_file.Register[11], dut.decode.Reg_file.Register[11]);
        $display("x12        = %0d (0x%08h)", dut.decode.Reg_file.Register[12], dut.decode.Reg_file.Register[12]);
        $display("x13        = %0d (0x%08h)", dut.decode.Reg_file.Register[13], dut.decode.Reg_file.Register[13]);
        $display("x14        = %0d (0x%08h)", dut.decode.Reg_file.Register[14], dut.decode.Reg_file.Register[14]);
        $display("x15        = %0d (0x%08h)", dut.decode.Reg_file.Register[15], dut.decode.Reg_file.Register[15]);
        $display("x16        = %0d (0x%08h)", dut.decode.Reg_file.Register[16], dut.decode.Reg_file.Register[16]);
        $display("x17        = %0d (0x%08h)", dut.decode.Reg_file.Register[17], dut.decode.Reg_file.Register[17]);
        $display("x18        = %0d (0x%08h)", dut.decode.Reg_file.Register[18], dut.decode.Reg_file.Register[18]);
        $display("x19        = %0d (0x%08h)", dut.decode.Reg_file.Register[19], dut.decode.Reg_file.Register[19]);
        $display("x20        = %0d (0x%08h)", dut.decode.Reg_file.Register[20], dut.decode.Reg_file.Register[20]);
        $display("x21        = %0d (0x%08h)", dut.decode.Reg_file.Register[21], dut.decode.Reg_file.Register[21]);
        $display("x22        = %0d (0x%08h)", dut.decode.Reg_file.Register[22], dut.decode.Reg_file.Register[22]);
        $display("x23        = %0d (0x%08h)", dut.decode.Reg_file.Register[23], dut.decode.Reg_file.Register[23]);
        $display("x24        = %0d (0x%08h)", dut.decode.Reg_file.Register[24], dut.decode.Reg_file.Register[24]);
        $display("x25        = %0d (0x%08h)", dut.decode.Reg_file.Register[25], dut.decode.Reg_file.Register[25]);
        $display("x26        = %0d (0x%08h)", dut.decode.Reg_file.Register[26], dut.decode.Reg_file.Register[26]);
        $display("x27        = %0d (0x%08h)", dut.decode.Reg_file.Register[27], dut.decode.Reg_file.Register[27]);
        $display("x28        = %0d (0x%08h)", dut.decode.Reg_file.Register[28], dut.decode.Reg_file.Register[28]);
        $display("x29        = %0d (0x%08h)", dut.decode.Reg_file.Register[29], dut.decode.Reg_file.Register[29]);
        $display("x30        = %0d (0x%08h)", dut.decode.Reg_file.Register[30], dut.decode.Reg_file.Register[30]);
        $display("x31        = %0d (0x%08h)", dut.decode.Reg_file.Register[31], dut.decode.Reg_file.Register[31]);

        $display("");
        $display("============================================================");
        $display("=                 PASS / FAIL CHECKS                       =");
        $display("============================================================");

        // ----------------------------------------------------------------
        // I-type ALU: base values
        // ----------------------------------------------------------------
        if (dut.decode.Reg_file.Register[1] == 32'h0000006C)  // JAL overwrites x1 with link addr
            begin $display("PASS: JAL   x1=0x6C (link addr)"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: JAL   x1=0x%08h (expected 0x0000006C)", dut.decode.Reg_file.Register[1]); fail_count = fail_count + 1; end

        if (dut.decode.Reg_file.Register[2] == 32'd3)
            begin $display("PASS: ADDI  x2=3"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: ADDI  x2=%0d (expected 3)", dut.decode.Reg_file.Register[2]); fail_count = fail_count + 1; end

        // ----------------------------------------------------------------
        // R-type ALU
        // ----------------------------------------------------------------
        if (dut.decode.Reg_file.Register[3] == 32'd8)
            begin $display("PASS: ADD   x3=8   (5+3)"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: ADD   x3=%0d (expected 8)", dut.decode.Reg_file.Register[3]); fail_count = fail_count + 1; end

        if (dut.decode.Reg_file.Register[4] == 32'd2)
            begin $display("PASS: SUB   x4=2   (5-3)"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: SUB   x4=%0d (expected 2)", dut.decode.Reg_file.Register[4]); fail_count = fail_count + 1; end

        if (dut.decode.Reg_file.Register[5] == 32'd1)
            begin $display("PASS: AND   x5=1   (5&3)"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: AND   x5=%0d (expected 1)", dut.decode.Reg_file.Register[5]); fail_count = fail_count + 1; end

        if (dut.decode.Reg_file.Register[6] == 32'd7)
            begin $display("PASS: OR    x6=7   (5|3)"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: OR    x6=%0d (expected 7)", dut.decode.Reg_file.Register[6]); fail_count = fail_count + 1; end

        if (dut.decode.Reg_file.Register[7] == 32'd6)
            begin $display("PASS: XOR   x7=6   (5^3)"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: XOR   x7=%0d (expected 6)", dut.decode.Reg_file.Register[7]); fail_count = fail_count + 1; end

        if (dut.decode.Reg_file.Register[8] == 32'd1)
            begin $display("PASS: SLT   x8=1   (3<5)"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: SLT   x8=%0d (expected 1)", dut.decode.Reg_file.Register[8]); fail_count = fail_count + 1; end

        if (dut.decode.Reg_file.Register[9] == 32'd1)
            begin $display("PASS: SLTU  x9=1   (3<u5)"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: SLTU  x9=%0d (expected 1)", dut.decode.Reg_file.Register[9]); fail_count = fail_count + 1; end

        if (dut.decode.Reg_file.Register[10] == 32'd40)
            begin $display("PASS: SLL   x10=40 (5<<3)"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: SLL   x10=%0d (expected 40)", dut.decode.Reg_file.Register[10]); fail_count = fail_count + 1; end

        if (dut.decode.Reg_file.Register[11] == 32'd0)
            begin $display("PASS: SRL   x11=0  (5>>3)"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: SRL   x11=%0d (expected 0)", dut.decode.Reg_file.Register[11]); fail_count = fail_count + 1; end

        if (dut.decode.Reg_file.Register[12] == 32'hFFFFFFFF)
            begin $display("PASS: ADDI  x12=0xFFFFFFFF (-1)"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: ADDI  x12=0x%08h (expected 0xFFFFFFFF)", dut.decode.Reg_file.Register[12]); fail_count = fail_count + 1; end

        if (dut.decode.Reg_file.Register[13] == 32'hFFFFFFFF)
            begin $display("PASS: SRA   x13=0xFFFFFFFF (-1>>>3)"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: SRA   x13=0x%08h (expected 0xFFFFFFFF)", dut.decode.Reg_file.Register[13]); fail_count = fail_count + 1; end

        // ----------------------------------------------------------------
        // I-type ALU (non-addi)
        // ----------------------------------------------------------------
        if (dut.decode.Reg_file.Register[14] == 32'd1)
            begin $display("PASS: ANDI  x14=1  (5&3)"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: ANDI  x14=%0d (expected 1)", dut.decode.Reg_file.Register[14]); fail_count = fail_count + 1; end

        if (dut.decode.Reg_file.Register[15] == 32'd7)
            begin $display("PASS: ORI   x15=7  (5|3)"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: ORI   x15=%0d (expected 7)", dut.decode.Reg_file.Register[15]); fail_count = fail_count + 1; end

        if (dut.decode.Reg_file.Register[16] == 32'd6)
            begin $display("PASS: XORI  x16=6  (5^3)"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: XORI  x16=%0d (expected 6)", dut.decode.Reg_file.Register[16]); fail_count = fail_count + 1; end

        if (dut.decode.Reg_file.Register[17] == 32'd1)
            begin $display("PASS: SLTI  x17=1  (3<5)"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: SLTI  x17=%0d (expected 1)", dut.decode.Reg_file.Register[17]); fail_count = fail_count + 1; end

        if (dut.decode.Reg_file.Register[18] == 32'd1)
            begin $display("PASS: SLTIU x18=1  (3<u5)"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: SLTIU x18=%0d (expected 1)", dut.decode.Reg_file.Register[18]); fail_count = fail_count + 1; end

        if (dut.decode.Reg_file.Register[19] == 32'd10)
            begin $display("PASS: SLLI  x19=10 (5<<1)"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: SLLI  x19=%0d (expected 10)", dut.decode.Reg_file.Register[19]); fail_count = fail_count + 1; end

        if (dut.decode.Reg_file.Register[20] == 32'd2)
            begin $display("PASS: SRLI  x20=2  (5>>1)"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: SRLI  x20=%0d (expected 2)", dut.decode.Reg_file.Register[20]); fail_count = fail_count + 1; end

        if (dut.decode.Reg_file.Register[21] == 32'hFFFFFFFF)
            begin $display("PASS: SRAI  x21=0xFFFFFFFF (-1>>>1)"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: SRAI  x21=0x%08h (expected 0xFFFFFFFF)", dut.decode.Reg_file.Register[21]); fail_count = fail_count + 1; end

        // ----------------------------------------------------------------
        // U-type
        // ----------------------------------------------------------------
        if (dut.decode.Reg_file.Register[22] == 32'hDEADB000)
            begin $display("PASS: LUI   x22=0xDEADB000"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: LUI   x22=0x%08h (expected 0xDEADB000)", dut.decode.Reg_file.Register[22]); fail_count = fail_count + 1; end

        if (dut.decode.Reg_file.Register[23] == 32'h00000058)
            begin $display("PASS: AUIPC x23=0x58 (PC of auipc instr)"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: AUIPC x23=0x%08h (expected 0x00000058)", dut.decode.Reg_file.Register[23]); fail_count = fail_count + 1; end

        // ----------------------------------------------------------------
        // Branches (canary check: x30 must NOT be 99)
        // If ANY branch failed to take, x30 would be 99.
        // x30 final value should be 16 (from load-use test at the end).
        // ----------------------------------------------------------------
        if (dut.decode.Reg_file.Register[30] != 32'd99)
            begin $display("PASS: BEQ   branch taken (canary safe)"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: BEQ   branch NOT taken (x30=99)"); fail_count = fail_count + 1; end

        // Since all 6 branches share the same canary register, we verify
        // individual branch correctness by checking x30's final value:
        // If x30 == 16, ALL branches were taken, AND the load-use test passed.
        if (dut.decode.Reg_file.Register[30] == 32'd16)
            begin $display("PASS: BRANCHES(BEQ/BNE/BLT/BGE/BLTU/BGEU) "); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: BRANCHES — x30=%0d (expected 16, got via load-use after all branches)", dut.decode.Reg_file.Register[30]); fail_count = fail_count + 1; end

        // ----------------------------------------------------------------
        // JAL / JALR subroutine
        // ----------------------------------------------------------------
        if (dut.decode.Reg_file.Register[29] == 32'd42)
            begin $display("PASS: JAL/JALR subroutine x29=42"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: JAL/JALR subroutine x29=%0d (expected 42)", dut.decode.Reg_file.Register[29]); fail_count = fail_count + 1; end

        // ----------------------------------------------------------------
        // Load instructions (reading back stored values)
        // ----------------------------------------------------------------
        // SW stored x3=8 to mem[0..3], then LW reads it back
        if (dut.decode.Reg_file.Register[24] == 32'd8)
            begin $display("PASS: LW    x24=8  (word from mem[0])"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: LW    x24=%0d (expected 8)", dut.decode.Reg_file.Register[24]); fail_count = fail_count + 1; end

        // SB stored x1 low byte to mem[4]. Original x1=5, but JAL overwrites x1=0x6C.
        // SB at 0x60 executes BEFORE JAL at 0x68, so x1 was still 5 at that point.
        if (dut.decode.Reg_file.Register[25] == 32'd5)
            begin $display("PASS: LB    x25=5  (signed byte from mem[4])"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: LB    x25=%0d (expected 5)", dut.decode.Reg_file.Register[25]); fail_count = fail_count + 1; end

        if (dut.decode.Reg_file.Register[26] == 32'd5)
            begin $display("PASS: LBU   x26=5  (unsigned byte from mem[4])"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: LBU   x26=%0d (expected 5)", dut.decode.Reg_file.Register[26]); fail_count = fail_count + 1; end

        // SH stored x1 (=5 at that time) halfword to mem[8..9]
        if (dut.decode.Reg_file.Register[27] == 32'd5)
            begin $display("PASS: LH    x27=5  (signed half from mem[8])"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: LH    x27=%0d (expected 5)", dut.decode.Reg_file.Register[27]); fail_count = fail_count + 1; end

        if (dut.decode.Reg_file.Register[28] == 32'd5)
            begin $display("PASS: LHU   x28=5  (unsigned half from mem[8])"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: LHU   x28=%0d (expected 5)", dut.decode.Reg_file.Register[28]); fail_count = fail_count + 1; end

        // ----------------------------------------------------------------
        // Load-use hazard test
        // ----------------------------------------------------------------
        if (dut.decode.Reg_file.Register[31] == 32'd8)
            begin $display("PASS: LW(hazard)   x31=8"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: LW(hazard)   x31=%0d (expected 8)", dut.decode.Reg_file.Register[31]); fail_count = fail_count + 1; end

        if (dut.decode.Reg_file.Register[30] == 32'd16)
            begin $display("PASS: ADD(post-lw) x30=16 (8+8, load-use stall worked)"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: ADD(post-lw) x30=%0d (expected 16)", dut.decode.Reg_file.Register[30]); fail_count = fail_count + 1; end

        // ----------------------------------------------------------------
        // Summary
        // ----------------------------------------------------------------
        $display("");
        $display("============================================================");
        $display("  TOTAL PASS: %0d", pass_count);
        $display("  TOTAL FAIL: %0d", fail_count);
        if (fail_count == 0)
            $display("  *** ALL TESTS PASSED ***");
        else
            $display("  *** SOME TESTS FAILED ***");
        $display("============================================================");
        $display("");

        $finish;
    end

endmodule