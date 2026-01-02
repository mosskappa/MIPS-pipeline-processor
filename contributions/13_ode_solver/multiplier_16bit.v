// The module takes 2 arguments with Fixed point representation and calculate their multiplication
module multiplier_16bit(first_operand, second_operand, out,enable,overflow);
	// Fixed Point multiplication using Q format
	// The number starts from bit "15" to bit "3" and total bits is 13,
	// and its scale factor start from bit "2" to bit "0" and total bits is 3
	input signed[15:0] first_operand;
	input signed[15:0] second_operand;
	wire [31:0] temp_result_wire;
	reg signed[31:0] temp_result;
	reg [2:0]first_operand_scale_factor,second_operand_scale_factor,output_scale_factor, shift_factor = 0;
	reg signed[15:0]first_operand_number,second_operand_number;
        reg signed[12:0] output_number;
	output reg signed[15:0] out;

	output reg overflow;
	input enable;


	//choose your multiplier by commenting the other one

//	wallace_16bit_multiplier mult (first_operand_number, second_operand_number,temp_result_wire);
	booth_16bit_multiplier mult (first_operand_number, second_operand_number,temp_result_wire);


	always @(*)
	begin
	if(enable) begin
		// Extracting the first number and its scale factor.
		first_operand_scale_factor = first_operand[15:13];
		first_operand_number[15:13] = (first_operand[12] == 1) ? 3'b111 : 3'b000;  // Sign extend
		first_operand_number[12:0] = first_operand[12:0];
		// Extracting the second number and its scale factor.
		second_operand_scale_factor = second_operand[15:13];
		second_operand_number[15:13] = (second_operand[12] == 1) ? 3'b111 : 3'b000; // Sign extend
		second_operand_number[12:0] = second_operand[12:0];

		// Calulating the output number
		//temp_result = first_operand_number * second_operand_number;
		temp_result = temp_result_wire;



		// Calculate new scale factor
		if(first_operand_scale_factor>second_operand_scale_factor)
		begin
			output_scale_factor = first_operand_scale_factor;
			shift_factor = second_operand_scale_factor;
		end
		else
		begin
			output_scale_factor = second_operand_scale_factor;
			shift_factor = first_operand_scale_factor;
		end
		/*
		temp_result_scale_factor = first_operand_scale_factor + second_operand_scale_factor;
		// If the result of the scale factor addition is greater than 7 we should make the scale factor of the output = 7
		// , and shift the resulted number right
		if(temp_result_scale_factor[3] > 1'b1)
		begin
			output_scale_factor = 3'b111;
			shift_factor = temp_result_scale_factor - 3'b111;
		end
		else
		begin
			shift_factor = 4'b0000;
			output_scale_factor = temp_result_scale_factor[2:0];
		end
		*/
		temp_result = temp_result >>> shift_factor; // Shift and keep the sign
		// Assign output number with the same Fixed point representation mentioned above
		output_number = temp_result[12:0];
		assign out = {output_scale_factor,output_number} ;
		assign overflow = ((temp_result[31:12] == 20'h0) || (temp_result[31:12] == 20'hFFFFF))? 1'b0 : 1'b1;

	end
	end
endmodule
