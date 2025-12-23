`timescale 1ns / 1ps

module tb_expression_parser;

    reg clk;
    reg rst;
    
    // Inputs
    reg input_stb;
    reg [31:0] input_data;
    reg is_input_operator;
    
    // Outputs
    wire input_ack;
    wire result_stb;
    wire [31:0] result_data;
    reg result_ack;

    // Operator mapping
    localparam OP_MUL = 32'b001; // *
    localparam OP_ADD = 32'b010; // +
    localparam OP_SUB = 32'b011; // -
    localparam OP_EQ  = 32'b100; // = (Equal / End)

    // Instantiate Top Module
    expression_parser_top dut(
        .CLK(clk),
        .RST(rst),
        .input_stb(input_stb),
        .input_data(input_data),
        .is_input_operator(is_input_operator),
        .input_ack(input_ack),
        .result_stb(result_stb),
        .result_data(result_data),
        .result_ack(result_ack)
    );

    // Clock Generation
    always #5 clk = ~clk;

    // Tasks for driving inputs
    task send_number;
        input [31:0] num;
        begin
            wait(!input_ack);
            input_stb = 1;
            input_data = num;
            is_input_operator = 0;
            wait(input_ack);
            #2; // hold for a bit
            input_stb = 0;
            #10;
        end
    endtask

    task send_op;
        input [31:0] op;
        begin
            wait(!input_ack);
            input_stb = 1;
            input_data = op;
            is_input_operator = 1;
            wait(input_ack);
            #2;
            input_stb = 0;
            #10;
        end
    endtask

    // Monitor internal signals to show conversion process
    // Use a register to track previous state of output_stb to detect rising edge
    reg prev_output_stb;
    initial prev_output_stb = 0;

    always @(posedge clk) begin
        prev_output_stb <= dut.u_converter.output_stb;
        
        // Only print on rising edge (0->1) to avoid repeated lines
        if (dut.u_converter.output_stb && !prev_output_stb) begin
            if (dut.u_converter.is_output_operator) begin
                case (dut.u_converter.output_data[2:0])
                    3'b001: $display("    [Parser Output] * (Operator)");
                    3'b010: $display("    [Parser Output] + (Operator)");
                    3'b011: $display("    [Parser Output] - (Operator)");
                    3'b100: $display("    [Parser Output] = (End)");
                    default: $display("    [Parser Output] Unknown Operator (%b)", dut.u_converter.output_data[2:0]);
                endcase
            end else begin
                $display("    [Parser Output] %d (Number)", dut.u_converter.output_data);
            end
        end
    end

    // Initial Block
    initial begin
        clk = 0;
        rst = 1;
        input_stb = 0;
        is_input_operator = 0;
        result_ack = 0;

        #20 rst = 0;
        #10;

        $display("=================================================");
        $display(" Automatic Expression Parsing \u0026 Evaluation Demo");
        $display("=================================================");
        $display("Demonstrates: Infix -> Postfix (Shunting Yard) -> Stack Calculation");
        $display("");

        //-----------------------------------------
        // Test Case 1: 3 + 4 * 2
        // Expected Postfix: 3 4 2 * +
        // Expected Result: 11
        //-----------------------------------------
        $display("Test Case 1: 3 + 4 * 2 = ?");
        $display(" Sending Infix: 3, +, 4, *, 2, =");
        $display("--------------------------------");
        
        send_number(3);
        send_op(OP_ADD);
        send_number(4);
        send_op(OP_MUL);
        send_number(2);
        send_op(OP_EQ); // "=" triggers calculation

        wait(result_stb);
        $display("--------------------------------");
        $display(" Result: %d", result_data);
        if (result_data == 11) $display(" [PASS]");
        else $display(" [FAIL]");
        
        result_ack = 1;
        wait(!result_stb);
        result_ack = 0;
        
        #50;

        //-----------------------------------------
        // Test Case 2: 5 * 3 + 2 * 4
        // Expected Postfix: 5 3 * 2 4 * +
        // Expected Result: 23
        //-----------------------------------------
        $display("");
        $display("Test Case 2: 5 * 3 + 2 * 4 = ?");
        $display(" Sending Infix: 5, *, 3, +, 2, *, 4, =");
        $display("--------------------------------");
        
        send_number(5);
        send_op(OP_MUL);
        send_number(3);
        send_op(OP_ADD);
        send_number(2);
        send_op(OP_MUL);
        send_number(4);
        send_op(OP_EQ);

        wait(result_stb);
        $display("--------------------------------");
        $display(" Result: %d", result_data);
        if (result_data == 23) $display(" [PASS]");
        else $display(" [FAIL]");

        result_ack = 1;
        wait(!result_stb);
        result_ack = 0;

        #50;

        //-----------------------------------------
        // Test Case 3: Mixed Priority Chain
        // Expression: 10 - 2 * 3 + 4 * 5
        // Expected Logic:
        //   1. 2 * 3 = 6
        //   2. 4 * 5 = 20
        //   3. 10 - 6 = 4  (Left associativity)
        //   4. 4 + 20 = 24
        // Postfix: 10 2 3 * - 4 5 * +
        //-----------------------------------------
        $display("");
        $display("Test Case 3: 10 - 2 * 3 + 4 * 5 = ?");
        $display(" Sending Infix: 10, -, 2, *, 3, +, 4, *, 5, =");
        $display("--------------------------------");
        
        send_number(10);
        send_op(OP_SUB);
        send_number(2);
        send_op(OP_MUL);
        send_number(3);
        send_op(OP_ADD);
        send_number(4);
        send_op(OP_MUL);
        send_number(5);
        send_op(OP_EQ);

        wait(result_stb);
        $display("--------------------------------");
        $display(" Result: %d", result_data);
        if (result_data == 24) $display(" [PASS]");
        else $display(" [FAIL]");

        result_ack = 1;
        wait(!result_stb);
        result_ack = 0;

        #50;
        $finish;
    end

endmodule
