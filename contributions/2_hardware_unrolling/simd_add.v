// Simple SIMD adder (structure-unrolled via generate)
// Demonstrates DLP + unrolling in Verilog.

module simd_add #(
  parameter integer LANES = 8,
  parameter integer WIDTH = 8
) (
  input  wire [LANES*WIDTH-1:0] a,
  input  wire [LANES*WIDTH-1:0] b,
  output wire [LANES*WIDTH-1:0] y
);
  genvar i;
  generate
    for (i = 0; i < LANES; i = i + 1) begin : gen_lane
      wire [WIDTH-1:0] ai = a[i*WIDTH +: WIDTH];
      wire [WIDTH-1:0] bi = b[i*WIDTH +: WIDTH];
      assign y[i*WIDTH +: WIDTH] = ai + bi;
    end
  endgenerate
endmodule
