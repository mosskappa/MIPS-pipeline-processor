module m_full_adder (CarryOut, Sum, A, B, CarryIn);
	wire   w_WIRE_1;
 	wire   w_WIRE_2;
 	wire   w_WIRE_3;
       	output CarryOut, Sum;
	input  A, B, CarryIn;

  	assign w_WIRE_1 = A ^ B;
  	assign w_WIRE_2 = w_WIRE_1 & CarryIn;
  	assign w_WIRE_3 = A & B;

	assign CarryOut = w_WIRE_2 | w_WIRE_3;
  	assign Sum   = w_WIRE_1 ^ CarryIn;

endmodule
