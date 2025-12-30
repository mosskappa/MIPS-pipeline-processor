`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Contribution 9-2: Polynomial Exponential Function
// 
// Implements exp(x) using Range Reduction + Polynomial Approximation
// Method: e^x = 2^(x * log2(e)) = 2^(i+f) = 2^i * 2^f
//
// SIMPLIFIED VERSION: Combinational logic for clarity
// (Can be pipelined for higher clock speeds)
//
// Author: JUNYI LIU
// Date: December 2025
//////////////////////////////////////////////////////////////////////////////////

module poly_exp #(
    parameter WIDTH = 16,           // Total bit width
    parameter FRAC_BITS = 12        // Fractional bits (Q4.12 format)
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  valid_in,
    input  wire signed [WIDTH-1:0] x_in,      // Input in Q4.12 format
    output reg                   valid_out,
    output reg  signed [WIDTH-1:0] exp_out    // Output exp(x) in Q4.12 format
);

    // =========================================================================
    // Constants (Q4.12 fixed-point format, 12 fractional bits)
    // =========================================================================
    
    // log2(e) = 1.4427 ≈ 5909 in Q4.12 (1.4427 * 4096 = 5909)
    localparam signed [31:0] LOG2_E = 32'sd5909;
    
    // Polynomial coefficients for 2^f where f in [0, 1)
    // a0 = 1.0         = 4096 in Q4.12
    // a1 = ln(2)       = 0.6931 * 4096 = 2839
    // a2 = ln(2)^2/2   = 0.2402 * 4096 = 984
    localparam signed [31:0] A0 = 32'sd4096;   // 1.0
    localparam signed [31:0] A1 = 32'sd2839;   // 0.6931
    localparam signed [31:0] A2 = 32'sd984;    // 0.2402
    
    // =========================================================================
    // Internal wires for combinational computation
    // =========================================================================
    
    // Step 1: x * log2(e)
    wire signed [31:0] x_log2e;
    assign x_log2e = (x_in * LOG2_E) >>> FRAC_BITS;  // Q4.12 result
    
    // Step 2: Separate integer and fractional parts
    wire signed [4:0] int_part;
    wire signed [WIDTH-1:0] frac_part;
    
    assign int_part = x_log2e[FRAC_BITS +: 5];  // Integer part (5 bits for -16 to 15)
    assign frac_part = {4'b0000, x_log2e[FRAC_BITS-1:0]};  // Fractional part [0, 1)
    
    // Step 3: Compute polynomial 2^f ≈ a0 + a1*f + a2*f^2
    wire signed [31:0] f_squared;
    wire signed [31:0] poly_result;
    
    assign f_squared = (frac_part * frac_part) >>> FRAC_BITS;
    assign poly_result = A0 + 
                         ((A1 * frac_part) >>> FRAC_BITS) + 
                         ((A2 * f_squared) >>> FRAC_BITS);
    
    // Step 4: Apply 2^i by shifting
    wire signed [WIDTH-1:0] shifted_result;
    
    // Clamp shift amount to valid range
    wire [3:0] shift_amt;
    assign shift_amt = (int_part > 15) ? 4'd15 : 
                       (int_part < -15) ? 4'd15 : 
                       (int_part >= 0) ? int_part[3:0] : (-int_part[3:0]);
    
    assign shifted_result = (int_part >= 0) ? 
                            (poly_result[WIDTH-1:0] << shift_amt) :
                            (poly_result[WIDTH-1:0] >> shift_amt);
    
    // =========================================================================
    // Output register (1 cycle latency)
    // =========================================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            exp_out <= 0;
            valid_out <= 0;
        end else begin
            valid_out <= valid_in;
            exp_out <= shifted_result;
        end
    end

endmodule
