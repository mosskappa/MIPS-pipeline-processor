module m_half_adder (CarryOut, Sum, A, B);
	output CarryOut, Sum;
	input  A, B;
  	assign Sum   = A ^ B;  // bitwise xor
  	assign CarryOut = A & B;  // bitwise and
endmodule 

