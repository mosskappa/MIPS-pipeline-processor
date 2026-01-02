module add_sub_cla(sub, in1, in2, cin, out, cout, invalid);

	input signed [15:0] in1;
	input signed [15:0] in2;
 	output reg signed [15:0] out;
	wire signed [19:0] tempIn1;
	wire signed [19:0] tempIn2;
	reg signed [19:0] tempIn11;
	reg signed [19:0] tempIn22;
	reg [2:0] diffScaleFactor;
	reg [2:0] newScaleFactor;
	wire [19:0] tempOut;
	input sub;
	wire tempCout;
	input cin;
	output reg cout;
	output reg invalid;
	wire v;
	reg valid;

	carry_lookahead_adder_20bit cs0(sub, tempIn11, tempIn22, cin, tempOut, tempCout, v);

	//Sign Extend
	assign tempIn1[19:13] = (in1[12] == 1) ? 7'b1111111 : 7'b0000000;
	assign tempIn1[12:0] = in1[12:0];			
	assign tempIn2[19:13] = (in2[12] == 1) ? 7'b1111111 : 7'b0000000;
	assign tempIn2[12:0] = in2[12:0];

	//preprocessing	
	always @ (tempIn1 or tempIn2 or in1 or in2)
	begin

		if(in1[15:13] != in2[15:13]) begin

			if(in1[15:13] > in2[15:13]) begin
				diffScaleFactor = in1[15:13] - in2[15:13];
				tempIn22 = tempIn2 << diffScaleFactor;
				tempIn11 = tempIn1;
				newScaleFactor = in1[15:13];

			end else begin
				diffScaleFactor = in2[15:13] - in1[15:13];
				tempIn11 = tempIn1 << diffScaleFactor;
				tempIn22 = tempIn2;
				newScaleFactor = in2[15:13];			

			end

		end else begin
				newScaleFactor = in2[15:13];
				diffScaleFactor = 0;
				tempIn11 = tempIn1;
				tempIn22 = tempIn2;
		end
	end

	//post
	always @ (tempOut or newScaleFactor or v or tempCout)
	begin

			out[12:0] = tempOut[12:0];
			out[15:13] = newScaleFactor;

			valid = !v && ((tempOut[19:12] == 8'b11111111) || (tempOut[19:12] == 8'b00000000));
			invalid = !valid;
			cout = tempCout;

	end


endmodule
