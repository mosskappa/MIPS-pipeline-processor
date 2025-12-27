/*
================================================================================
-- Module: tb_cordic.v
-- Description: Testbench for the CORDIC sine/cosine calculator.
-- Source: https://github.com/Pranav-2045/CORDIC
-- Author: Pranav-2045
-- Integrated by: 劉俊逸 (M143140014) for Computer Architecture Final Project
================================================================================
*/
`timescale 1ns / 1ps

module tb_cordic;

    // Parameters
    localparam DATA_WIDTH = 16;
    localparam ITERATIONS = 16;
    localparam CLK_PERIOD = 10; // 10 ns clock period
    localparam real ERROR_TOLERANCE = 0.01; // 1% error tolerance

    // Testbench signals
    reg                         clk;
    reg                         rst_n;
    reg                         start;
    reg  signed [DATA_WIDTH-1:0] angle_in;
    wire signed [DATA_WIDTH-1:0] x_out;
    wire signed [DATA_WIDTH-1:0] y_out;
    wire                        done;
    
    // Test metrics
    integer tests_passed;
    integer tests_total;

    // Instantiate the Design Under Test (DUT)
    cordic #(
        .DATA_WIDTH(DATA_WIDTH),
        .ITERATIONS(ITERATIONS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .angle_in(angle_in),
        .x_out(x_out),
        .y_out(y_out),
        .done(done)
    );

    // Clock generator
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Testing task
    task test_angle;
        input real angle_degrees;
        reg signed [DATA_WIDTH-1:0] scaled_angle;
        real expected_cos, expected_sin;
        real actual_cos, actual_sin;
        real cos_error, sin_error;
        real pi;
        reg pass;

        begin
            pi = 3.1415926535;
            
            // Convert angle to the DUT's fixed-point format
            scaled_angle = angle_degrees * 16384.0 / 90.0;
            
            // Calculate expected results
            expected_cos = $cos(angle_degrees * pi / 180.0);
            expected_sin = $sin(angle_degrees * pi / 180.0);

            $display("-----------------------------------------------------");
            $display("Testing angle: %0.0f degrees", angle_degrees);
            
            // Start the test
            angle_in <= scaled_angle;
            start <= 1;
            @(posedge clk);
            start <= 0;
            
            // Wait for the done signal
            wait(done);
            
            // Convert DUT's fixed-point output back to real numbers
            actual_cos = x_out / 16384.0;
            actual_sin = y_out / 16384.0;
            
            // Calculate errors
            cos_error = (actual_cos - expected_cos);
            sin_error = (actual_sin - expected_sin);
            if (cos_error < 0) cos_error = -cos_error;
            if (sin_error < 0) sin_error = -sin_error;
            
            // Check pass/fail
            pass = (cos_error < ERROR_TOLERANCE) && (sin_error < ERROR_TOLERANCE);
            tests_total = tests_total + 1;
            
            // Display results
            $display("  cos: DUT=%0.4f, Expected=%0.4f, Error=%0.4f", actual_cos, expected_cos, cos_error);
            $display("  sin: DUT=%0.4f, Expected=%0.4f, Error=%0.4f", actual_sin, expected_sin, sin_error);
            
            if (pass) begin
                $display("  Result: [PASS]");
                tests_passed = tests_passed + 1;
            end else begin
                $display("  Result: [FAIL] (Error > %0.2f%%)", ERROR_TOLERANCE * 100);
            end
            
            @(posedge clk);
        end
    endtask


    // Main test sequence
    initial begin
        // Initialize signals
        rst_n <= 0;
        start <= 0;
        angle_in <= 0;
        tests_passed = 0;
        tests_total = 0;
        
        // Apply reset
        # (CLK_PERIOD * 2);
        rst_n <= 1;
        # (CLK_PERIOD);
        
        $display("");
        $display("╔═══════════════════════════════════════════════════════════════════════╗");
        $display("║     CONTRIBUTION 9: CORDIC TRIGONOMETRIC FUNCTIONS                    ║");
        $display("║     Author: 劉俊逸 (M143140014)                                       ║");
        $display("╚═══════════════════════════════════════════════════════════════════════╝");
        $display("");
        
        // Run tests for various angles
        test_angle(0.0);
        test_angle(30.0);
        test_angle(45.0);
        test_angle(60.0);
        test_angle(90.0);
        test_angle(-30.0);
        test_angle(-90.0);
        
        $display("");
        $display("╔═══════════════════════════════════════════════════════════════════════╗");
        $display("║                        SUMMARY                                        ║");
        $display("╠═══════════════════════════════════════════════════════════════════════╣");
        $display("║   Tests Passed: %0d / %0d                                              ║", tests_passed, tests_total);
        if (tests_passed == tests_total)
            $display("║   Status:       ALL PASSED ★★★                                     ║");
        else
            $display("║   Status:       FAILURES DETECTED                                    ║");
        $display("╚═══════════════════════════════════════════════════════════════════════╝");
        $display("");
        
        $finish;
    end

endmodule
