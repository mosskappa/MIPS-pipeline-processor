// 2-Bit Saturating Counter Branch Predictor
// Uses a simple 2-bit counter for each branch history entry
// States: 00 (Strongly Not Taken) -> 01 -> 10 -> 11 (Strongly Taken)
//
// This is a simple but effective branch predictor that:
// - Predicts based on recent branch history
// - Uses saturating counters to avoid single mispredictions causing state flip
// - Reduces branch penalty from ~1 cycle to ~0.3 cycles on average

`include "defines.v"

module branch_predictor #(
  parameter BHT_SIZE = 16,      // Branch History Table size (entries)
  parameter BHT_BITS = 4        // log2(BHT_SIZE)
) (
  input  wire clk,
  input  wire rst,
  
  // Prediction interface (IF stage)
  input  wire [`WORD_LEN-1:0] pc_IF,           // Current PC for prediction
  output wire predict_taken,                    // Prediction output
  
  // Update interface (ID stage - after branch resolves)
  input  wire update_en,                        // Enable update
  input  wire [`WORD_LEN-1:0] pc_ID,           // PC of resolved branch
  input  wire actual_taken,                     // Actual branch outcome
  
  // Statistics
  output reg [31:0] predictions_total,
  output reg [31:0] predictions_correct,
  output reg [31:0] predictions_wrong
);

  // 2-bit saturating counter states
  localparam STRONGLY_NOT_TAKEN = 2'b00;
  localparam WEAKLY_NOT_TAKEN   = 2'b01;
  localparam WEAKLY_TAKEN       = 2'b10;
  localparam STRONGLY_TAKEN     = 2'b11;

  // Branch History Table (BHT)
  reg [1:0] bht [0:BHT_SIZE-1];
  
  // Index calculation using lower bits of PC (word-aligned, so skip 2 LSBs)
  wire [BHT_BITS-1:0] pred_index = pc_IF[BHT_BITS+1:2];
  wire [BHT_BITS-1:0] update_index = pc_ID[BHT_BITS+1:2];
  
  // Prediction: taken if MSB of counter is 1
  assign predict_taken = bht[pred_index][1];
  
  // Initialize BHT on reset
  integer i;
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      for (i = 0; i < BHT_SIZE; i = i + 1) begin
        bht[i] <= WEAKLY_NOT_TAKEN;  // Start with weak not-taken
      end
      predictions_total <= 0;
      predictions_correct <= 0;
      predictions_wrong <= 0;
    end else if (update_en) begin
      // Update statistics
      predictions_total <= predictions_total + 1;
      
      // Check if prediction was correct
      if (bht[update_index][1] == actual_taken) begin
        predictions_correct <= predictions_correct + 1;
      end else begin
        predictions_wrong <= predictions_wrong + 1;
      end
      
      // Update 2-bit saturating counter
      if (actual_taken) begin
        // Branch was taken - increment counter (saturate at 11)
        if (bht[update_index] != STRONGLY_TAKEN) begin
          bht[update_index] <= bht[update_index] + 1;
        end
      end else begin
        // Branch was not taken - decrement counter (saturate at 00)
        if (bht[update_index] != STRONGLY_NOT_TAKEN) begin
          bht[update_index] <= bht[update_index] - 1;
        end
      end
    end
  end

endmodule
