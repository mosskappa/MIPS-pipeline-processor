module carry_lookahead_adder_4bit(in0,in1, cin, sum, cout, v);

	input [3:0] in0,in1;
	input cin;
	output [3:0] sum;
	output cout;
	output v;
 
	wire [3:0] p,g,c;
 
	assign p = in0 ^ in1;
	assign g = in0 & in1;
 
	assign c[0] = cin;
	assign c[1] = g[0] | (p[0] & c[0]);
	assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
	assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
	assign cout = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
	
	assign v = cout ^ c[3];
	assign sum = p ^ c;
 
endmodule
