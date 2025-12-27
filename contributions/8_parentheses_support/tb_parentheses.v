`timescale 1ns/1ns

//=============================================================================
// CONTRIBUTION 8: Expression Parser with Parentheses & Associativity
// Author: 劉俊逸 (M143140014)
//
// Features Verified:
// 1. Parentheses Handling: ( ) altering precedence
// 2. Right Associativity: 2^3^2 = 2^9 = 512 (not 64)
// 3. Mixed Operators: + - * / ^ ( )
//=============================================================================

module tb_parentheses;
    reg clk;
    reg rst;
    
    // Inputs to Top
    reg input_stb;
    reg [31:0] input_data;
    reg is_input_operator;
    
    // Outputs from Top
    wire input_ack;
    wire output_stb;
    wire [31:0] output_data;
    reg output_ack;
    
    // Metrics
    integer tests_passed;
    integer tests_total;
    
    // Instantiate Top
    expression_parser_top dut(
        .clk(clk),
        .rst(rst),
        .input_stb(input_stb),
        .input_data(input_data),
        .is_input_operator(is_input_operator),
        .input_ack(input_ack),
        .output_stb(output_stb),
        .output_data(output_data),
        .output_ack(output_ack)
    );
    
    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Operator Codes for Display
    // + (000), - (001), * (010), / (011), ^ (100), = (101), ( (110), ) (111)
    
    // Task to send data
    task send_input;
        input [31:0] data;
        input is_op;
        begin
            input_data = data;
            is_input_operator = is_op;
            input_stb = 1;
            wait(input_ack);
            @(posedge clk);
            input_stb = 0;
            wait(!input_ack);
            @(posedge clk);
        end
    endtask
    
    initial begin
        rst = 1;
        output_ack = 0;
        input_stb = 0;
        tests_passed = 0;
        tests_total = 0;
        
        #20;
        rst = 0;
        #20;
        
        $display("");
        $display("╔═══════════════════════════════════════════════════════════════════════╗");
        $display("║     CONTRIBUTION 8: PARENTHESES & ASSOCIATIVITY PARSER                ║");
        $display("║     Author: 劉俊逸 (M143140014)                                       ║");
        $display("╚═══════════════════════════════════════════════════════════════════════╝");
        $display("");
        
        //---------------------------------------------------------------------
        // Test 1: Parentheses Priority
        // Equation: 5 * ( 3 + 4 ) = 35
        //---------------------------------------------------------------------
        $display("Test 1: Parentheses Priority");
        $display("Formula: 5 * ( 3 + 4 )");
        $display("Expect:  5 * 7 = 35");
        
        send_input(32'd5, 0);
        send_input(32'b010, 1); // *
        send_input(32'b110, 1); // (
        send_input(32'd3, 0);
        send_input(32'b000, 1); // +
        send_input(32'd4, 0);
        send_input(32'b111, 1); // )
        send_input(32'b101, 1); // =
        
        wait(output_stb);
        tests_total = tests_total + 1;
        
        if (output_data == 35) begin
            $display("Result:  %0d  --> [PASS]", output_data);
            tests_passed = tests_passed + 1;
        end else begin
            $display("Result:  %0d  --> [FAIL]", output_data);
        end
        $display("-------------------------------------------------------------------------");
        
        output_ack = 1; #20; output_ack = 0; #20;

        //---------------------------------------------------------------------
        // Test 2: Right Associativity (Exponentiation)
        // Equation: 2 ^ 3 ^ 2 = 2 ^ (3 ^ 2) = 2 ^ 9 = 512
        // Wrong (Left Assoc): (2 ^ 3) ^ 2 = 8 ^ 2 = 64
        //---------------------------------------------------------------------
        $display("Test 2: Right Associativity (Exponentiation)");
        $display("Formula: 2 ^ 3 ^ 2");
        $display("Expect:  2 ^ 9 = 512 (Right Associative)");
        
        send_input(32'd2, 0);
        send_input(32'b100, 1); // ^
        send_input(32'd3, 0);
        send_input(32'b100, 1); // ^
        send_input(32'd2, 0);
        send_input(32'b101, 1); // =
        
        wait(output_stb);
        tests_total = tests_total + 1;

        if (output_data == 512) begin
            $display("Result:  %0d  --> [PASS]", output_data);
            tests_passed = tests_passed + 1;
        end else if (output_data == 64) begin
             $display("Result:  %0d  --> [FAIL] (Left Associative Detected)", output_data);
        end else begin
             $display("Result:  %0d  --> [FAIL]", output_data);
        end
        $display("-------------------------------------------------------------------------");

        output_ack = 1; #20; output_ack = 0; #20;

        //---------------------------------------------------------------------
        // Test 3: Mixed Operations & Parentheses
        // Equation: 100 / ( 2 + 3 ) = 20
        //---------------------------------------------------------------------
        $display("Test 3: Division with Parentheses");
        $display("Formula: 100 / ( 2 + 3 )");
        $display("Expect:  100 / 5 = 20");
        
        send_input(32'd100, 0);
        send_input(32'b011, 1); // /
        send_input(32'b110, 1); // (
        send_input(32'd2, 0);
        send_input(32'b000, 1); // +
        send_input(32'd3, 0);
        send_input(32'b111, 1); // )
        send_input(32'b101, 1); // =
        
        wait(output_stb);
        tests_total = tests_total + 1;

        if (output_data == 20) begin
            $display("Result:  %0d  --> [PASS]", output_data);
            tests_passed = tests_passed + 1;
        end else begin
            $display("Result:  %0d  --> [FAIL]", output_data);
        end
        $display("-------------------------------------------------------------------------");
        
        $display("");
        $display("╔═══════════════════════════════════════════════════════════════════════╗");
        $display("║                        SUMMARY                                        ║");
        $display("╠═══════════════════════════════════════════════════════════════════════╣");
        $display("║   Tests Passed: %0d / %0d                                           ║", tests_passed, tests_total);
        if (tests_passed == tests_total)
            $display("║   Status:       ALL PASSED ★★★                                  ║");
        else
            $display("║   Status:       FAILURES DETECTED                               ║");
        $display("╚═══════════════════════════════════════════════════════════════════════╝");
        $display("");
        
        $finish;
    end

endmodule
