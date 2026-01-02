module booth_16bit_multiplier(A, B, product);
    input signed [15:0] A,B;
    output signed [31:0] product;
    reg signed [31:0] product;
    reg signed [15:0] Q,Acc;
    reg  Q0;
    integer n; 
always @(A,B)
	begin
	Q0 = 0;
	Q = A;
	Acc = 16'h0;
	for(n = 16; n  > 0; n = n - 1) begin
	case({Q[0],Q0})
		2'b10 : Acc = Acc - B;
		2'b01 : Acc = Acc + B;
		default : begin end
	endcase
	Q0 = Q[0];
	Q = Q >> 1;
	Q[15] = Acc[0];
	Acc = Acc >> 1;
	Acc[15] = Acc[14];
	end
	product = {Acc,Q};
	
end
 endmodule
