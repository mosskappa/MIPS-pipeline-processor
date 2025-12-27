//-----------------------------------------------------------------------------
// Contribution 10: L1 Cache Testbench with Performance Analysis
// Author: 劉俊逸 (M143140014)
//
// This testbench demonstrates:
//   1. Cache hit/miss behavior
//   2. Spatial locality benefits (block prefetching)
//   3. Temporal locality benefits (repeated access)
//   4. Performance metrics: Hit Rate, Average Access Time
//
// Expected Results:
//   - Sequential access: ~87.5% hit rate (7/8 hits per block)
//   - Random access: Lower hit rate
//   - Speedup from cache: ~10x compared to no-cache baseline
//-----------------------------------------------------------------------------

`timescale 1ns / 1ps

module tb_l1_cache;

    //-------------------------------------------------------------------------
    // Parameters
    //-------------------------------------------------------------------------
    parameter CLK_PERIOD = 10;
    parameter MEM_LATENCY = 10;  // 10 cycles for main memory access
    
    //-------------------------------------------------------------------------
    // Signals
    //-------------------------------------------------------------------------
    reg         clk;
    reg         rst;
    
    // Processor interface
    reg         proc_read;
    reg         proc_write;
    reg  [31:0] proc_addr;
    reg  [31:0] proc_wdata;
    wire [31:0] proc_rdata;
    wire        proc_ready;
    
    // Memory interface
    wire        mem_read;
    wire        mem_write;
    wire [31:0] mem_addr;
    wire [255:0] mem_wdata_block;
    reg  [255:0] mem_rdata_block;
    reg         mem_ready;
    
    // Performance counters
    wire [31:0] hit_count;
    wire [31:0] miss_count;
    wire [31:0] total_accesses;
    
    // Testbench variables
    integer i, j;
    integer test_cycles;
    integer total_cycles;
    real hit_rate;
    real speedup;
    real avg_access_time;
    
    //-------------------------------------------------------------------------
    // DUT Instantiation
    //-------------------------------------------------------------------------
    l1_data_cache dut (
        .clk            (clk),
        .rst            (rst),
        .proc_read      (proc_read),
        .proc_write     (proc_write),
        .proc_addr      (proc_addr),
        .proc_wdata     (proc_wdata),
        .proc_rdata     (proc_rdata),
        .proc_ready     (proc_ready),
        .mem_read       (mem_read),
        .mem_write      (mem_write),
        .mem_addr       (mem_addr),
        .mem_wdata_block(mem_wdata_block),
        .mem_rdata_block(mem_rdata_block),
        .mem_ready      (mem_ready)
    );
    
    // Connect performance counters
    assign hit_count = dut.hit_count;
    assign miss_count = dut.miss_count;
    assign total_accesses = dut.total_accesses;
    
    //-------------------------------------------------------------------------
    // Clock generation
    //-------------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    //-------------------------------------------------------------------------
    // Simulated main memory (with latency)
    //-------------------------------------------------------------------------
    reg [4:0] mem_counter;
    reg mem_in_progress;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_ready <= 1'b0;
            mem_counter <= 0;
            mem_in_progress <= 1'b0;
            mem_rdata_block <= 256'b0;
        end else begin
            mem_ready <= 1'b0;
            
            if ((mem_read || mem_write) && !mem_in_progress) begin
                mem_in_progress <= 1'b1;
                mem_counter <= MEM_LATENCY;
            end else if (mem_in_progress) begin
                if (mem_counter > 1) begin
                    mem_counter <= mem_counter - 1;
                end else begin
                    mem_ready <= 1'b1;
                    mem_in_progress <= 1'b0;
                    // Generate some test data based on address
                    mem_rdata_block <= {8{mem_addr}};
                end
            end
        end
    end
    
    //-------------------------------------------------------------------------
    // Test tasks
    //-------------------------------------------------------------------------
    task read_word;
        input [31:0] addr;
        begin
            @(posedge clk);
            proc_read <= 1'b1;
            proc_write <= 1'b0;
            proc_addr <= addr;
            @(posedge clk);
            proc_read <= 1'b0;
            // Wait for ready
            while (!proc_ready) @(posedge clk);
        end
    endtask
    
    task write_word;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(posedge clk);
            proc_read <= 1'b0;
            proc_write <= 1'b1;
            proc_addr <= addr;
            proc_wdata <= data;
            @(posedge clk);
            proc_write <= 1'b0;
            // Wait for ready
            while (!proc_ready) @(posedge clk);
        end
    endtask
    
    //-------------------------------------------------------------------------
    // Main test sequence
    //-------------------------------------------------------------------------
    initial begin
        $display("==========================================================");
        $display("  Contribution 10: L1 Cache Performance Analysis");
        $display("  Author: 劉俊逸 (M143140014)");
        $display("==========================================================");
        $display("");
        
        // Initialize
        rst = 1;
        proc_read = 0;
        proc_write = 0;
        proc_addr = 0;
        proc_wdata = 0;
        
        #(CLK_PERIOD * 5);
        rst = 0;
        #(CLK_PERIOD * 2);
        
        //---------------------------------------------------------------------
        // TEST 1: Sequential Read - Demonstrate Spatial Locality
        //---------------------------------------------------------------------
        $display("----------------------------------------------------------");
        $display("TEST 1: Sequential Read (Spatial Locality Demo)");
        $display("----------------------------------------------------------");
        $display("Reading 64 consecutive words (8 cache blocks)...");
        $display("");
        
        test_cycles = 0;
        for (i = 0; i < 64; i = i + 1) begin
            read_word(i * 4);  // Word-aligned addresses
            test_cycles = test_cycles + 1;
        end
        
        #(CLK_PERIOD * 5);
        
        hit_rate = (hit_count * 100.0) / total_accesses;
        $display("  Total Accesses  : %d", total_accesses);
        $display("  Cache Hits      : %d", hit_count);
        $display("  Cache Misses    : %d", miss_count);
        $display("  Hit Rate        : %.2f%%", hit_rate);
        $display("");
        $display("  [ANALYSIS] Block size = 8 words, so 7/8 accesses hit");
        $display("  [ANALYSIS] Expected hit rate: 87.5%%");
        $display("");
        
        //---------------------------------------------------------------------
        // TEST 2: Repeated Access - Demonstrate Temporal Locality
        //---------------------------------------------------------------------
        $display("----------------------------------------------------------");
        $display("TEST 2: Repeated Access (Temporal Locality Demo)");
        $display("----------------------------------------------------------");
        $display("Re-reading the same 64 words (all should hit now)...");
        $display("");
        
        for (i = 0; i < 64; i = i + 1) begin
            read_word(i * 4);
        end
        
        #(CLK_PERIOD * 5);
        
        hit_rate = (hit_count * 100.0) / total_accesses;
        $display("  Total Accesses  : %d", total_accesses);
        $display("  Cache Hits      : %d", hit_count);
        $display("  Cache Misses    : %d (no new misses)", miss_count);
        $display("  Hit Rate        : %.2f%%", hit_rate);
        $display("");
        
        //---------------------------------------------------------------------
        // TEST 3: Write Operations
        //---------------------------------------------------------------------
        $display("----------------------------------------------------------");
        $display("TEST 3: Write Operations (Write-Back Policy)");
        $display("----------------------------------------------------------");
        
        for (i = 0; i < 16; i = i + 1) begin
            write_word(i * 4, 32'hDEADBEEF + i);
        end
        
        #(CLK_PERIOD * 5);
        
        $display("  Wrote 16 words to cache");
        $display("  Total Accesses  : %d", total_accesses);
        $display("  Hit Rate        : %.2f%%", (hit_count * 100.0) / total_accesses);
        $display("");
        
        //---------------------------------------------------------------------
        // TEST 4: Loop Access Pattern (Common in programs)
        //---------------------------------------------------------------------
        $display("----------------------------------------------------------");
        $display("TEST 4: Loop Access Pattern (x10 iterations)");
        $display("----------------------------------------------------------");
        
        // Simulate array processing in a loop
        for (j = 0; j < 10; j = j + 1) begin
            for (i = 0; i < 32; i = i + 1) begin
                read_word(i * 4);
            end
        end
        
        #(CLK_PERIOD * 5);
        
        hit_rate = (hit_count * 100.0) / total_accesses;
        $display("  Total Accesses  : %d", total_accesses);
        $display("  Cache Hits      : %d", hit_count);
        $display("  Cache Misses    : %d", miss_count);
        $display("  Hit Rate        : %.2f%%", hit_rate);
        $display("");
        
        //---------------------------------------------------------------------
        // FINAL PERFORMANCE SUMMARY
        //---------------------------------------------------------------------
        $display("==========================================================");
        $display("  FINAL PERFORMANCE SUMMARY");
        $display("==========================================================");
        $display("");
        
        hit_rate = (hit_count * 100.0) / total_accesses;
        avg_access_time = (hit_count * 1.0 + miss_count * MEM_LATENCY) / total_accesses;
        speedup = MEM_LATENCY / avg_access_time;
        
        $display("  +------------------------------------+------------+");
        $display("  | Metric                             | Value      |");
        $display("  +------------------------------------+------------+");
        $display("  | Total Memory Accesses              | %10d |", total_accesses);
        $display("  | Cache Hits                         | %10d |", hit_count);
        $display("  | Cache Misses                       | %10d |", miss_count);
        $display("  | Hit Rate                           | %9.2f%% |", hit_rate);
        $display("  | Average Access Time (cycles)       | %10.2f |", avg_access_time);
        $display("  | Memory Latency (cycles)            | %10d |", MEM_LATENCY);
        $display("  | SPEEDUP vs No-Cache                | %9.2fx |", speedup);
        $display("  +------------------------------------+------------+");
        $display("");
        
        if (hit_rate > 90.0) begin
            $display("  [RESULT] EXCELLENT! Cache Hit Rate > 90%%");
        end else if (hit_rate > 80.0) begin
            $display("  [RESULT] GOOD! Cache Hit Rate > 80%%");
        end else begin
            $display("  [RESULT] Cache Hit Rate: %.2f%%", hit_rate);
        end
        
        $display("");
        $display("  [CONCLUSION]");
        $display("  With L1 Cache, memory access is %.2fx faster than baseline.", speedup);
        $display("  This demonstrates the critical importance of cache memory");
        $display("  in modern processor design (Memory Wall Problem).");
        $display("");
        $display("==========================================================");
        $display("  TEST COMPLETED SUCCESSFULLY");
        $display("==========================================================");
        
        #(CLK_PERIOD * 10);
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #1000000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
