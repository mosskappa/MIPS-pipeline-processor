`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Contribution 10: Polynomial Natural Logarithm Function
// 
// Implements ln(x) using Range Reduction + Polynomial Approximation
// Method: ln(x) = ln(2^k * m) = k * ln(2) + ln(m), where m ∈ [1, 2)
//
// Author: JUNYI LIU
// Date: January 2026
//////////////////////////////////////////////////////////////////////////////////

module poly_log #(
    parameter WIDTH = 16,           // Total bit width
    parameter FRAC_BITS = 12        // Fractional bits (Q4.12 format)
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  valid_in,
    input  wire [WIDTH-1:0]      x_in,      // Input in Q4.12 format (must be > 0)
    output reg                   valid_out,
    output reg  signed [WIDTH-1:0] ln_out   // Output ln(x) in Q4.12 format
);

    // =========================================================================
    // Constants (Q4.12 fixed-point format, 12 fractional bits)
    // =========================================================================
    
    // ln(2) = 0.6931 ≈ 2839 in Q4.12 (0.6931 * 4096 = 2839)
    localparam signed [31:0] LN_2 = 32'sd2839;
    
    // Polynomial coefficients for ln(1+x) where x ∈ [0, 1)
    // ln(1+x) ≈ x - x²/2 + x³/3 (Taylor series)
    // Simplified to 2nd order: ln(1+x) ≈ a1*x + a2*x²
    // a1 = 1.0, a2 = -0.5 (for better accuracy near x=0)
    localparam signed [31:0] A1 = 32'sd4096;    // 1.0
    localparam signed [31:0] A2 = -32'sd2048;   // -0.5
    
    // =========================================================================
    // Range Reduction: Find k such that x = 2^k * m, m ∈ [1, 2)
    // =========================================================================
    
    // Count leading zeros to find the position of the MSB
    // This determines k = floor(log2(x))
    
    reg [3:0] k_value;           // Integer part (log2(x) integer)
    reg [WIDTH-1:0] m_value;     // Normalized mantissa in [1, 2) range
    reg signed [31:0] k_signed;
    
    // Find the highest set bit position
    integer i;
    always @(*) begin
        k_value = 0;
        m_value = x_in;
        
        // Find position of MSB (simplified for synthesis)
        // For Q4.12: integer part is bits [15:12]
        if (x_in[15]) k_value = 4'd3;
        else if (x_in[14]) k_value = 4'd2;
        else if (x_in[13]) k_value = 4'd1;
        else if (x_in[12]) k_value = 4'd0;
        else if (x_in[11]) k_value = 4'd15; // -1 in 4-bit (x < 1)
        else if (x_in[10]) k_value = 4'd14; // -2
        else if (x_in[9])  k_value = 4'd13; // -3
        else k_value = 4'd12; // -4 or smaller
        
        // Normalize to [1, 2): shift so that MSB is at position 12
        if (k_value < 4'd8) begin
            // k >= 0: shift right
            m_value = x_in >> k_value;
        end else begin
            // k < 0: shift left
            m_value = x_in << (16 - k_value);
        end
        
        // Convert k to signed (handle negative k for x < 1)
        if (k_value < 4'd8)
            k_signed = k_value;
        else
            k_signed = k_value - 16; // Convert to negative
    end
    
    // =========================================================================
    // Polynomial Approximation: ln(m) where m ∈ [1, 2)
    // =========================================================================
    
    // Let y = m - 1, so y ∈ [0, 1)
    // ln(1+y) ≈ y - y²/2
    
    wire signed [31:0] y_value;
    wire signed [31:0] y_squared;
    wire signed [31:0] poly_result;
    wire signed [31:0] final_result;
    
    // y = m - 1.0 (subtract Q4.12 representation of 1.0 = 4096)
    assign y_value = m_value - 32'sd4096;
    
    // y² / 4096 (to keep in Q4.12)
    assign y_squared = (y_value * y_value) >>> FRAC_BITS;
    
    // ln(1+y) ≈ a1*y + a2*y² = y - y²/2
    assign poly_result = y_value + ((A2 * y_squared) >>> FRAC_BITS);
    
    // Final result: ln(x) = k * ln(2) + ln(m)
    assign final_result = (k_signed * LN_2) + poly_result;
    
    // =========================================================================
    // Output register (1 cycle latency)
    // =========================================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ln_out <= 0;
            valid_out <= 0;
        end else begin
            valid_out <= valid_in;
            // Clamp to output width
            ln_out <= final_result[WIDTH-1:0];
        end
    end

endmodule
