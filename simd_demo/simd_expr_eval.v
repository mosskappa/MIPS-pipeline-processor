// SIMD Expression Evaluator - Fixed Version
// Evaluates expressions like (a+b)*c/d^e with proper operator priority
// Uses pipelined stages to handle operator precedence:
//   Priority: ^ (highest) > * / > + - (lowest)
//
// Fixed expression format: (a+b)*c/d^e
// The evaluator demonstrates operator priority handling

`ifndef SIMD_EXPR_EVAL_V
`define SIMD_EXPR_EVAL_V

module simd_expr_eval #(
  parameter integer LANES = 8,
  parameter integer WIDTH = 16
) (
  input  wire clk,
  input  wire rst,
  input  wire start,
  // Operands for expression (a+b)*c/d^e
  input  wire [LANES*WIDTH-1:0] a,
  input  wire [LANES*WIDTH-1:0] b,
  input  wire [LANES*WIDTH-1:0] c,
  input  wire [LANES*WIDTH-1:0] d,
  input  wire [LANES*WIDTH-1:0] e,
  output reg  [LANES*WIDTH-1:0] result,
  output reg  done
);

  // Operation codes
  localparam OP_ADD = 3'b000;
  localparam OP_MUL = 3'b010;
  localparam OP_DIV = 3'b011;
  localparam OP_EXP = 3'b100;

  // Pipeline state machine with wait states
  localparam IDLE       = 4'd0;
  localparam STAGE_EXP  = 4'd1;  // Compute d^e
  localparam WAIT_EXP   = 4'd2;
  localparam STAGE_ADD  = 4'd3;  // Compute a+b
  localparam WAIT_ADD   = 4'd4;
  localparam STAGE_MUL  = 4'd5;  // Compute (a+b)*c
  localparam WAIT_MUL   = 4'd6;
  localparam STAGE_DIV  = 4'd7;  // Compute result/d^e
  localparam WAIT_DIV   = 4'd8;
  localparam DONE_STATE = 4'd9;
  
  reg [3:0] state;
  
  // Intermediate results
  reg [LANES*WIDTH-1:0] d_exp_e;     // d^e
  reg [LANES*WIDTH-1:0] a_plus_b;    // a+b
  reg [LANES*WIDTH-1:0] times_c;     // (a+b)*c
  
  // Exponentiation function
  function automatic [WIDTH-1:0] power;
    input [WIDTH-1:0] base;
    input [WIDTH-1:0] exp;
    reg [WIDTH-1:0] res;
    integer i;
    begin
      res = 1;
      for (i = 0; i < exp && i < 16; i = i + 1) begin
        res = res * base;
      end
      power = res;
    end
  endfunction
  
  // Per-lane computation using generate
  genvar lane;
  
  // State machine
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= IDLE;
      d_exp_e <= 0;
      a_plus_b <= 0;
      times_c <= 0;
      result <= 0;
      done <= 0;
    end else begin
      done <= 0;
      
      case (state)
        IDLE: begin
          if (start) begin
            state <= STAGE_EXP;
          end
        end
        
        STAGE_EXP: begin
          // Compute d^e for all lanes
          state <= WAIT_EXP;
        end
        
        WAIT_EXP: begin
          // Store d^e result
          integer i;
          for (i = 0; i < LANES; i = i + 1) begin
            d_exp_e[i*WIDTH +: WIDTH] <= power(d[i*WIDTH +: WIDTH], e[i*WIDTH +: WIDTH]);
          end
          state <= STAGE_ADD;
        end
        
        STAGE_ADD: begin
          // Compute a+b for all lanes
          state <= WAIT_ADD;
        end
        
        WAIT_ADD: begin
          // Store a+b result
          integer i;
          for (i = 0; i < LANES; i = i + 1) begin
            a_plus_b[i*WIDTH +: WIDTH] <= a[i*WIDTH +: WIDTH] + b[i*WIDTH +: WIDTH];
          end
          state <= STAGE_MUL;
        end
        
        STAGE_MUL: begin
          // Compute (a+b)*c for all lanes
          state <= WAIT_MUL;
        end
        
        WAIT_MUL: begin
          // Store (a+b)*c result
          integer i;
          for (i = 0; i < LANES; i = i + 1) begin
            times_c[i*WIDTH +: WIDTH] <= a_plus_b[i*WIDTH +: WIDTH] * c[i*WIDTH +: WIDTH];
          end
          state <= STAGE_DIV;
        end
        
        STAGE_DIV: begin
          // Compute final result
          state <= WAIT_DIV;
        end
        
        WAIT_DIV: begin
          // Store final result: (a+b)*c / d^e
          integer i;
          for (i = 0; i < LANES; i = i + 1) begin
            if (d_exp_e[i*WIDTH +: WIDTH] != 0) begin
              result[i*WIDTH +: WIDTH] <= times_c[i*WIDTH +: WIDTH] / d_exp_e[i*WIDTH +: WIDTH];
            end else begin
              result[i*WIDTH +: WIDTH] <= {WIDTH{1'b1}};  // Max value for div by 0
            end
          end
          state <= DONE_STATE;
        end
        
        DONE_STATE: begin
          done <= 1;
          state <= IDLE;
        end
        
        default: state <= IDLE;
      endcase
    end
  end

endmodule

`endif
