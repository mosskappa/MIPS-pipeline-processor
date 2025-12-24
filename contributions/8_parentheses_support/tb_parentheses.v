`timescale 1ns/1ns

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
        #20;
        rst = 0;
        #20;
        
        // Equation 1: 5 * ( 3 + 4 ) = 35
        // New Encoding: * (010), + (000), ( (110), ) (111), = (101)
        
        $display("Test 1: 5 * ( 3 + 4 )");
        send_input(32'd5, 0);
        send_input(32'b010, 1); // *
        send_input(32'b110, 1); // (
        send_input(32'd3, 0);
        send_input(32'b000, 1); // +
        send_input(32'd4, 0);
        send_input(32'b111, 1); // )
        send_input(32'b101, 1); // =
        
        wait(output_stb);
        $display("Result: %d (Expected 35)", output_data);
        if (output_data == 35) $display("PASS"); else $display("FAIL");
        
        output_ack = 1; #20; output_ack = 0; #20;

        // Equation 2: 2 ^ 3 ^ 2 (Right Associative) -> 2 ^ 9 = 512
        // EXP = 100 (4)
        $display("Test 2: 2 ^ 3 ^ 2");
        send_input(32'd2, 0);
        send_input(32'b100, 1); // ^
        send_input(32'd3, 0);
        send_input(32'b100, 1); // ^
        send_input(32'd2, 0);
        send_input(32'b101, 1); // =
        
        wait(output_stb);
        $display("Result: %d (Expected 512)", output_data);
        if (output_data == 512) $display("PASS - Right Associativity Verified"); 
        else $display("FAIL - Got %0d (Likely Left Associative if 64)", output_data);

        output_ack = 1; #20; output_ack = 0; #20;

        // Equation 3: 100 / ( 2 + 3 ) = 20
        // DIV = 011 (3), + = 000 (0)
        $display("Test 3: 100 / ( 2 + 3 )");
        send_input(32'd100, 0);
        send_input(32'b011, 1); // /
        send_input(32'b110, 1); // (
        send_input(32'd2, 0);
        send_input(32'b000, 1); // +
        send_input(32'd3, 0);
        send_input(32'b111, 1); // )
        send_input(32'b101, 1); // =
        
        wait(output_stb);
        $display("Result: %d (Expected 20)", output_data);
        if (output_data == 20) $display("PASS"); else $display("FAIL");
        
        $finish;
    end

endmodule
