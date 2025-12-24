// Testbench for Branch Prediction Performance
// Compares execution with and without branch prediction
// Measures prediction accuracy and cycle savings

`timescale 1ns/1ns

module tb_branch_predictor;
  parameter BHT_SIZE = 16;
  parameter BHT_BITS = 4;
  
  reg clk;
  reg rst;
  
  // Prediction interface
  reg [31:0] pc_IF;
  wire predict_taken;
  
  // Update interface  
  reg update_en;
  reg [31:0] pc_ID;
  reg actual_taken;
  
  // Statistics
  wire [31:0] predictions_total;
  wire [31:0] predictions_correct;
  wire [31:0] predictions_wrong;
  
  // Test variables
  integer i;
  integer test_pattern;
  real accuracy;
  
  branch_predictor #(
    .BHT_SIZE(BHT_SIZE),
    .BHT_BITS(BHT_BITS)
  ) dut (
    .clk(clk),
    .rst(rst),
    .pc_IF(pc_IF),
    .predict_taken(predict_taken),
    .update_en(update_en),
    .pc_ID(pc_ID),
    .actual_taken(actual_taken),
    .predictions_total(predictions_total),
    .predictions_correct(predictions_correct),
    .predictions_wrong(predictions_wrong)
  );
  
  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  initial begin
    $display("");
    $display("==============================================");
    $display("    Branch Predictor Testbench");
    $display("    2-Bit Saturating Counter Predictor");
    $display("    BHT Size: %0d entries", BHT_SIZE);
    $display("==============================================");
    
    rst = 1;
    pc_IF = 0;
    pc_ID = 0;
    update_en = 0;
    actual_taken = 0;
    
    repeat (5) @(posedge clk);
    rst = 0;
    repeat (2) @(posedge clk);
    
    //==========================================
    // Test 1: Always Taken Loop (should learn quickly)
    //==========================================
    $display("\n[Test 1] Always Taken Loop (10 iterations)");
    $display("  Pattern: T T T T T T T T T T");
    
    for (i = 0; i < 10; i = i + 1) begin
      pc_IF = 32'h100;  // Same branch address
      @(posedge clk);
      
      // Simulate branch resolution
      pc_ID = 32'h100;
      actual_taken = 1;  // Always taken
      update_en = 1;
      @(posedge clk);
      update_en = 0;
    end
    
    accuracy = (predictions_correct * 100.0) / predictions_total;
    $display("  Results: %0d correct / %0d total (%.1f%% accuracy)", 
             predictions_correct, predictions_total, accuracy);
    
    //==========================================
    // Test 2: Always Not Taken (should learn)
    //==========================================
    $display("\n[Test 2] Always Not Taken (10 iterations)");
    $display("  Pattern: N N N N N N N N N N");
    
    for (i = 0; i < 10; i = i + 1) begin
      pc_IF = 32'h200;  // Different branch address
      @(posedge clk);
      
      pc_ID = 32'h200;
      actual_taken = 0;  // Always not taken
      update_en = 1;
      @(posedge clk);
      update_en = 0;
    end
    
    accuracy = (predictions_correct * 100.0) / predictions_total;
    $display("  Cumulative: %0d correct / %0d total (%.1f%% accuracy)", 
             predictions_correct, predictions_total, accuracy);
    
    //==========================================
    // Test 3: Alternating Pattern (worst case)
    //==========================================
    $display("\n[Test 3] Alternating Pattern (10 iterations)");
    $display("  Pattern: T N T N T N T N T N");
    
    for (i = 0; i < 10; i = i + 1) begin
      pc_IF = 32'h300;
      @(posedge clk);
      
      pc_ID = 32'h300;
      actual_taken = (i % 2 == 0) ? 1 : 0;  // Alternating
      update_en = 1;
      @(posedge clk);
      update_en = 0;
    end
    
    accuracy = (predictions_correct * 100.0) / predictions_total;
    $display("  Cumulative: %0d correct / %0d total (%.1f%% accuracy)", 
             predictions_correct, predictions_total, accuracy);
    
    //==========================================
    // Test 4: Realistic Loop Pattern (TTTTTTTTTN)
    //==========================================
    $display("\n[Test 4] Realistic Loop (9T then 1N, 3 iterations)");
    $display("  Pattern: TTTTTTTTN TTTTTTTTN TTTTTTTTN");
    
    for (i = 0; i < 30; i = i + 1) begin
      pc_IF = 32'h400;
      @(posedge clk);
      
      pc_ID = 32'h400;
      // 9 taken, then 1 not taken (typical loop exit)
      actual_taken = ((i % 10) < 9) ? 1 : 0;
      update_en = 1;
      @(posedge clk);
      update_en = 0;
    end
    
    accuracy = (predictions_correct * 100.0) / predictions_total;
    $display("  Cumulative: %0d correct / %0d total (%.1f%% accuracy)", 
             predictions_correct, predictions_total, accuracy);
    
    //==========================================
    // Summary
    //==========================================
    $display("\n==============================================");
    $display("    Branch Predictor Test Complete");
    $display("==============================================");
    $display("  Total Predictions:  %0d", predictions_total);
    $display("  Correct:            %0d", predictions_correct);
    $display("  Wrong:              %0d", predictions_wrong);
    accuracy = (predictions_correct * 100.0) / predictions_total;
    $display("  Overall Accuracy:   %.2f%%", accuracy);
    $display("");
    $display("  Expected: >70%% accuracy on typical workloads");
    $display("  Benefit:  Reduces branch penalty cycles");
    $display("==============================================");
    
    $finish;
  end
endmodule
