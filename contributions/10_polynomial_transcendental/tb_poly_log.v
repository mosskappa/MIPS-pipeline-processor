`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench for Polynomial Natural Logarithm (poly_log.v)
// 
// Tests ln(x) with standard test cases
// 
// Author: JUNYI LIU
// Date: January 2026
//////////////////////////////////////////////////////////////////////////////////

module tb_poly_log;

    // Parameters matching DUT
    parameter WIDTH = 16;
    parameter FRAC_BITS = 12;
    
    // Test signals
    reg clk;
    reg rst;
    reg valid_in;
    reg [WIDTH-1:0] x_in;
    wire valid_out;
    wire signed [WIDTH-1:0] ln_out;
    
    // Instantiate DUT
    poly_log #(
        .WIDTH(WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) dut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .x_in(x_in),
        .valid_out(valid_out),
        .ln_out(ln_out)
    );
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Test vectors (Q4.12 format: multiply by 4096)
    // x = 1.0 -> ln(1.0) = 0.0
    // x = 2.0 -> ln(2.0) = 0.6931
    // x = e ≈ 2.7183 -> ln(e) = 1.0
    // x = 0.5 -> ln(0.5) = -0.6931
    
    reg [WIDTH-1:0] test_x [0:3];
    reg signed [WIDTH-1:0] expected_ln [0:3];
    real real_x [0:3];
    real real_expected [0:3];
    
    integer test_num;
    integer pass_count;
    real result_real;
    real error_percent;
    
    initial begin
        // Initialize test vectors
        // Q4.12 format: value * 4096
        test_x[0] = 16'd4096;   // 1.0
        test_x[1] = 16'd8192;   // 2.0
        test_x[2] = 16'd11134; // 2.7183 (≈ e)
        test_x[3] = 16'd2048;   // 0.5
        
        expected_ln[0] = 16'sd0;      // ln(1.0) = 0.0
        expected_ln[1] = 16'sd2839;   // ln(2.0) = 0.6931 * 4096
        expected_ln[2] = 16'sd4096;   // ln(e) = 1.0 * 4096
        expected_ln[3] = -16'sd2839;  // ln(0.5) = -0.6931 * 4096
        
        real_x[0] = 1.0;
        real_x[1] = 2.0;
        real_x[2] = 2.7183;
        real_x[3] = 0.5;
        
        real_expected[0] = 0.0;
        real_expected[1] = 0.6931;
        real_expected[2] = 1.0;
        real_expected[3] = -0.6931;
        
        // Initialize
        clk = 0;
        rst = 1;
        valid_in = 0;
        x_in = 0;
        pass_count = 0;
        
        // Display header
        $display("");
        $display("╔══════════════════════════════════════════════════════════════════════════════╗");
        $display("║         POLYNOMIAL NATURAL LOGARITHM (ln(x)) - TESTBENCH RESULTS            ║");
        $display("║               Contribution 10: poly_log.v Verification                       ║");
        $display("╠══════════════════════════════════════════════════════════════════════════════╣");
        $display("║ Method: Range Reduction + Taylor Series Approximation                        ║");
        $display("║ Format: Q4.12 Fixed-Point (16-bit)                                          ║");
        $display("╚══════════════════════════════════════════════════════════════════════════════╝");
        $display("");
        
        // Release reset
        #20 rst = 0;
        #10;
        
        // Run tests
        $display("┌──────┬────────────┬──────────────┬──────────────┬──────────┬────────┐");
        $display("│ Test │   Input x  │ Expected ln  │  Result ln   │  Error   │ Status │");
        $display("├──────┼────────────┼──────────────┼──────────────┼──────────┼────────┤");
        
        for (test_num = 0; test_num < 4; test_num = test_num + 1) begin
            // Apply input
            x_in = test_x[test_num];
            valid_in = 1;
            #10;
            valid_in = 0;
            
            // Wait for result
            #20;
            
            // Calculate result as real number
            result_real = $signed(ln_out) / 4096.0;
            
            // Calculate error
            if (real_expected[test_num] == 0.0)
                error_percent = (result_real == 0.0) ? 0.0 : 100.0;
            else
                error_percent = ((result_real - real_expected[test_num]) / real_expected[test_num]) * 100.0;
            
            if (error_percent < 0) error_percent = -error_percent;
            
            // Check pass/fail (allow up to 15% error for approximation)
            if (error_percent < 15.0 || (real_expected[test_num] == 0.0 && result_real < 0.1 && result_real > -0.1)) begin
                $display("│  %0d   │   %7.4f  │    %7.4f   │    %7.4f   │  %5.2f%%  │  PASS  │", 
                         test_num + 1, real_x[test_num], real_expected[test_num], result_real, error_percent);
                pass_count = pass_count + 1;
            end else begin
                $display("│  %0d   │   %7.4f  │    %7.4f   │    %7.4f   │  %5.2f%%  │  FAIL  │", 
                         test_num + 1, real_x[test_num], real_expected[test_num], result_real, error_percent);
            end
            
            #10;
        end
        
        $display("└──────┴────────────┴──────────────┴──────────────┴──────────┴────────┘");
        $display("");
        
        // Summary
        $display("════════════════════════════════════════════════════════════════════════════════");
        if (pass_count == 4) begin
            $display("                    ✓ ALL %0d/4 TESTS PASSED!", pass_count);
        end else begin
            $display("                    ✗ %0d/4 TESTS PASSED, %0d FAILED", pass_count, 4 - pass_count);
        end
        $display("════════════════════════════════════════════════════════════════════════════════");
        $display("");
        
        #50;
        $finish;
    end

endmodule
