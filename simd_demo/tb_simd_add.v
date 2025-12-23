`timescale 1ns/1ns

module tb_simd_add;
  localparam integer LANES = 8;
  localparam integer WIDTH = 8;

  reg  [LANES*WIDTH-1:0] a;
  reg  [LANES*WIDTH-1:0] b;
  wire [LANES*WIDTH-1:0] y;

  simd_add #(.LANES(LANES), .WIDTH(WIDTH)) dut (
    .a(a),
    .b(b),
    .y(y)
  );

  integer i;
  reg [WIDTH-1:0] tmp_a;
  reg [WIDTH-1:0] tmp_b;

  initial begin
    // Lane i: a=i, b=2*i
    a = 0;
    b = 0;
    for (i = 0; i < LANES; i = i + 1) begin
      tmp_a = i;
      tmp_b = 2*i;
      a[i*WIDTH +: WIDTH] = tmp_a;
      b[i*WIDTH +: WIDTH] = tmp_b;
    end

    #1;

    for (i = 0; i < LANES; i = i + 1) begin
      if (y[i*WIDTH +: WIDTH] !== (3*i)) begin
        $display("FAIL lane=%0d got=%0d expected=%0d", i, y[i*WIDTH +: WIDTH], 3*i);
        $finish;
      end
    end

    $display("PASS simd_add LANES=%0d WIDTH=%0d", LANES, WIDTH);
    $finish;
  end
endmodule
