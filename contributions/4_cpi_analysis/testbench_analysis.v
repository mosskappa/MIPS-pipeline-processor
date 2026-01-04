`timescale 1ns/1ns

// Enhanced Metrics Testbench for Performance Ceiling Analysis
// Additional metrics: branch_flushes, load_use_stalls, forwardable_hazards
// Calculates theoretical vs actual pipeline efficiency
//
// Run examples:
//   iverilog -g2012 -I . -o sim_metrics.out testbench_metrics_enhanced.v topLevelCircuit.v defines.v $(find modules -name '*.v')
//   vvp sim_metrics.out +FWD=0 +TARGET=300
//   vvp sim_metrics.out +FWD=1 +TARGET=300

module testbench_metrics_enhanced;
  reg clk;
  reg rst;
  
  // Basic metrics
  integer cycles;
  integer instrs;
  integer stalls;
  
  // Enhanced metrics for ceiling analysis
  
  integer branch_flushes;        // Number of branch-induced flushes
  integer load_use_stalls;       // Load-use hazards (unavoidable with forwarding)
  integer forwardable_hazards;   // Hazards resolved by forwarding
  integer raw_hazards_total;     // Total RAW hazards detected
  
  // Efficiency calculations
  real cpi;
  real ipc;
  real pipeline_efficiency;      // Actual throughput / theoretical max
  real stall_percentage;
  real theoretical_cpi;          // Ideal CPI = 1.0 for perfect pipeline
  
  integer max_cycles;
  integer target_instrs;
  reg done;
  reg [31:0] prev_pc;
  reg prev_pc_valid;
  reg forwarding_EN;
  
  // Track previous states for edge detection
  reg prev_hazard_detected;
  reg prev_br_taken;
  reg prev_mem_r_en_exe;

  MIPS_Processor dut (clk, rst, forwarding_EN);

  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10ns period
  end

  initial begin
    forwarding_EN = 1;
    if (!$value$plusargs("FWD=%d", forwarding_EN)) begin
      // default stays 0
    end

    rst = 1;
    repeat (3) @(posedge clk);
    rst = 0;

    // Initialize all counters
    cycles = 0;
    instrs = 0;
    stalls = 0;
    branch_flushes = 0;
    load_use_stalls = 0;
    forwardable_hazards = 0;
    raw_hazards_total = 0;
    
    prev_hazard_detected = 0;
    prev_br_taken = 0;
    prev_mem_r_en_exe = 0;

    max_cycles = 200000;
    if (!$value$plusargs("MAX=%d", max_cycles)) begin
      // default stays 200000
    end

    target_instrs = 0;
    if (!$value$plusargs("TARGET=%d", target_instrs)) begin
      // default stays 0 (meaning: run until program end)
    end

    done = 0;
    prev_pc = 32'h0;
    prev_pc_valid = 0;

    while ((cycles < max_cycles) && ((target_instrs == 0) ? (!done) : (instrs < target_instrs))) begin
      @(posedge clk);
    end

    // Calculate derived metrics
    if (instrs != 0) begin
      cpi = (cycles * 1.0) / instrs;
      ipc = (instrs * 1.0) / cycles;
      theoretical_cpi = 1.0;  // Ideal pipeline
      pipeline_efficiency = (theoretical_cpi / cpi) * 100.0;
      stall_percentage = (stalls * 100.0) / cycles;
    end else begin
      cpi = 0;
      ipc = 0;
      pipeline_efficiency = 0;
      stall_percentage = 0;
    end

    // Print comprehensive report
    $display("");
    $display("================================================================================");
    $display("         MIPS Pipeline Performance Analysis Report");
    $display("================================================================================");
    $display("Configuration: Forwarding = %s", forwarding_EN ? "ENABLED" : "DISABLED");
    $display("--------------------------------------------------------------------------------");
    $display("");
    $display("[Basic Metrics]");
    $display("  Total Cycles:            %0d", cycles);
    $display("  Instructions Executed:   %0d", instrs);
    $display("  Stall Cycles:            %0d (%.2f%%)", stalls, stall_percentage);
    $display("  CPI (Cycles/Instruction): %.4f", cpi);
    $display("  IPC (Instructions/Cycle): %.4f", ipc);
    $display("");
    $display("[Hazard Analysis]");
    $display("  Total RAW Hazards:       %0d", raw_hazards_total);
    $display("  Branch Flushes:          %0d", branch_flushes);
    $display("  Load-Use Stalls:         %0d (unavoidable)", load_use_stalls);
    if (forwarding_EN) begin
      $display("  Hazards Resolved by FWD: %0d", forwardable_hazards);
    end
    $display("");
    $display("[Efficiency Analysis]");
    $display("  Theoretical CPI:         1.00 (ideal pipeline)");
    $display("  Actual CPI:              %.4f", cpi);
    $display("  Pipeline Efficiency:     %.2f%%", pipeline_efficiency);
    $display("");
    $display("[Performance Ceiling Analysis]");
    $display("  Theoretical Speedup:     5 stages x 1.14 FWD gain x 8 SIMD = 45.60");
    if (forwarding_EN) begin
      // Calculate actual speedup factors
      $display("  Actual Stage Efficiency: %.2f (pipeline overhead)", 5.0 * pipeline_efficiency / 100.0);
      $display("  Note: Load-use hazards and branch penalties prevent reaching ceiling");
    end
    $display("");
    $display("================================================================================");

    $finish;
  end

  always @(posedge clk) begin
    if (!rst) begin
      cycles = cycles + 1;
      
      // Count stalls
      if (dut.hazard_detected) begin
        stalls = stalls + 1;

        // Classify stall type
        if (dut.MEM_R_EN_EXE) begin
          // Load-use hazard - cannot be resolved by forwarding
          load_use_stalls = load_use_stalls + 1;
        end
      end
      
      // Count branch flushes (when IF_Flush is asserted)
      if (dut.IF_Flush && !prev_br_taken) begin
        branch_flushes = branch_flushes + 1;
      end
      
      // Track RAW hazards for analysis
      // A RAW hazard occurs when source registers match destination of in-flight instructions
      if (dut.WB_EN_EXE && (dut.src1_ID == dut.dest_EXE || dut.src2_regFile_ID == dut.dest_EXE)) begin
        raw_hazards_total = raw_hazards_total + 1;
        if (forwarding_EN && !dut.hazard_detected) begin
          forwardable_hazards = forwardable_hazards + 1;
        end
      end
      if (dut.WB_EN_MEM && (dut.src1_ID == dut.dest_MEM || dut.src2_regFile_ID == dut.dest_MEM)) begin
        raw_hazards_total = raw_hazards_total + 1;
        if (forwarding_EN && !dut.hazard_detected) begin
          forwardable_hazards = forwardable_hazards + 1;
        end
      end

      // Count dynamic instructions
      if (!dut.hazard_detected) begin
        if (!prev_pc_valid) begin
          prev_pc = dut.PC_IF;
          prev_pc_valid = 1;
          if (dut.inst_IF !== 32'b0)
            instrs = instrs + 1;
        end else if (dut.PC_IF != prev_pc) begin
          if (dut.inst_IF !== 32'b0)
            instrs = instrs + 1;
          prev_pc = dut.PC_IF;
        end
      end

      // Program completion detection
      if ((target_instrs == 0) && !done && (dut.inst_IF === 32'hA800FFFF)) begin
        done = 1;
      end
      
      // Update previous state
      prev_hazard_detected = dut.hazard_detected;
      prev_br_taken = dut.Br_Taken_ID;
      prev_mem_r_en_exe = dut.MEM_R_EN_EXE;
    end
  end
endmodule
