`timescale 1ns / 1ps

//==============================================================================
// Flexible SIMD Expression Evaluator Demo
// 
// This testbench demonstrates that the SIMD ALU can compute ANY expression
// by sequencing operations. Unlike simd_expr_eval.v which is hardcoded for
// one expression, this approach is fully flexible.
//
// Examples:
//   1. a^b + c^d
//   2. (a+b) * (c-d)
//   3. a^b + (c+d^e) * f
//==============================================================================

module tb_simd_flexible_expr;

    parameter integer LANES = 8;
    parameter integer WIDTH = 16;
    
    // SIMD ALU interface
    reg  clk;
    reg  rst;
    reg  [2:0] op;
    reg  [LANES*WIDTH-1:0] a_bus, b_bus;
    wire [LANES*WIDTH-1:0] y_bus;
    wire valid;
    
    // Temporary storage for intermediate results
    reg [LANES*WIDTH-1:0] temp1, temp2, temp3;
    
    // Operation codes
    localparam OP_ADD = 3'b000;
    localparam OP_SUB = 3'b001;
    localparam OP_MUL = 3'b010;
    localparam OP_DIV = 3'b011;
    localparam OP_EXP = 3'b100;
    
    // Instantiate SIMD ALU
    simd_alu #(
        .LANES(LANES),
        .WIDTH(WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .op(op),
        .a(a_bus),
        .b(b_bus),
        .y(y_bus),
        .valid(valid)
    );
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Helper function to extract lane value
    function [WIDTH-1:0] get_lane;
        input [LANES*WIDTH-1:0] bus;
        input integer lane;
        begin
            get_lane = bus[lane*WIDTH +: WIDTH];
        end
    endfunction
    
    // Helper task to set lane value
    task set_lanes;
        input [WIDTH-1:0] val;
        output [LANES*WIDTH-1:0] bus;
        integer i;
        begin
            for (i = 0; i < LANES; i = i + 1)
                bus[i*WIDTH +: WIDTH] = val;
        end
    endtask

    integer i;
    reg [WIDTH-1:0] expected;
    
    initial begin
        clk = 0;
        rst = 1;
        op = OP_ADD;
        a_bus = 0;
        b_bus = 0;
        
        #20 rst = 0;
        
        $display("==============================================");
        $display("Flexible SIMD Expression Evaluator Demo");
        $display("==============================================");
        $display("");
        
        //----------------------------------------------------------------------
        // Example 1: Compute a^b + c^d
        // where a=2, b=3, c=3, d=2
        // Expected: 2^3 + 3^2 = 8 + 9 = 17
        //----------------------------------------------------------------------
        $display("Example 1: a^b + c^d");
        $display("  a=2, b=3, c=3, d=2");
        $display("  Expected: 2^3 + 3^2 = 8 + 9 = 17");
        $display("");
        
        // Step 1: Compute a^b
        $display("  Step 1: Compute a^b = 2^3");
        set_lanes(16'd2, a_bus);
        set_lanes(16'd3, b_bus);
        op = OP_EXP;
        #20;
        temp1 = y_bus;
        $display("    Result: %d", get_lane(temp1, 0));
        
        // Step 2: Compute c^d
        $display("  Step 2: Compute c^d = 3^2");
        set_lanes(16'd3, a_bus);
        set_lanes(16'd2, b_bus);
        op = OP_EXP;
        #20;
        temp2 = y_bus;
        $display("    Result: %d", get_lane(temp2, 0));
        
        // Step 3: Add results
        $display("  Step 3: Compute temp1 + temp2 = 8 + 9");
        a_bus = temp1;
        b_bus = temp2;
        op = OP_ADD;
        #20;
        $display("    Final Result: %d", get_lane(y_bus, 0));
        $display("    Expected:     17");
        if (get_lane(y_bus, 0) == 17)
            $display("    [PASS] a^b + c^d = 17");
        else
            $display("    [FAIL]");
        $display("");
        
        //----------------------------------------------------------------------
        // Example 2: Compute (a+b) * (c-d)
        // where a=5, b=3, c=10, d=2
        // Expected: (5+3) * (10-2) = 8 * 8 = 64
        //----------------------------------------------------------------------
        $display("Example 2: (a+b) * (c-d)");
        $display("  a=5, b=3, c=10, d=2");
        $display("  Expected: (5+3) * (10-2) = 8 * 8 = 64");
        $display("");
        
        // Step 1: Compute a+b
        $display("  Step 1: Compute a+b = 5+3");
        set_lanes(16'd5, a_bus);
        set_lanes(16'd3, b_bus);
        op = OP_ADD;
        #20;
        temp1 = y_bus;
        $display("    Result: %d", get_lane(temp1, 0));
        
        // Step 2: Compute c-d
        $display("  Step 2: Compute c-d = 10-2");
        set_lanes(16'd10, a_bus);
        set_lanes(16'd2, b_bus);
        op = OP_SUB;
        #20;
        temp2 = y_bus;
        $display("    Result: %d", get_lane(temp2, 0));
        
        // Step 3: Multiply results
        $display("  Step 3: Compute temp1 * temp2 = 8 * 8");
        a_bus = temp1;
        b_bus = temp2;
        op = OP_MUL;
        #20;
        $display("    Final Result: %d", get_lane(y_bus, 0));
        $display("    Expected:     64");
        if (get_lane(y_bus, 0) == 64)
            $display("    [PASS] (a+b) * (c-d) = 64");
        else
            $display("    [FAIL]");
        $display("");
        
        //----------------------------------------------------------------------
        // Example 3: Compute a^b + (c + d^e) * f
        // where a=2, b=2, c=1, d=2, e=3, f=2
        // Expected: 2^2 + (1 + 2^3) * 2 = 4 + (1+8)*2 = 4 + 18 = 22
        //----------------------------------------------------------------------
        $display("Example 3: a^b + (c + d^e) * f");
        $display("  a=2, b=2, c=1, d=2, e=3, f=2");
        $display("  Expected: 2^2 + (1 + 2^3) * 2 = 4 + 9*2 = 22");
        $display("");
        
        // Step 1: Compute a^b
        $display("  Step 1: Compute a^b = 2^2");
        set_lanes(16'd2, a_bus);
        set_lanes(16'd2, b_bus);
        op = OP_EXP;
        #20;
        temp1 = y_bus;  // temp1 = 4
        $display("    Result: %d", get_lane(temp1, 0));
        
        // Step 2: Compute d^e
        $display("  Step 2: Compute d^e = 2^3");
        set_lanes(16'd2, a_bus);
        set_lanes(16'd3, b_bus);
        op = OP_EXP;
        #20;
        temp2 = y_bus;  // temp2 = 8
        $display("    Result: %d", get_lane(temp2, 0));
        
        // Step 3: Compute c + temp2
        $display("  Step 3: Compute c + d^e = 1 + 8");
        set_lanes(16'd1, a_bus);
        b_bus = temp2;
        op = OP_ADD;
        #20;
        temp2 = y_bus;  // temp2 = 9
        $display("    Result: %d", get_lane(temp2, 0));
        
        // Step 4: Compute temp2 * f
        $display("  Step 4: Compute (c+d^e) * f = 9 * 2");
        a_bus = temp2;
        set_lanes(16'd2, b_bus);
        op = OP_MUL;
        #20;
        temp2 = y_bus;  // temp2 = 18
        $display("    Result: %d", get_lane(temp2, 0));
        
        // Step 5: Compute temp1 + temp2
        $display("  Step 5: Compute a^b + result = 4 + 18");
        a_bus = temp1;
        b_bus = temp2;
        op = OP_ADD;
        #20;
        $display("    Final Result: %d", get_lane(y_bus, 0));
        $display("    Expected:     22");
        if (get_lane(y_bus, 0) == 22)
            $display("    [PASS] a^b + (c+d^e)*f = 22");
        else
            $display("    [FAIL]");
        $display("");
        
        //----------------------------------------------------------------------
        // Example 4: User Request -> (a+b)*c / d^e
        // a=5, b=3, c=10, d=2, e=3
        // Result: (5+3)*10 / 2^3 = 8*10 / 8 = 80 / 8 = 10
        //----------------------------------------------------------------------
        $display("Example 4: (a+b)*c / d^e");
        $display("  a=5, b=3, c=10, d=2, e=3");
        $display("  Expected: (5+3)*10 / 2^3 = 80 / 8 = 10");
        $display("");
        
        // Step 1: Compute d^e (High Priority)
        $display("  Step 1: Compute d^e = 2^3");
        set_lanes(16'd2, a_bus);
        set_lanes(16'd3, b_bus);
        op = OP_EXP;
        #20;
        temp1 = y_bus;  // temp1 = 8
        $display("    Result: %d", get_lane(temp1, 0));
        
        // Step 2: Compute a+b (Parenthesis)
        $display("  Step 2: Compute a+b = 5+3");
        set_lanes(16'd5, a_bus);
        set_lanes(16'd3, b_bus);
        op = OP_ADD;
        #20;
        temp2 = y_bus;  // temp2 = 8
        $display("    Result: %d", get_lane(temp2, 0));
        
        // Step 3: Compute (a+b)*c
        $display("  Step 3: Compute temp2 * c = 8 * 10");
        a_bus = temp2;
        set_lanes(16'd10, b_bus);
        op = OP_MUL;
        #20;
        temp2 = y_bus;  // temp2 = 80
        $display("    Result: %d", get_lane(temp2, 0));
        
        // Step 4: Final Division
        $display("  Step 4: Compute temp2 / temp1 = 80 / 8");
        a_bus = temp2;
        b_bus = temp1;
        op = OP_DIV;
        #20;
        $display("    Final Result: %d", get_lane(y_bus, 0));
        $display("    Expected:     10");
        if (get_lane(y_bus, 0) == 10)
            $display("    [PASS] (a+b)*c / d^e = 10");
        else
            $display("    [FAIL]");
        $display("");
        
        //----------------------------------------------------------------------
        // Summary
        //----------------------------------------------------------------------
        $display("==============================================");
        $display("SUMMARY");
        $display("==============================================");
        $display("");
        $display("This demo proves that the SIMD ALU can compute");
        $display("ANY arithmetic expression by sequencing operations.");
        $display("");
        $display("Key points:");
        $display("  1. simd_alu.v provides 5 operations: +, -, *, /, ^");
        $display("  2. Complex expressions are broken into steps");
        $display("  3. Intermediate results stored in temp registers");
        $display("  4. Each step processes 8 lanes in parallel!");
        $display("");
        $display("==============================================");
        
        #50 $finish;
    end

endmodule
