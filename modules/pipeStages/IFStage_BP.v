`include "defines.v"

// Enhanced IF Stage with Branch Prediction Support
// This version adds optional branch prediction to reduce branch penalties
// When bp_enable=1, uses predictor; when bp_enable=0, uses original behavior

module IFStage_BP (
  input  clk, 
  input  rst, 
  input  brTaken,           // Actual branch outcome from ID stage
  input  [`WORD_LEN-1:0] brOffset,
  input  freeze,
  input  bp_enable,          // Enable branch prediction
  
  // Branch prediction update signals
  input  branch_resolved,    // A branch has been resolved in ID
  input  [`WORD_LEN-1:0] resolved_pc,  // PC of resolved branch
  
  output [`WORD_LEN-1:0] PC, 
  output [`WORD_LEN-1:0] instruction,
  output predict_taken_out,  // Prediction for next instruction
  
  // Statistics outputs
  output [31:0] bp_total,
  output [31:0] bp_correct,
  output [31:0] bp_wrong
);

  wire [`WORD_LEN-1:0] adderIn1, adderOut, brOffserTimes4;
  wire [`WORD_LEN-1:0] predicted_pc, normal_pc;
  wire predict_taken;
  wire mispredicted;
  
  // Branch predictor instance
  branch_predictor #(
    .BHT_SIZE(16),
    .BHT_BITS(4)
  ) bp (
    .clk(clk),
    .rst(rst),
    .pc_IF(PC),
    .predict_taken(predict_taken),
    .update_en(branch_resolved),
    .pc_ID(resolved_pc),
    .actual_taken(brTaken),
    .predictions_total(bp_total),
    .predictions_correct(bp_correct),
    .predictions_wrong(bp_wrong)
  );
  
  // Misprediction detection
  assign mispredicted = branch_resolved && (predict_taken != brTaken);
  
  // PC selection logic
  // Priority: misprediction correction > prediction > normal
  wire use_branch_target;
  
  // If BP enabled: use prediction, but correct on misprediction
  // If BP disabled: use original behavior (brTaken)
  assign use_branch_target = bp_enable ? 
    (mispredicted ? brTaken : predict_taken) : brTaken;

  mux #(.LENGTH(`WORD_LEN)) adderInput (
    .in1(32'd4),
    .in2(brOffserTimes4),
    .sel(use_branch_target),
    .out(adderIn1)
  );

  adder add4 (
    .in1(adderIn1),
    .in2(PC),
    .out(adderOut)
  );

  register PCReg (
    .clk(clk),
    .rst(rst),
    .writeEn(~freeze),
    .regIn(adderOut),
    .regOut(PC)
  );

  instructionMem instructions (
    .rst(rst),
    .addr(PC),
    .instruction(instruction)
  );

  assign brOffserTimes4 = brOffset << 2;
  assign predict_taken_out = predict_taken;
  
endmodule // IFStage_BP
