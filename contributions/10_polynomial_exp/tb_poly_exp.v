`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench for Polynomial Exp Function
// 
// Tests exp(x) implementation using polynomial approximation
//
// Author: JUNYI LIU
// Date: December 2025
//////////////////////////////////////////////////////////////////////////////////

module tb_poly_exp;

    // Parameters
    parameter WIDTH = 16;
    parameter FRAC_BITS = 12;
    
    // Signals
    reg clk;
    reg rst;
    reg valid_in;
    reg signed [WIDTH-1:0] x_in;
    wire valid_out;
    wire signed [WIDTH-1:0] exp_out;
    
    // Test tracking
    integer test_count;
    integer pass_count;
    real x_real, exp_expected, exp_actual, error_percent;
    
    // Simulation control
    reg sim_done;
    
    // Instantiate DUT
    poly_exp #(
        .WIDTH(WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) DUT (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .x_in(x_in),
        .valid_out(valid_out),
        .exp_out(exp_out)
    );
    
    // Clock generation - STOPS when sim_done is set
    initial clk = 0;
    always begin
        if (sim_done) begin
            $display("Simulation complete - clock stopped");
            #10;  // Small delay then truly stop
            $finish;
        end
        #5 clk = ~clk;
    end
    
    // Convert Q4.12 to real
    function real q4_12_to_real;
        input signed [WIDTH-1:0] q_val;
        begin
            q4_12_to_real = $itor(q_val) / 4096.0;
        end
    endfunction
    
    // Convert real to Q4.12
    function signed [WIDTH-1:0] real_to_q4_12;
        input real r_val;
        begin
            real_to_q4_12 = $rtoi(r_val * 4096.0);
        end
    endfunction
    
    // Main test sequence
    initial begin
        $display("==============================================");
        $display("  Polynomial Exp Function Testbench");
        $display("  Contribution 9-2: Range Reduction + Taylor");
        $display("==============================================");
        $display("");
        
        // Initialize
        sim_done = 0;
        rst = 1;
        valid_in = 0;
        x_in = 0;
        test_count = 0;
        pass_count = 0;
        
        // Reset
        #100;
        rst = 0;
        #50;
        
        $display("Testing exp(x) with standard values:");
        $display("----------------------------------------------");
        
        // Test 1: exp(0) = 1.0
        test_count = test_count + 1;
        x_in = 16'sd0;  // 0.0 in Q4.12
        valid_in = 1;
        #20;
        exp_actual = q4_12_to_real(exp_out);
        exp_expected = 1.0;
        error_percent = ((exp_actual - exp_expected) / exp_expected) * 100.0;
        if (error_percent < 0) error_percent = -error_percent;
        if (error_percent < 15.0) begin
            $display("[PASS] exp(0.0) = %.4f (expected: 1.0000)", exp_actual);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] exp(0.0) = %.4f (expected: 1.0000)", exp_actual);
        end
        valid_in = 0;
        #20;
        
        // Test 2: exp(0.5) = 1.6487
        test_count = test_count + 1;
        x_in = 16'sd2048;  // 0.5 in Q4.12 (0.5 * 4096 = 2048)
        valid_in = 1;
        #20;
        exp_actual = q4_12_to_real(exp_out);
        exp_expected = 1.6487;
        error_percent = ((exp_actual - exp_expected) / exp_expected) * 100.0;
        if (error_percent < 0) error_percent = -error_percent;
        if (error_percent < 15.0) begin
            $display("[PASS] exp(0.5) = %.4f (expected: 1.6487)", exp_actual);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] exp(0.5) = %.4f (expected: 1.6487)", exp_actual);
        end
        valid_in = 0;
        #20;
        
        // Test 3: exp(1.0) = 2.7183
        test_count = test_count + 1;
        x_in = 16'sd4096;  // 1.0 in Q4.12
        valid_in = 1;
        #20;
        exp_actual = q4_12_to_real(exp_out);
        exp_expected = 2.7183;
        error_percent = ((exp_actual - exp_expected) / exp_expected) * 100.0;
        if (error_percent < 0) error_percent = -error_percent;
        if (error_percent < 15.0) begin
            $display("[PASS] exp(1.0) = %.4f (expected: 2.7183)", exp_actual);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] exp(1.0) = %.4f (expected: 2.7183)", exp_actual);
        end
        valid_in = 0;
        #20;
        
        // Test 4: exp(-0.5) = 0.6065
        test_count = test_count + 1;
        x_in = -16'sd2048;  // -0.5 in Q4.12
        valid_in = 1;
        #20;
        exp_actual = q4_12_to_real(exp_out);
        exp_expected = 0.6065;
        error_percent = ((exp_actual - exp_expected) / exp_expected) * 100.0;
        if (error_percent < 0) error_percent = -error_percent;
        if (error_percent < 15.0) begin
            $display("[PASS] exp(-0.5) = %.4f (expected: 0.6065)", exp_actual);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] exp(-0.5) = %.4f (expected: 0.6065)", exp_actual);
        end
        valid_in = 0;
        #20;

        // Summary
        #50;
        $display("");
        $display("==============================================");
        $display("  Test Summary: %0d/%0d PASSED", pass_count, test_count);
        $display("==============================================");
        
        if (pass_count == test_count)
            $display("  ALL TESTS PASSED!");
        else
            $display("  SOME TESTS FAILED");
        
        $display("");
        $display("Performance: Polynomial exp() = 1 cycle latency");
        $display("vs CORDIC Hyperbolic = 16 cycles latency");
        $display("==============================================");
        
        // Signal simulation complete
        #50;
        sim_done = 1;
    end

endmodule
