`timescale 1ns/1ns

// Metrics-oriented testbench:
// - Compare forwarding_EN=0 vs 1
// - Count cycles, committed instructions (WB_EN_WB), and stall cycles (hazard_detected)
// Run examples:
//   iverilog -g2012 -I . -o sim_metrics.out testbench_metrics.v topLevelCircuit.v defines.v $(find modules -name '*.v')
//   vvp sim_metrics.out +FWD=0
//   vvp sim_metrics.out +FWD=1

module testbench_metrics;
  reg clk;
  reg rst;
  integer cycles;
  integer instrs;
  integer stalls;
  integer max_cycles;
  integer target_instrs;

  reg done;
  reg [31:0] prev_pc;
  reg prev_pc_valid;

  reg forwarding_EN;

  MIPS_Processor dut (clk, rst, forwarding_EN);

  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10ns period
  end

  initial begin
    forwarding_EN = 1;  // Changed to 1 for Vivado demo (Forwarding ON)
    if (!$value$plusargs("FWD=%d", forwarding_EN)) begin
      // default stays 1 for Vivado
    end

    rst = 1;
    repeat (3) @(posedge clk);
    rst = 0;

    cycles = 0;
    instrs = 0;
    stalls = 0;

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

    // Two supported stop conditions:
    // 1) +TARGET=<N> : run until N dynamic instructions are fetched (PC-advancing IF events)
    // 2) default     : run until the program reaches its terminal instruction.
    // In this repo's instruction memory, the program ends with "JMP -1" encoded as 32'hA800FFFF.
    while ((cycles < max_cycles) && ((target_instrs == 0) ? (!done) : (instrs < target_instrs))) begin
      @(posedge clk);
    end

    if (instrs != 0)
      $display("FWD=%0d cycles=%0d instrs=%0d stalls=%0d CPI=%0f", forwarding_EN, cycles, instrs, stalls, (cycles * 1.0) / instrs);
    else
      $display("FWD=%0d cycles=%0d instrs=%0d stalls=%0d CPI=NA", forwarding_EN, cycles, instrs, stalls);

    $finish;
  end

  always @(posedge clk) begin
    if (!rst) begin
      cycles = cycles + 1;
      if (dut.hazard_detected)
        stalls = stalls + 1;

      // Count dynamic instructions as "new IF fetch" events.
      // IF is frozen on hazards, so PC doesn't advance during stall cycles.
      if (!dut.hazard_detected) begin
        if (!prev_pc_valid) begin
          prev_pc = dut.PC_IF;
          prev_pc_valid = 1;
          if (dut.inst_IF !== 32'b0)
            instrs = instrs + 1;
        end else if (dut.PC_IF != prev_pc) begin
          // Exclude NOP (all-zero) to avoid counting bubbles.
          if (dut.inst_IF !== 32'b0)
            instrs = instrs + 1;
          prev_pc = dut.PC_IF;
        end
      end

      // Program completion detection: first time IF sees the terminal JMP -1.
      if ((target_instrs == 0) && !done && (dut.inst_IF === 32'hA800FFFF)) begin
        done = 1;
      end
    end
  end
endmodule
