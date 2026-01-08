`timescale 1ns / 1ps

module tb_LD_clocked();
    reg clk=1'b0;
    reg [31:0] in;
    reg [1:0] mode;
    wire [11:0] count;
    wire [3:0] val;
    
    always #5 clk = ~clk;
    
    LD_clocked inst1( .clk(clk), .in(in), .count(count), .valid(val), .mode(mode));
    
    
    
    initial
        begin

        // MODE 00: 8-BIT PRECISION (4 Parallel Operations)
        
        // We check 4 bytes: [31:24], [23:16], [15:8], [7:0]
        
        // CASE 1: Standard Posits
        // In: 08 (LZ=4), F0 (LZ=4), 20 (LZ=2), C0 (LZ=2)
        // Counts: 4, 4, 2, 2 -> Binary: 100_100_010_010
        mode = 2'b00; in = 32'h08F020C0;
        // Exp Count: 12'h912
        // Exp Valid: 4'hF

       // CASE 2: Regime Crossing
        // In: 40 (LZ=2), BF (LZ=2), 10 (LZ=3), EF (LZ=3)
        // Counts: 2, 2, 3, 3 -> Binary: 010_010_011_011 -> 0100_1001_1011
        #10 mode = 2'b00; in = 32'h40BF10EF;
        // Exp Count: 12'h49B
        // Exp Valid: 4'hF
        
        // CASE 3: Edge Cases (Max Zeros / Invalid)
        // In: 00 (LZ=0), 7F (LZ=7), 80 (LZ=0), FF (LZ=7)
        // Counts: 0, 0, 0, 0 
        #10 mode = 2'b00; in = 32'h007F80FF;
        // Exp Count: 12'h000
        // Exp Valid: 4'h5 (Valid bits: 0, 0, 0, 0)

 

        // CASE 4: Random Values (Your specific query)
        // In: 35 (LZ=2), CA (LZ=2), 92 (LZ=3), 6D (LZ=3)
        // Counts: 2, 2, 3, 3 -> Binary: 010_010_011_011 -> 0100_1001_1011
        #10 mode = 2'b00; in = 32'h35CA926D;
        // Exp Count: 12'h49B
        // Exp Valid: 4'hF
        
        
        
        
        // MODE 01: 16-BIT PRECISION (2 Parallel Operations)
        
        // We check 2 words: [31:16], [15:0]

        // CASE 5: Long Regimes (Crosses Byte Boundary)
        // In: 0010 (LZ=11), FFEF (LZ=11)
        // 0010 (0000000000010000): Pos, Reg0. LZ=11.
        // FFEF (1111111111101111): Neg, Reg1. Inv->0000000000010000. LZ=11.
        #10 mode = 2'b01; in = 32'h0010FFEF;
        // Exp Count: 0, B, B -> 12'h0BB
        // Exp Valid: 0, 1, 1 -> 4'h5 (Bits 0 and 2 high)

        // CASE 6: Short Regimes
        // In: 4000 (LZ=2), C000 (LZ=2)
        // 4000 (0100...): Pos, Reg1. Inv->0011.... LZ=2.
        #10 mode = 2'b01; in = 32'h4000C000;
        // Exp Count: 0, 2, 2 -> 12'h022
        // Exp Valid: 0, 1, 1 -> 4'h5

        // CASE 7: Crossing Bit 8 boundary exactly
        // In: 0100 (LZ=7), FEFF (LZ=7)
        // 0100 (0000000100000000): LZ=7.
        #10 mode = 2'b01; in = 32'h0100FEFF;
        // Exp Count: 0, 7, 7 -> 12'h077
        // Exp Valid: 0, 1, 1 -> 4'h5

        // CASE 8: Invalid / All Zero Regimes
        // In: 7FFF (LZ=Invalid), 8000 (LZ=Invalid)
        #10 mode = 2'b01; in = 32'h7FFF8000;
        // Exp Count: 0, 0, 0 -> 12'h000
        // Exp Valid: 0, 0, 0 -> 4'h0


       
        // MODE 10: 32-BIT PRECISION (1 Operation)
      
        
        // CASE 9: Massive Regime (Deep Zero)
        // In: 00000002 (000...0010)
        // LZ = 30. (Decimal 30 = Hex 1E)
        #10 mode = 2'b10; in = 32'h00000002;
        // Exp Count: 0, 1E -> 12'h01E
        // Exp Valid: 1 -> 4'h1


        // CASE 10: Standard 32-bit Posit
        // In: 40000000 (0100...) -> Inv 0011... -> LZ=2
        #10 mode = 2'b10; in = 32'h40000000;
        // Exp Count: 0, 02 -> 12'h002
        // Exp Valid: 1 -> 4'h1
        
         // CASE 11: Massive Regime (Deep One / Negative)
        // In: FFFFFFFD (111...1101)
        // Inv -> 000...0010. LZ = 30.
        #10 mode = 2'b10; in = 32'hFFFFFFFD;
        // Exp Count: 0, 1E -> 12'h01E
        // Exp Valid: 1 -> 4'h1

        // CASE 12: Regime Crossing 16-bit boundary
        // In: 00008000 (0000000000000000 1000...)
        // LZ = 16. (Hex 10)
        #10 mode = 2'b10; in = 32'h00008000;
        // Exp Count: 0, 10 -> 12'h010
        // Exp Valid: 1 -> 4'h1

        #10 $finish;
        
        end
        
    initial $monitor($time, " count=%h, valid=%h", count, val);
    
endmodule
