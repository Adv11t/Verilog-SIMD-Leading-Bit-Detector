`timescale 1ns / 1ps

module LD_clocked(
    input clk,
    input [31:0] in, 
    output reg [11:0] count, 
    output reg [3:0] valid, 
    input [1:0] mode);

    wire [11:0] count_wr;
    wire [3:0] valid_wr;
    
    LD_comb ld( .in(in), .mode(mode), .count(count_wr), .valid(valid_wr));
    
    always @(posedge clk)
        begin
            count <= count_wr;
            valid <= valid_wr;
        end

endmodule


//4 bit base LOD module
//valid: check if all bits are zero / no one -> valid=0
//count: detects the position(from left) of first '1' encountered 
//eg: in = 0001, count=11 (that is 3 from left), valid=1

module lod4(input [3:0] in, output [1:0] count4, output valid);
    wire countup, countdown;
    wire valid1, valid0;
    assign valid1 = |in[3:2];
    assign valid0 = |in[1:0];
    assign countup = (in[3])? 1'b0 : (in[2]) ? 1'b1 : 1'b0;
    assign countdown = (in[1]) ? 1'b0 : (in[0]) ? 1'b1 : 1'b0;
    assign valid = valid0 | valid1;
    assign count4 = (valid1) ? {1'b0,countup} : (valid0) ? {1'b1,countdown}: 2'd0;
endmodule


//Combined multiprecion detector supporting 3 precisions: 
// in: 32 bit word, 
//count: position of terminating bit or count=(no. of identical bit regime)+1
// mode = 00 8 bit precision, count: each three bits represent count for each byte, valid: each 1 bit correspond to valid of a byte
// mode = 01 16 bit precision, count: first 4 bits are redundant, remaining 2 set of 4 bits each present count of one 16 bit
// mode = 10 32 bit precision, count: first 7 bits are redundant, remaining 5 bits represent cound of whole 32 bit word

//eg:
        // In: 08 (LZ=4), F0 (LZ=4), 20 (LZ=2), C0 (LZ=2)
        // Binary: 00001000 | 11110000 | 00100000 | 11000000
        // mode = 2'b00; in = 32'h08F020C0;
        // Exp Count: 4, 4, 2, 2 -> 12'h4422 //gives position of terminating bit
        // Exp Valid: 1, 1, 1, 1 -> 4'hF
        
//Logic: Step1: divide the 32 bit word into four bytes, find control bit
//              control bit: the 1st regime bit (after sign)
//              if control bit=0, directly use lod on it
//              if control bit=1, invert that set then use lod on it
//Step 2: invert bytes based on control bits by <XOR> operation
//step 3: force the updated sign bit =0 based on modes then use lod


module LD_comb(input [31:0] in, output [11:0] count, output [3:0] valid, input [1:0] mode);

    wire valid4a,valid4b,valid4c,valid4d,valid4e,valid4f,valid4g,valid4h,valid8a,valid8b,valid8c,valid8d,valid16a,valid16b,valid32;
    wire [1:0] count4a,count4b,count4c,count4d,count4e,count4f,count4g,count4h;
    wire [2:0] count8a,count8b,count8c,count8d;
    wire [3:0] count16a,count16b;
    wire [4:0] count32;
    wire [31:0] updatedin;
    
  
    // STEP 1: Determine Inversion Flags (Regime Handling)
    
    //Byte 3 (31:24): Always controlled by in[30] (Global Regime Start).
    //Byte 2 (23:16): If 8-bit mode, controlled by in[22]. Else (16/32), it follows in[30].
    //Byte 1 (15:8): If 32-bit mode, follows in[30]. Else (8/16), controlled by in[14].
    //Byte 0 (7:0): If 8-bit mode, in[6]. If 16-bit, in[14]. If 32-bit, in[30].
    
    wire inv_byte3 = in[30];
    wire inv_byte2 = (mode == 2'b00) ? in[22] : in[30];
    wire inv_byte1 = (mode == 2'b10) ? in[30] : in[14];
    wire inv_byte0 = (mode == 2'b00) ? in[6]  : 
                     (mode == 2'b01) ? in[14] : in[30];

    // STEP 2: Apply Inversion (Conditional XOR)
    wire [31:0] inverted_in;    
    assign inverted_in = in ^ { {8{inv_byte3}}, {8{inv_byte2}}, {8{inv_byte1}}, {8{inv_byte0}} };
    
    // STEP 3: Sign Masking (Force Sign Bits to 0)
    wire not_mode_8b = mode[1] | mode[0]; // Logic 1 if Mode is 01 or 10

    assign updatedin = {
        1'b0,                           // Bit 31: Global Sign (Always 0)
        inverted_in[30:24],             // Data
        
        inverted_in[23] & not_mode_8b,  // Bit 23: Sign only in 8b mode (00)
        inverted_in[22:16],             // Data
        
        inverted_in[15] & mode[1],      // Bit 15: Sign in 8b(00) and 16b(01). Pass only in 32b(10)
        inverted_in[14:8],              // Data
        
        inverted_in[7] & not_mode_8b,   // Bit 7: Sign only in 8b mode (00)
        inverted_in[6:0]                // Data
    };
                       
    lod4 u4a(.in(updatedin[3:0]), .count4(count4a), .valid(valid4a));
    lod4 u4b(.in(updatedin[7:4]), .count4(count4b), .valid(valid4b));
    lod4 u4c(.in(updatedin[11:8]), .count4(count4c), .valid(valid4c));
    lod4 u4d(.in(updatedin[15:12]), .count4(count4d), .valid(valid4d));
    lod4 u4e(.in(updatedin[19:16]), .count4(count4e), .valid(valid4e));
    lod4 u4f(.in(updatedin[23:20]), .count4(count4f), .valid(valid4f));
    lod4 u4g(.in(updatedin[27:24]), .count4(count4g), .valid(valid4g));
    lod4 u4h(.in(updatedin[31:28]), .count4(count4h), .valid(valid4h));
    
    // 8bit logic
    assign valid8a = valid4a|valid4b;
    assign valid8b = valid4c|valid4d;
    assign valid8c = valid4e|valid4f;
    assign valid8d = valid4g|valid4h;
    assign count8a = (valid4b) ? {1'b0,count4b} : (valid4a) ? {1'b1,count4a} : 3'b000; 
    assign count8b = (valid4d) ? {1'b0,count4d} : (valid4c) ? {1'b1,count4c} : 3'b000; 
    assign count8c = (valid4f) ? {1'b0,count4f} : (valid4e) ? {1'b1,count4e} : 3'b000; 
    assign count8d = (valid4h) ? {1'b0,count4h} : (valid4g) ? {1'b1,count4g} : 3'b000; 
    
    //16 bit logic
    assign valid16a = valid8a|valid8b;
    assign valid16b = valid8c|valid8d;
    assign count16a = (valid8b) ? {1'b0,count8b} : (valid8a) ?  {1'b1,count8a}: 4'd0;
    assign count16b = (valid8d) ? {1'b0,count8d} : (valid8c) ?  {1'b1,count8c}: 4'd0;
    
    // 32 bit logic
    assign valid32 = valid16a|valid16b;
    assign count32 = (valid16b) ? {1'b0,count16b} : (valid16a) ? {1'b1,count16a} : 5'd0;
    
    reg [11:0] countsel;
    reg [3:0] validsel;
    always @(*) begin
        case (mode)
             2'b00: begin
                countsel = {count8d,count8c,count8b,count8a};
                validsel = {valid8d,valid8c,valid8b,valid8a};
            end
            2'b01: begin
                countsel = {4'd0,count16b,count16a};
                validsel = {1'd0,valid16b,1'd0,valid16a};
            end
            2'b10: begin
                countsel = {7'd0,count32};
                validsel = {3'd0,valid32};        
            end
            default: begin
                countsel = 12'd0;
                validsel = 4'd0;
            end
        endcase
    end
    
    assign count = countsel;
    assign valid = validsel;
endmodule
