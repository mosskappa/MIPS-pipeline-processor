module wallace_16bit_multiplier (A, B,product);
	output [31:0] product;
	input [15:0] A, B;
	wire [15:0] resultant[3:0];
	wire carry[4:0];
	wire [7:0] adding_result[4:0];

wallace_8bit_multiplier m1 (A[7:0],B[7:0],resultant[0]);
wallace_8bit_multiplier m2 (A[15:8],B[7:0],resultant[1]);
wallace_8bit_multiplier m3 (A[7:0],B[15:8],resultant[2]);
wallace_8bit_multiplier m4 (A[15:8],B[15:8],resultant[3]);
assign product[7:0] = resultant[0][7:0];

nbits_adder a1 (0,resultant[1][7:0],resultant[0][15:8],adding_result[0],carry[0]);
nbits_adder a2 (0,resultant[2][7:0],adding_result[0],adding_result[1],carry[1]);

assign product[15:8] = adding_result[1];


nbits_adder a3 (carry[1],resultant[1][15:8],resultant[2][15:8],adding_result[2],carry[2]);
nbits_adder a4 (carry[0],resultant[3][7:0],adding_result[2],adding_result[3],carry[3]);

assign product[23:16] = adding_result[3];

nbits_adder a5 (carry[3],resultant[3][15:8],{7'b0000000,carry[2]},adding_result[4],carry[4]);

assign product [31:24] = adding_result[4];





endmodule 
