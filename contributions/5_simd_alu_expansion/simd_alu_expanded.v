// SIMD ALU with Full Arithmetic Operations
// Demonstrates DLP + hardware unrolling with multiple operation types
// Supports: ADD, SUB, MUL, DIV, EXP (power)
//
// Operation encoding:
//   3'b000 = ADD
//   3'b001 = SUB
//   3'b010 = MUL
//   3'b011 = DIV
//   3'b100 = EXP (a ^ b, where b is small integer)

`ifndef SIMD_ALU_V
`define SIMD_ALU_V

module simd_alu #(
  parameter integer LANES = 8,
  parameter integer WIDTH = 16  // 16-bit for better precision in division
) (
  input  wire clk,
  input  wire rst,
  input  wire [LANES*WIDTH-1:0] a,
  input  wire [LANES*WIDTH-1:0] b,
  input  wire [2:0] op,
  output reg  [LANES*WIDTH-1:0] y,
  output reg  valid  // Result valid signal
);

  // Operation codes
  localparam OP_ADD = 3'b000;
  localparam OP_SUB = 3'b001;
  localparam OP_MUL = 3'b010;
  localparam OP_DIV = 3'b011;
  localparam OP_EXP = 3'b100;

  // Internal signals for each lane
  wire [WIDTH-1:0] lane_a [0:LANES-1];
  wire [WIDTH-1:0] lane_b [0:LANES-1];
  reg  [WIDTH-1:0] lane_y [0:LANES-1];
  
  // Generate lane input slicing
  genvar i;
  generate
    for (i = 0; i < LANES; i = i + 1) begin : gen_input_slice
      assign lane_a[i] = a[i*WIDTH +: WIDTH];
      assign lane_b[i] = b[i*WIDTH +: WIDTH];
    end
  endgenerate
  
  // Exponentiation function (iterative, for small exponents)
  function automatic [WIDTH-1:0] power;
    input [WIDTH-1:0] base;
    input [WIDTH-1:0] exp;
    reg [WIDTH-1:0] result;
    reg [WIDTH-1:0] count;
    begin
      if (exp == 0) begin
        power = 1;
      end else begin
        result = 1;
        for (count = 0; count < exp && count < 16; count = count + 1) begin
          result = result * base;
        end
        power = result;
      end
    end
  endfunction

  // Main computation logic - parallel for all lanes
  integer j;
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      valid <= 0;
      for (j = 0; j < LANES; j = j + 1) begin
        lane_y[j] <= 0;
      end
    end else begin
      valid <= 1;
      for (j = 0; j < LANES; j = j + 1) begin
        case (op)
          OP_ADD: lane_y[j] <= lane_a[j] + lane_b[j];
          OP_SUB: lane_y[j] <= lane_a[j] - lane_b[j];
          OP_MUL: lane_y[j] <= lane_a[j] * lane_b[j];
          OP_DIV: lane_y[j] <= (lane_b[j] != 0) ? (lane_a[j] / lane_b[j]) : {WIDTH{1'b1}}; // Div by 0 = max
          OP_EXP: lane_y[j] <= power(lane_a[j], lane_b[j]);
          default: lane_y[j] <= 0;
        endcase
      end
    end
  end
  
  // Output assignment - fixed for Vivado compatibility
  always @(*) begin
    y[0*WIDTH +: WIDTH] = lane_y[0];
    y[1*WIDTH +: WIDTH] = lane_y[1];
    y[2*WIDTH +: WIDTH] = lane_y[2];
    y[3*WIDTH +: WIDTH] = lane_y[3];
    y[4*WIDTH +: WIDTH] = lane_y[4];
    y[5*WIDTH +: WIDTH] = lane_y[5];
    y[6*WIDTH +: WIDTH] = lane_y[6];
    y[7*WIDTH +: WIDTH] = lane_y[7];
  end

endmodule

`endif
