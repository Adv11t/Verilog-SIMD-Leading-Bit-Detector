`timescale 1ns / 1ps

module testbench();
    reg [15:0] in;
    reg [1:0] mode;
    wire [7:0] count;
    wire [3:0] val;
    
    LD_combined inst1( .in(in), .count(count), .valid(val), .mode(mode));
    
    initial
        begin
            // --- MODE 00 (4-bit) ---
        #5 mode = 2'b00; in = 16'h27B4; 
        // Trace: 0010(LOD1) 0111(Inv->0000->Invld) 1011(LOD1) 0100(Inv->0011->LOD1)
        // Exp: Count=8'h45, Valid=4'b1011
        
        #5 mode = 2'b00; in = 16'hFEDA; 
        // Trace: 1111(Invld) 1110(Inv->0001->LOD3) 1101(Inv->0010->LOD2) 1010(LOD2)
        // Exp: Count=8'h3A, Valid=4'b0111

        // --- MODE 01 (8-bit) ---
        #5 mode = 2'b01; in = 16'h08F0;
        // Trace: 00001000(LOD4) | 11110000(Inv->00001111->LOD4)
        // Exp: Count=8'h24, Valid=0101

        #5 mode = 2'b01; in = 16'h807F;
        // Trace: 10000000(Zero) | 01111111(Inv->Zero)
        // Exp: Count=8'h00, Valid=4'b0000

        // --- MODE 10 (16-bit) ---
        #5 mode = 2'b10; in = 16'h0001;
        // Trace: 0000...0001 -> LOD 14
        // Exp: Count=8'h0E, Valid=4'b0001

        #5 mode = 2'b10; in = 16'hFFFE;
        // Trace: 1111...1110 -> Inv -> 0000...0001 -> LOD 14
        // Exp: Count=8'h0F, Valid=4'b0001

        #5 mode = 2'b10; in = 16'h4000;
        // Trace: 0100... (Pos, Reg 1). Inv -> 0011... -> LOD 2
        // Exp: Count=8'h02, Valid=4'b0001

        #5 $finish;
        end
        
    initial $monitor($time, " count=%h, valid=%h", count, val);
    
endmodule

