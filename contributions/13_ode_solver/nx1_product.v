module nx1_product(multiplicand, multiplier, result);
	parameter DATA_WIDTH = 8;
	output [DATA_WIDTH-1:0] result;
	input multiplicand;
  	input  [DATA_WIDTH-1:0] multiplier;
  genvar i;
  generate 
    for (i = 0; i < DATA_WIDTH; i = i + 1) begin
          and a0 (result[i],multiplicand, multiplier[i]);
    end
  endgenerate	
endmodule
