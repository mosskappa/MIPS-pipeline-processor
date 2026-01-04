`timescale 1ns/1ns

//=============================================================================
// CONTRIBUTION 8: Expression Parser with Parentheses & Right Associativity
// Author: 劉俊逸 (M143140014)
//
// Features Verified:
// 1. Parentheses Handling: ( ) override operator precedence
// 2. Right Associativity: 2^3^2 = 2^9 = 512 (not 64)
// 3. All Operations: + - * / ^
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
    
    // Operator Encoding (aligned with contributions/8 converter.v)
    localparam OP_ADD = 32'b000; // +
    localparam OP_SUB = 32'b001; // -
    localparam OP_MUL = 32'b010; // *
    localparam OP_DIV = 32'b011; // /
    localparam OP_EXP = 32'b100; // ^
    localparam OP_EQ  = 32'b101; // =
    localparam OP_LP  = 32'b110; // (
    localparam OP_RP  = 32'b111; // )
    
    // Instantiate Top (lowercase clk/rst from expression_parser_top)
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
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Task: Send input with proper handshake
    task send_input;
        input [31:0] data;
        input is_op;
        begin
            @(posedge clk);
            input_data = data;
            is_input_operator = is_op;
            input_stb = 1;
            
            // Wait for acknowledgment
            wait(input_ack);
            @(posedge clk);
            input_stb = 0;
            
            // Wait for ack to deassert
            wait(!input_ack);
            @(posedge clk);
        end
    endtask
    
    initial begin
        rst = 1;
        output_ack = 0;
        input_stb = 0;
        input_data = 0;
        is_input_operator = 0;
        tests_passed = 0;
        tests_total = 0;
        
        // Hold reset
        repeat(4) @(posedge clk);
        rst = 0;
        repeat(2) @(posedge clk);
        
        $display("");
        $display("╔═══════════════════════════════════════════════════════════════════════╗");
        $display("║     CONTRIBUTION 8: PARENTHESES & ASSOCIATIVITY PARSER                ║");
        $display("║     Author: 劉俊逸 (M143140014)                                       ║");
        $display("╚═══════════════════════════════════════════════════════════════════════╝");
        $display("");
        
        //---------------------------------------------------------------------
        // Test 1: Parentheses Priority
        // Expression: 5 * ( 3 + 4 ) = 5 * 7 = 35
        //---------------------------------------------------------------------
        $display("Test 1: Parentheses Priority");
        $display("Formula: 5 * ( 3 + 4 )");
        $display("Expect:  5 * 7 = 35");
        
        send_input(32'd5, 0);      // 5
        send_input(OP_MUL, 1);     // *
        send_input(OP_LP, 1);      // (
        send_input(32'd3, 0);      // 3
        send_input(OP_ADD, 1);     // +
        send_input(32'd4, 0);      // 4
        send_input(OP_RP, 1);      // )
        send_input(OP_EQ, 1);      // =
        
        // Wait for result
        wait(output_stb);
        tests_total = tests_total + 1;
        
        if (output_data == 35) begin
            $display("Result:  %0d  --> [PASS]", output_data);
            tests_passed = tests_passed + 1;
        end else begin
            $display("Result:  %0d  --> [FAIL] (expected 35)", output_data);
        end
        $display("-------------------------------------------------------------------------");
        
        // Acknowledge result
        @(posedge clk);
        output_ack = 1;
        wait(!output_stb);
        @(posedge clk);
        output_ack = 0;
        repeat(5) @(posedge clk);

        //---------------------------------------------------------------------
        // Test 2: Right Associativity (Exponentiation)
        // Expression: 2 ^ 3 ^ 2 = 2 ^ (3 ^ 2) = 2 ^ 9 = 512
        // Wrong (Left Assoc): (2 ^ 3) ^ 2 = 8 ^ 2 = 64
        //---------------------------------------------------------------------
        $display("Test 2: Right Associativity (Exponentiation)");
        $display("Formula: 2 ^ 3 ^ 2");
        $display("Expect:  2 ^ 9 = 512 (Right Associative)");
        
        send_input(32'd2, 0);      // 2
        send_input(OP_EXP, 1);     // ^
        send_input(32'd3, 0);      // 3
        send_input(OP_EXP, 1);     // ^
        send_input(32'd2, 0);      // 2
        send_input(OP_EQ, 1);      // =
        
        wait(output_stb);
        tests_total = tests_total + 1;

        if (output_data == 512) begin
            $display("Result:  %0d  --> [PASS]", output_data);
            tests_passed = tests_passed + 1;
        end else if (output_data == 64) begin
            $display("Result:  %0d  --> [FAIL] (Left Associative - should be Right)", output_data);
        end else begin
            $display("Result:  %0d  --> [FAIL] (expected 512)", output_data);
        end
        $display("-------------------------------------------------------------------------");

        @(posedge clk);
        output_ack = 1;
        wait(!output_stb);
        @(posedge clk);
        output_ack = 0;
        repeat(5) @(posedge clk);

        //---------------------------------------------------------------------
        // Test 3: Division with Parentheses
        // Expression: 100 / ( 2 + 3 ) = 100 / 5 = 20
        //---------------------------------------------------------------------
        $display("Test 3: Division with Parentheses");
        $display("Formula: 100 / ( 2 + 3 )");
        $display("Expect:  100 / 5 = 20");
        
        send_input(32'd100, 0);    // 100
        send_input(OP_DIV, 1);     // /
        send_input(OP_LP, 1);      // (
        send_input(32'd2, 0);      // 2
        send_input(OP_ADD, 1);     // +
        send_input(32'd3, 0);      // 3
        send_input(OP_RP, 1);      // )
        send_input(OP_EQ, 1);      // =
        
        wait(output_stb);
        tests_total = tests_total + 1;

        if (output_data == 20) begin
            $display("Result:  %0d  --> [PASS]", output_data);
            tests_passed = tests_passed + 1;
        end else begin
            $display("Result:  %0d  --> [FAIL] (expected 20)", output_data);
        end
        $display("-------------------------------------------------------------------------");
        
        // Final Summary
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
