// Hazard Unit — Data forwarding + Load-use stall detection
//
// Forwarding:
//   ForwardAE/ForwardBE:
//     00 = from register file
//     01 = forward from WB stage (ResultW)
//     10 = forward from MEM stage (ALUResultM)
//
// Load-use stall:
//   When EX stage has a load (ResultSrcE == 2'b01) and its destination
//   matches a source register in the ID stage → stall 1 cycle.
//   StallF=1, StallD=1, FlushE=1

module hazard_unit(
    rst,
    // Forwarding inputs
    RegWriteM, RegWriteW,
    RD_M, RD_W,
    Rs1_E, Rs2_E,
    // Forwarding outputs
    ForwardAE, ForwardBE,
    // Load-use stall inputs
    ResultSrcE,
    RD_E,
    Rs1_D, Rs2_D,
    // Stall/flush outputs
    StallF, StallD, FlushE,
    // Branch/jump flush
    PCSrcE, FlushD
);

    input        rst;
    input        RegWriteM, RegWriteW;
    input  [4:0] RD_M, RD_W, Rs1_E, Rs2_E;
    input  [1:0] ResultSrcE;
    input  [4:0] RD_E, Rs1_D, Rs2_D;
    input        PCSrcE;

    output [1:0] ForwardAE, ForwardBE;
    output       StallF, StallD, FlushE, FlushD;

    // ---- MEM-to-EX forwarding ----
    assign ForwardAE =
        (rst == 1'b0)                                                  ? 2'b00 :
        ((RegWriteM) && (RD_M != 5'h0) && (RD_M == Rs1_E))           ? 2'b10 : // MEM fwd
        ((RegWriteW) && (RD_W != 5'h0) && (RD_W == Rs1_E))           ? 2'b01 : // WB fwd
                                                                         2'b00;

    assign ForwardBE =
        (rst == 1'b0)                                                  ? 2'b00 :
        ((RegWriteM) && (RD_M != 5'h0) && (RD_M == Rs2_E))           ? 2'b10 : // MEM fwd
        ((RegWriteW) && (RD_W != 5'h0) && (RD_W == Rs2_E))           ? 2'b01 : // WB fwd
                                                                         2'b00;

    // ---- Load-use hazard ----
    wire lwStall = (ResultSrcE == 2'b01) &&
                   ((RD_E == Rs1_D) || (RD_E == Rs2_D));

    assign StallF = lwStall;
    assign StallD = lwStall;

    // FlushD: insert NOP into ID/EX for BOTH branch/jump AND load-use stall
    //   - branch/jump: squash wrong-path instruction currently in ID stage
    //   - load-use:    insert bubble so ADD doesn't read stale LW result
    assign FlushD = PCSrcE | lwStall;

    // FlushE: flush EX/MEM — NEVER needed (LW must proceed to MEM normally)
    assign FlushE = 1'b0;

endmodule