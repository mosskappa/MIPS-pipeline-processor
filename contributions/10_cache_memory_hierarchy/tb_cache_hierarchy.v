`timescale 1ns/1ps

//=============================================================================
// CONTRIBUTION 10: Cache Hierarchy Comparison Analysis
// Author: 劉俊逸 (M143140014)
//
// This testbench compares memory access performance across different cache
// hierarchy configurations using industry-standard parameters.
//
// Configurations:
//   1. No Cache (Direct Memory Access)
//   2. L1 Only
//   3. L1 + L2
//   4. L1 + L2 + L3
//
// STANDARD PARAMETERS SOURCE:
//   - Patterson & Hennessy, "Computer Architecture: A Quantitative Approach"
//     6th Edition, Chapter 2: Memory Hierarchy Design
//   - Intel/AMD typical desktop processor specifications (2020-2024)
//=============================================================================

module tb_cache_hierarchy;

    //=========================================================================
    // Standard Cache Parameters (from Patterson & Hennessy and Intel/AMD specs)
    //=========================================================================
    localparam CLK_PERIOD = 10;
    
    // Main Memory (DRAM)
    localparam real MEM_LATENCY = 100;         // ~100 cycles (Intel/AMD typical)
    
    // L1 Cache Parameters (per-core, private)
    localparam real L1_SIZE_KB = 32;           // 32 KB (Intel/AMD typical)
    localparam real L1_HIT_CYCLES = 1;         // 1 cycle (fastest)
    localparam real L1_HIT_RATE = 0.95;        // 95% hit rate
    
    // L2 Cache Parameters (per-core or shared)
    localparam real L2_SIZE_KB = 256;          // 256 KB (Intel/AMD typical)
    localparam real L2_HIT_CYCLES = 12;        // 10-15 cycles
    localparam real L2_HIT_RATE = 0.90;        // 90% of L1 misses hit in L2
    
    // L3 Cache Parameters (shared across cores)
    localparam real L3_SIZE_MB = 8;            // 8 MB (Intel/AMD typical)
    localparam real L3_HIT_CYCLES = 40;        // 30-50 cycles
    localparam real L3_HIT_RATE = 0.95;        // 95% of L2 misses hit in L3
    
    // Workload: SPEC CPU2006 Average (49.6% memory operations)
    localparam integer TOTAL_MEM_OPS = 10000;

    //=========================================================================
    // Test Signals
    //=========================================================================
    reg clk;
    real amat_no_cache, amat_l1, amat_l1l2, amat_l1l2l3;
    real speedup_l1, speedup_l1l2, speedup_l1l2l3;
    
    //=========================================================================
    // Clock Generation
    //=========================================================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    //=========================================================================
    // AMAT Calculation Functions
    // AMAT = Hit Time + Miss Rate × Miss Penalty
    // Note: Verilog requires functions to have at least one input
    //=========================================================================
    
    function real calc_amat_no_cache;
        input dummy;  // Required by Verilog syntax
        begin
            calc_amat_no_cache = MEM_LATENCY;  // Every access goes to memory
        end
    endfunction
    
    function real calc_amat_l1_only;
        input dummy;  // Required by Verilog syntax
        real miss_penalty;
        begin
            miss_penalty = MEM_LATENCY;  // L1 miss goes directly to memory
            calc_amat_l1_only = L1_HIT_CYCLES + (1 - L1_HIT_RATE) * miss_penalty;
        end
    endfunction
    
    function real calc_amat_l1_l2;
        input dummy;  // Required by Verilog syntax
        real l2_miss_penalty;
        real l1_miss_penalty;
        begin
            // L2 miss goes to memory
            l2_miss_penalty = MEM_LATENCY;
            // L1 miss penalty = L2 access time
            l1_miss_penalty = L2_HIT_CYCLES + (1 - L2_HIT_RATE) * l2_miss_penalty;
            // Total AMAT
            calc_amat_l1_l2 = L1_HIT_CYCLES + (1 - L1_HIT_RATE) * l1_miss_penalty;
        end
    endfunction
    
    function real calc_amat_l1_l2_l3;
        input dummy;  // Required by Verilog syntax
        real l3_miss_penalty;
        real l2_miss_penalty;
        real l1_miss_penalty;
        begin
            // L3 miss goes to memory
            l3_miss_penalty = MEM_LATENCY;
            // L2 miss penalty = L3 access time
            l2_miss_penalty = L3_HIT_CYCLES + (1 - L3_HIT_RATE) * l3_miss_penalty;
            // L1 miss penalty = L2 access time
            l1_miss_penalty = L2_HIT_CYCLES + (1 - L2_HIT_RATE) * l2_miss_penalty;
            // Total AMAT
            calc_amat_l1_l2_l3 = L1_HIT_CYCLES + (1 - L1_HIT_RATE) * l1_miss_penalty;
        end
    endfunction

    //=========================================================================
    // Main Test
    //=========================================================================
    initial begin
        #(CLK_PERIOD * 2);
        
        $display("");
        $display("╔═══════════════════════════════════════════════════════════════════════════════╗");
        $display("║   CONTRIBUTION 10: CACHE HIERARCHY COMPARISON ANALYSIS                       ║");
        $display("║   Author: 劉俊逸 (M143140014)                                                 ║");
        $display("╚═══════════════════════════════════════════════════════════════════════════════╝");
        $display("");
        
        //=====================================================================
        // Display Standard Parameters
        //=====================================================================
        $display("═══════════════════════════════════════════════════════════════════════════════");
        $display("                    STANDARD CACHE PARAMETERS                                  ");
        $display("    Source: Patterson & Hennessy, CAAQA 6th Ed. + Intel/AMD Specs             ");
        $display("═══════════════════════════════════════════════════════════════════════════════");
        $display("");
        $display("┌───────────┬──────────┬─────────────┬──────────────┐");
        $display("│ Level     │ Size     │ Hit Latency │ Hit Rate     │");
        $display("├───────────┼──────────┼─────────────┼──────────────┤");
        $display("│ L1 Cache  │   32 KB  │    1 cycle  │     95%%      │");
        $display("│ L2 Cache  │  256 KB  │   12 cycles │     90%%      │");
        $display("│ L3 Cache  │    8 MB  │   40 cycles │     95%%      │");
        $display("│ DRAM      │    N/A   │  100 cycles │     N/A      │");
        $display("└───────────┴──────────┴─────────────┴──────────────┘");
        $display("");
        
        //=====================================================================
        // Calculate AMAT for each configuration
        //=====================================================================
        amat_no_cache = calc_amat_no_cache(0);
        amat_l1 = calc_amat_l1_only(0);
        amat_l1l2 = calc_amat_l1_l2(0);
        amat_l1l2l3 = calc_amat_l1_l2_l3(0);
        
        speedup_l1 = amat_no_cache / amat_l1;
        speedup_l1l2 = amat_no_cache / amat_l1l2;
        speedup_l1l2l3 = amat_no_cache / amat_l1l2l3;
        
        //=====================================================================
        // AMAT Comparison Results
        //=====================================================================
        $display("═══════════════════════════════════════════════════════════════════════════════");
        $display("              AVERAGE MEMORY ACCESS TIME (AMAT) COMPARISON                     ");
        $display("═══════════════════════════════════════════════════════════════════════════════");
        $display("");
        $display("AMAT Formula (Patterson & Hennessy):");
        $display("  AMAT = Hit Time + Miss Rate × Miss Penalty");
        $display("");
        $display("┌─────────────────────┬─────────────────┬─────────────┬──────────────┐");
        $display("│ Configuration       │ AMAT (cycles)   │ Speedup     │ Improvement  │");
        $display("├─────────────────────┼─────────────────┼─────────────┼──────────────┤");
        $display("│ No Cache (Baseline) │    %6.1f        │    1.00x    │     ---      │", amat_no_cache);
        $display("│ L1 Only             │    %6.2f        │   %5.1fx    │   %5.1f%%     │", amat_l1, speedup_l1, (1 - amat_l1/amat_no_cache)*100);
        $display("│ L1 + L2             │    %6.2f        │   %5.1fx    │   %5.1f%%     │", amat_l1l2, speedup_l1l2, (1 - amat_l1l2/amat_no_cache)*100);
        $display("│ L1 + L2 + L3        │    %6.2f        │   %5.1fx    │   %5.1f%%     │", amat_l1l2l3, speedup_l1l2l3, (1 - amat_l1l2l3/amat_no_cache)*100);
        $display("└─────────────────────┴─────────────────┴─────────────┴──────────────┘");
        $display("");
        
        //=====================================================================
        // Incremental Benefit Analysis
        //=====================================================================
        $display("═══════════════════════════════════════════════════════════════════════════════");
        $display("                    INCREMENTAL BENEFIT ANALYSIS                               ");
        $display("═══════════════════════════════════════════════════════════════════════════════");
        $display("");
        $display("┌──────────────────────┬───────────────────────────────────────────────┐");
        $display("│ Adding...            │ Benefit                                       │");
        $display("├──────────────────────┼───────────────────────────────────────────────┤");
        $display("│ L1 Cache             │ AMAT: %.1f → %.2f cycles (%.1fx faster)       │", amat_no_cache, amat_l1, speedup_l1);
        $display("│ + L2 Cache           │ AMAT: %.2f → %.2f cycles (%.2fx additional)   │", amat_l1, amat_l1l2, amat_l1/amat_l1l2);
        $display("│ + L3 Cache           │ AMAT: %.2f → %.2f cycles (%.2fx additional)   │", amat_l1l2, amat_l1l2l3, amat_l1l2/amat_l1l2l3);
        $display("└──────────────────────┴───────────────────────────────────────────────┘");
        $display("");
        
        //=====================================================================
        // Total Cycles for Workload
        //=====================================================================
        $display("═══════════════════════════════════════════════════════════════════════════════");
        $display("              TOTAL MEMORY CYCLES FOR SPEC CPU2006 WORKLOAD                    ");
        $display("              (%0d memory operations)                                          ", TOTAL_MEM_OPS);
        $display("═══════════════════════════════════════════════════════════════════════════════");
        $display("");
        $display("┌─────────────────────┬──────────────────┬─────────────────┐");
        $display("│ Configuration       │ Total Cycles     │ Time Saved      │");
        $display("├─────────────────────┼──────────────────┼─────────────────┤");
        $display("│ No Cache            │    %10.0f    │       ---       │", amat_no_cache * TOTAL_MEM_OPS);
        $display("│ L1 Only             │    %10.0f    │    %10.0f   │", amat_l1 * TOTAL_MEM_OPS, (amat_no_cache - amat_l1) * TOTAL_MEM_OPS);
        $display("│ L1 + L2             │    %10.0f    │    %10.0f   │", amat_l1l2 * TOTAL_MEM_OPS, (amat_no_cache - amat_l1l2) * TOTAL_MEM_OPS);
        $display("│ L1 + L2 + L3        │    %10.0f    │    %10.0f   │", amat_l1l2l3 * TOTAL_MEM_OPS, (amat_no_cache - amat_l1l2l3) * TOTAL_MEM_OPS);
        $display("└─────────────────────┴──────────────────┴─────────────────┘");
        $display("");
        
        //=====================================================================
        // Summary
        //=====================================================================
        $display("╔═══════════════════════════════════════════════════════════════════════════════╗");
        $display("║                              KEY FINDINGS                                     ║");
        $display("╠═══════════════════════════════════════════════════════════════════════════════╣");
        $display("║  1. L1 Cache provides the LARGEST improvement (%.1fx speedup)               ║", speedup_l1);
        $display("║  2. L2 Cache adds %.2fx additional speedup (diminishing returns)            ║", amat_l1/amat_l1l2);
        $display("║  3. L3 Cache adds %.2fx additional speedup (further diminishing)            ║", amat_l1l2/amat_l1l2l3);
        $display("║  4. Full hierarchy achieves %.1fx total speedup vs no cache                 ║", speedup_l1l2l3);
        $display("╠═══════════════════════════════════════════════════════════════════════════════╣");
        $display("║  This demonstrates the 'Memory Wall' problem and why modern CPUs             ║");
        $display("║  require multi-level cache hierarchies.                                       ║");
        $display("╚═══════════════════════════════════════════════════════════════════════════════╝");
        $display("");
        
        #100;
        $finish;
    end

endmodule
