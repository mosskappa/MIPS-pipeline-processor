//-----------------------------------------------------------------------------
// Contribution 10: L1 Data Cache (Direct-Mapped)
// Author: 劉俊逸 (M143140014)
// Source Attribution: Inspired by raghavgoyal283/Cache-Controller
// 
// Features:
//   - 256 cache lines (8KB cache with 32-byte blocks)
//   - Direct-mapped organization
//   - Write-back, write-allocate policy
//   - Performance counters (hit/miss tracking)
//-----------------------------------------------------------------------------

module l1_data_cache #(
    parameter ADDR_WIDTH     = 32,
    parameter DATA_WIDTH     = 32,
    parameter CACHE_SIZE     = 8192,      // 8KB cache
    parameter BLOCK_SIZE     = 32,         // 32 bytes per block (8 words)
    parameter NUM_BLOCKS     = 256,        // CACHE_SIZE / BLOCK_SIZE
    parameter INDEX_BITS     = 8,          // log2(NUM_BLOCKS)
    parameter OFFSET_BITS    = 5,          // log2(BLOCK_SIZE)
    parameter TAG_BITS       = 19          // ADDR_WIDTH - INDEX_BITS - OFFSET_BITS
)(
    input  wire                    clk,
    input  wire                    rst,
    
    // Processor interface
    input  wire                    proc_read,
    input  wire                    proc_write,
    input  wire [ADDR_WIDTH-1:0]   proc_addr,
    input  wire [DATA_WIDTH-1:0]   proc_wdata,
    output reg  [DATA_WIDTH-1:0]   proc_rdata,
    output reg                     proc_ready,
    
    // Memory interface (simulated main memory)
    output reg                     mem_read,
    output reg                     mem_write,
    output reg  [ADDR_WIDTH-1:0]   mem_addr,
    output reg  [BLOCK_SIZE*8-1:0] mem_wdata_block,
    input  wire [BLOCK_SIZE*8-1:0] mem_rdata_block,
    input  wire                    mem_ready,
    
    // Performance counters
    output reg  [31:0]             hit_count,
    output reg  [31:0]             miss_count,
    output reg  [31:0]             total_accesses
);

    //-------------------------------------------------------------------------
    // Address breakdown
    //-------------------------------------------------------------------------
    wire [TAG_BITS-1:0]    addr_tag;
    wire [INDEX_BITS-1:0]  addr_index;
    wire [OFFSET_BITS-1:0] addr_offset;
    
    assign addr_tag    = proc_addr[ADDR_WIDTH-1 : INDEX_BITS+OFFSET_BITS];
    assign addr_index  = proc_addr[INDEX_BITS+OFFSET_BITS-1 : OFFSET_BITS];
    assign addr_offset = proc_addr[OFFSET_BITS-1 : 0];
    
    //-------------------------------------------------------------------------
    // Cache storage
    //-------------------------------------------------------------------------
    reg [TAG_BITS-1:0]      tag_array   [0:NUM_BLOCKS-1];
    reg [BLOCK_SIZE*8-1:0]  data_array  [0:NUM_BLOCKS-1];
    reg                     valid_array [0:NUM_BLOCKS-1];
    reg                     dirty_array [0:NUM_BLOCKS-1];
    
    //-------------------------------------------------------------------------
    // State machine
    //-------------------------------------------------------------------------
    localparam IDLE         = 3'd0;
    localparam COMPARE_TAG  = 3'd1;
    localparam WRITE_BACK   = 3'd2;
    localparam ALLOCATE     = 3'd3;
    localparam UPDATE       = 3'd4;
    
    reg [2:0] state, next_state;
    
    // Cache hit detection
    wire cache_hit = valid_array[addr_index] && (tag_array[addr_index] == addr_tag);
    
    // Word selection within block
    wire [2:0] word_select = addr_offset[4:2];  // Select 1 of 8 words
    
    //-------------------------------------------------------------------------
    // State machine - sequential
    //-------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    //-------------------------------------------------------------------------
    // State machine - combinational
    //-------------------------------------------------------------------------
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (proc_read || proc_write)
                    next_state = COMPARE_TAG;
            end
            
            COMPARE_TAG: begin
                if (cache_hit) begin
                    next_state = IDLE;  // Hit - done
                end else if (dirty_array[addr_index] && valid_array[addr_index]) begin
                    next_state = WRITE_BACK;  // Miss with dirty block
                end else begin
                    next_state = ALLOCATE;  // Miss - fetch from memory
                end
            end
            
            WRITE_BACK: begin
                if (mem_ready)
                    next_state = ALLOCATE;
            end
            
            ALLOCATE: begin
                if (mem_ready)
                    next_state = UPDATE;
            end
            
            UPDATE: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    //-------------------------------------------------------------------------
    // Data path
    //-------------------------------------------------------------------------
    integer i;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all cache lines
            for (i = 0; i < NUM_BLOCKS; i = i + 1) begin
                valid_array[i] <= 1'b0;
                dirty_array[i] <= 1'b0;
                tag_array[i]   <= {TAG_BITS{1'b0}};
            end
            
            proc_ready    <= 1'b0;
            proc_rdata    <= 32'b0;
            mem_read      <= 1'b0;
            mem_write     <= 1'b0;
            mem_addr      <= 32'b0;
            hit_count     <= 32'b0;
            miss_count    <= 32'b0;
            total_accesses <= 32'b0;
            
        end else begin
            // Default outputs
            proc_ready <= 1'b0;
            mem_read   <= 1'b0;
            mem_write  <= 1'b0;
            
            case (state)
                IDLE: begin
                    if (proc_read || proc_write) begin
                        total_accesses <= total_accesses + 1;
                    end
                end
                
                COMPARE_TAG: begin
                    if (cache_hit) begin
                        // Cache HIT
                        hit_count <= hit_count + 1;
                        proc_ready <= 1'b1;
                        
                        if (proc_read) begin
                            // Read hit - extract word from block
                            case (word_select)
                                3'd0: proc_rdata <= data_array[addr_index][31:0];
                                3'd1: proc_rdata <= data_array[addr_index][63:32];
                                3'd2: proc_rdata <= data_array[addr_index][95:64];
                                3'd3: proc_rdata <= data_array[addr_index][127:96];
                                3'd4: proc_rdata <= data_array[addr_index][159:128];
                                3'd5: proc_rdata <= data_array[addr_index][191:160];
                                3'd6: proc_rdata <= data_array[addr_index][223:192];
                                3'd7: proc_rdata <= data_array[addr_index][255:224];
                                default: proc_rdata <= 32'b0;
                            endcase
                        end else begin
                            // Write hit - update word in block
                            case (word_select)
                                3'd0: data_array[addr_index][31:0]     <= proc_wdata;
                                3'd1: data_array[addr_index][63:32]   <= proc_wdata;
                                3'd2: data_array[addr_index][95:64]   <= proc_wdata;
                                3'd3: data_array[addr_index][127:96]  <= proc_wdata;
                                3'd4: data_array[addr_index][159:128] <= proc_wdata;
                                3'd5: data_array[addr_index][191:160] <= proc_wdata;
                                3'd6: data_array[addr_index][223:192] <= proc_wdata;
                                3'd7: data_array[addr_index][255:224] <= proc_wdata;
                            endcase
                            dirty_array[addr_index] <= 1'b1;
                        end
                    end else begin
                        // Cache MISS
                        miss_count <= miss_count + 1;
                    end
                end
                
                WRITE_BACK: begin
                    // Write dirty block back to memory
                    mem_write <= 1'b1;
                    mem_addr  <= {tag_array[addr_index], addr_index, {OFFSET_BITS{1'b0}}};
                    mem_wdata_block <= data_array[addr_index];
                end
                
                ALLOCATE: begin
                    // Fetch block from memory
                    mem_read <= 1'b1;
                    mem_addr <= {proc_addr[ADDR_WIDTH-1:OFFSET_BITS], {OFFSET_BITS{1'b0}}};
                end
                
                UPDATE: begin
                    // Update cache with new block
                    data_array[addr_index]  <= mem_rdata_block;
                    tag_array[addr_index]   <= addr_tag;
                    valid_array[addr_index] <= 1'b1;
                    dirty_array[addr_index] <= 1'b0;
                    proc_ready <= 1'b1;
                    
                    // Handle the original request
                    if (proc_read) begin
                        case (word_select)
                            3'd0: proc_rdata <= mem_rdata_block[31:0];
                            3'd1: proc_rdata <= mem_rdata_block[63:32];
                            3'd2: proc_rdata <= mem_rdata_block[95:64];
                            3'd3: proc_rdata <= mem_rdata_block[127:96];
                            3'd4: proc_rdata <= mem_rdata_block[159:128];
                            3'd5: proc_rdata <= mem_rdata_block[191:160];
                            3'd6: proc_rdata <= mem_rdata_block[223:192];
                            3'd7: proc_rdata <= mem_rdata_block[255:224];
                            default: proc_rdata <= 32'b0;
                        endcase
                    end else begin
                        // Write allocate - update the fetched block
                        case (word_select)
                            3'd0: data_array[addr_index][31:0]     <= proc_wdata;
                            3'd1: data_array[addr_index][63:32]   <= proc_wdata;
                            3'd2: data_array[addr_index][95:64]   <= proc_wdata;
                            3'd3: data_array[addr_index][127:96]  <= proc_wdata;
                            3'd4: data_array[addr_index][159:128] <= proc_wdata;
                            3'd5: data_array[addr_index][191:160] <= proc_wdata;
                            3'd6: data_array[addr_index][223:192] <= proc_wdata;
                            3'd7: data_array[addr_index][255:224] <= proc_wdata;
                        endcase
                        dirty_array[addr_index] <= 1'b1;
                    end
                end
            endcase
        end
    end

endmodule
