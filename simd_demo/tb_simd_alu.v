// Testbench for SIMD ALU with all operations
// Tests ADD, SUB, MUL, DIV, EXP operations across 8 lanes

`timescale 1ns/1ns

module tb_simd_alu;
  parameter LANES = 8;
  parameter WIDTH = 16;
  
  reg clk;
  reg rst;
  reg [LANES*WIDTH-1:0] a, b;
  reg [2:0] op;
  wire [LANES*WIDTH-1:0] y;
  wire valid;
  
  // Operation codes
  localparam OP_ADD = 3'b000;
  localparam OP_SUB = 3'b001;
  localparam OP_MUL = 3'b010;
  localparam OP_DIV = 3'b011;
  localparam OP_EXP = 3'b100;
  
  integer i;
  integer pass_count;
  integer test_count;
  reg [WIDTH-1:0] expected;
  reg [WIDTH-1:0] actual;
  
  simd_alu #(
    .LANES(LANES),
    .WIDTH(WIDTH)
  ) dut (
    .clk(clk),
    .rst(rst),
    .a(a),
    .b(b),
    .op(op),
    .y(y),
    .valid(valid)
  );
  
  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  // Helper function to set lane value
  task set_lane;
    input integer lane;
    input [WIDTH-1:0] val_a;
    input [WIDTH-1:0] val_b;
    begin
      a[lane*WIDTH +: WIDTH] = val_a;
      b[lane*WIDTH +: WIDTH] = val_b;
    end
  endtask
  
  // Helper function to get lane result
  function [WIDTH-1:0] get_lane;
    input integer lane;
    begin
      get_lane = y[lane*WIDTH +: WIDTH];
    end
  endfunction
  
  initial begin
    $display("");
    $display("==============================================");
    $display("    SIMD ALU Testbench (LANES=%0d, WIDTH=%0d)", LANES, WIDTH);
    $display("==============================================");
    
    rst = 1;
    a = 0;
    b = 0;
    op = OP_ADD;
    pass_count = 0;
    test_count = 0;
    
    repeat (3) @(posedge clk);
    rst = 0;
    
    //==========================================
    // Test 1: Addition
    //==========================================
    $display("\n[Test 1] Addition (a + b)");
    for (i = 0; i < LANES; i = i + 1) begin
      set_lane(i, i + 1, i + 10);  // a[i] = i+1, b[i] = i+10
    end
    op = OP_ADD;
    @(posedge clk);
    @(posedge clk);
    
    for (i = 0; i < LANES; i = i + 1) begin
      expected = (i + 1) + (i + 10);
      actual = get_lane(i);
      test_count = test_count + 1;
      if (actual == expected) begin
        $display("  Lane %0d: %0d + %0d = %0d PASS", i, i+1, i+10, actual);
        pass_count = pass_count + 1;
      end else begin
        $display("  Lane %0d: %0d + %0d = %0d FAIL (expected %0d)", i, i+1, i+10, actual, expected);
      end
    end
    
    //==========================================
    // Test 2: Subtraction
    //==========================================
    $display("\n[Test 2] Subtraction (a - b)");
    for (i = 0; i < LANES; i = i + 1) begin
      set_lane(i, 100 + i*10, i*5);
    end
    op = OP_SUB;
    @(posedge clk);
    @(posedge clk);
    
    for (i = 0; i < LANES; i = i + 1) begin
      expected = (100 + i*10) - (i*5);
      actual = get_lane(i);
      test_count = test_count + 1;
      if (actual == expected) begin
        $display("  Lane %0d: %0d - %0d = %0d PASS", i, 100+i*10, i*5, actual);
        pass_count = pass_count + 1;
      end else begin
        $display("  Lane %0d: %0d - %0d = %0d FAIL (expected %0d)", i, 100+i*10, i*5, actual, expected);
      end
    end
    
    //==========================================
    // Test 3: Multiplication
    //==========================================
    $display("\n[Test 3] Multiplication (a * b)");
    for (i = 0; i < LANES; i = i + 1) begin
      set_lane(i, i + 2, i + 3);
    end
    op = OP_MUL;
    @(posedge clk);
    @(posedge clk);
    
    for (i = 0; i < LANES; i = i + 1) begin
      expected = (i + 2) * (i + 3);
      actual = get_lane(i);
      test_count = test_count + 1;
      if (actual == expected) begin
        $display("  Lane %0d: %0d * %0d = %0d PASS", i, i+2, i+3, actual);
        pass_count = pass_count + 1;
      end else begin
        $display("  Lane %0d: %0d * %0d = %0d FAIL (expected %0d)", i, i+2, i+3, actual, expected);
      end
    end
    
    //==========================================
    // Test 4: Division
    //==========================================
    $display("\n[Test 4] Division (a / b)");
    for (i = 0; i < LANES; i = i + 1) begin
      set_lane(i, (i + 1) * 12, i + 2);  // Ensure divisible
    end
    op = OP_DIV;
    @(posedge clk);
    @(posedge clk);
    
    for (i = 0; i < LANES; i = i + 1) begin
      expected = ((i + 1) * 12) / (i + 2);
      actual = get_lane(i);
      test_count = test_count + 1;
      if (actual == expected) begin
        $display("  Lane %0d: %0d / %0d = %0d PASS", i, (i+1)*12, i+2, actual);
        pass_count = pass_count + 1;
      end else begin
        $display("  Lane %0d: %0d / %0d = %0d FAIL (expected %0d)", i, (i+1)*12, i+2, actual, expected);
      end
    end
    
    //==========================================
    // Test 5: Exponentiation
    //==========================================
    $display("\n[Test 5] Exponentiation (a ^ b)");
    for (i = 0; i < LANES; i = i + 1) begin
      set_lane(i, 2, i);  // 2^0, 2^1, 2^2, ...
    end
    op = OP_EXP;
    @(posedge clk);
    @(posedge clk);
    
    for (i = 0; i < LANES; i = i + 1) begin
      expected = (1 << i);  // 2^i
      actual = get_lane(i);
      test_count = test_count + 1;
      if (actual == expected) begin
        $display("  Lane %0d: 2 ^ %0d = %0d PASS", i, i, actual);
        pass_count = pass_count + 1;
      end else begin
        $display("  Lane %0d: 2 ^ %0d = %0d FAIL (expected %0d)", i, i, actual, expected);
      end
    end
    
    //==========================================
    // Summary
    //==========================================
    $display("\n==============================================");
    $display("    Test Summary: %0d/%0d PASSED", pass_count, test_count);
    $display("==============================================");
    
    if (pass_count == test_count) begin
      $display("*** ALL TESTS PASSED - SIMD ALU FUNCTIONAL ***");
    end else begin
      $display("*** SOME TESTS FAILED ***");
    end
    
    $finish;
  end
endmodule
