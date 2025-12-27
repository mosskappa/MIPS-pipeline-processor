`timescale 1ns/1ns

// Comprehensive Analysis Testbench
// Measures Combined Performance of Forwarding + Branch Prediction
//
// Methodology:
// 1. Runs the processor with Forwarding ON and OFF.
// 2. Simultaneously runs a "Shadow Branch Predictor".
// 3. Calculates "Effective Cycles" by adjusting the real cycle count based on BP hits/misses.
//    - Gain: Prediction=TAKEN, Actual=TAKEN (Saves 1 flush cycle)
//    - Loss: Prediction=TAKEN, Actual=NOT_TAKEN (Adds 1 flush cycle)

module tb_analysis_combined;

  reg clk;
  reg rst;
  reg forwarding_EN;
  
  // Simulation Control
  integer cycles;
  integer instrs;
  integer max_cycles = 100000;
  
  // Metrics
  real cpi;
  integer raw_hazards;
  integer load_use_stalls;
  
  // Shadow Branch Predictor Signals
  wire pred_taken;
  reg  bp_update_en;
  reg  actual_taken_reg;
  reg  [31:0] pc_id_reg;
  
  // Tracking
  integer bp_correct_taken; // Savings
  integer bp_wrong_taken;   // Penalties (False Positive)
  integer total_branches;
  
  // DUT Instantiation
  MIPS_Processor dut (clk, rst, forwarding_EN);

  // Shadow Predictor Instantiation
  branch_predictor #(
    .BHT_SIZE(32)
  ) shadow_bp (
    .clk(clk),
    .rst(rst),
    .pc_IF(dut.PC_IF),
    .predict_taken(pred_taken),
    .update_en(bp_update_en),
    .pc_ID(pc_id_reg),
    .actual_taken(actual_taken_reg),
    // stats ignored
    .predictions_total(),
    .predictions_correct(),
    .predictions_wrong()
  );

  // Clock Gen
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Metrics Logic triggers on falling edge to capture stable states
  reg prev_freeze;
  
  // Main Test Flow
  initial begin
    $display("");
    $display("=================================================================");
    $display("  COMPREHENSIVE PERFORMANCE ANALYSIS: SINGLE VS COMBINED EFFECT");
    $display("=================================================================");
    
    // ----------------------------------------------------------------
    // PASS 1: Forwarding OFF
    // ----------------------------------------------------------------
    $display("\nRunning PASS 1: Forwarding DISABLED...");
    forwarding_EN = 0;
    run_simulation();
    print_results("Baseline (No FWD, Static BP)");

    // ----------------------------------------------------------------
    // PASS 2: Forwarding ON
    // ----------------------------------------------------------------
    $display("\nRunning PASS 2: Forwarding ENABLED...");
    forwarding_EN = 1;
    run_simulation();
    print_results("Forwarding Only");
    
    // ----------------------------------------------------------------
    // CONCLUSION
    // ----------------------------------------------------------------
    $display("\n[Final Analysis]");
    $display("To calculate Combined Effect (FWD + BP):");
    $display("  1. Start with 'Forwarding Only' cycles.");
    $display("  2. Apply BP Savings: (Correct Taken Preds * 1 cycle saved).");
    $display("  3. Apply BP Penalties: (Wrong Taken Preds * 1 cycle wasted).");
    $display("");
    $finish;
  end

  task run_simulation;
    begin
      rst = 1;
      repeat(3) @(posedge clk);
      rst = 0;
      
      cycles = 0;
      instrs = 0;
      raw_hazards = 0;
      load_use_stalls = 0;
      
      bp_correct_taken = 0;
      bp_wrong_taken = 0;
      total_branches = 0;
      
      while (cycles < max_cycles && dut.inst_IF !== 32'hA800FFFF) begin
        @(posedge clk);
        cycles = cycles + 1;
        
        // Count Instructions (if not stalled)
        if (!dut.hazard_detected && dut.inst_IF !== 32'b0) begin
           instrs = instrs + 1;
        end
        
        // Hazard Analysis
        if (dut.hazard_detected) begin
           if (dut.MEM_R_EN_EXE) load_use_stalls = load_use_stalls + 1;
        end
        
        // Branch Analysis (At end of ID stage)
        // Check if instruction in ID is a branch
        // Opcode 6'b000100 (BEQ) or 6'b000101 (BNE)
        if (!dut.hazard_detected && (dut.inst_ID[31:26] == 6'b000100 || dut.inst_ID[31:26] == 6'b000101)) begin
           total_branches = total_branches + 1;
           
           // Update Shadow Predictor
           bp_update_en = 1;
           pc_id_reg = dut.PC_ID;
           actual_taken_reg = dut.Br_Taken_ID;
           
           // Check "Virtual" Performance
           // We need the prediction made 1 cycle ago for THIS instruction.
           // Simplified: We assume the BP state hasn't changed wildly in 1 cycle for THIS address
           // or we access the BHT directly. 
           // Better: Use the 'pred_taken' signal logic but index by PC_ID
           
           // Accessing BHT from shadow module for verification
           // Note: This is simulation-only verification
           if (shadow_bp.bht[dut.PC_ID[5:2]][1] == 1'b1) begin 
              // BP Predicted TAKEN
              if (dut.Br_Taken_ID) begin 
                 bp_correct_taken = bp_correct_taken + 1; // Used to flush, now doesn't -> GAIN
              end else begin
                 bp_wrong_taken = bp_wrong_taken + 1; // Used to fallthrough, now flushes -> LOSS
              end
           end
        end else begin
           bp_update_en = 0;
        end
        
      end
    end
  endtask

  task print_results;
    input [31:0] config_name; // string
    reg [63:0] cycles_fwd_bp;
    real cpi_base, cpi_bp, cpi_comb;
    begin
        cpi_base = cycles * 1.0 / instrs;
        
        // Projected Cycles with BP
        // Base Cycles 
        // - Savings (Correct Taken: would have flushed, now fast) 
        // + Penalties (False Taken: would have flow, now flush)
        cycles_fwd_bp = cycles - bp_correct_taken + bp_wrong_taken;
        cpi_comb = cycles_fwd_bp * 1.0 / instrs;
        
        $display("---------------------------------------------------------");
        $display("Result for: %0s", config_name);
        $display("  Cycles (measured): %0d", cycles);
        $display("  Instructions:      %0d", instrs);
        $display("  CPI (measured):    %.4f", cpi_base);
        $display("  Load-Use Stalls:   %0d", load_use_stalls);
        $display("  Branch Stats:      Total=%0d, BP_Gain=%0d, BP_Loss=%0d", 
                  total_branches, bp_correct_taken, bp_wrong_taken);
        $display("  Projected CPI (with BP): %.4f (Speedup: %.2fx)", 
                  cpi_comb, cpi_base / cpi_comb);
        $display("---------------------------------------------------------");
    end
  endtask

endmodule
