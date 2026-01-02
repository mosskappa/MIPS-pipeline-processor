module nbits_adder(CarryIn,a,b,sum,CarryOut);
	parameter N=8;
	input [N-1:0] a,b;
	input CarryIn;
	output [N-1:0] sum;
   	output  CarryOut;
 	wire [N-1:0] carry;
   	genvar i;
   	generate 
   		for(i=0;i<N;i=i+1)
     		begin: generate_N_bit_Adder
   			if(i==0) 
  				m_full_adder f(carry[0],sum[0],a[0],b[0],CarryIn);
   			else
  				m_full_adder f(carry[i],sum[i],a[i],b[i],carry[i-1]);
     			end
  		assign CarryOut = carry[N-1];
   	endgenerate
endmodule