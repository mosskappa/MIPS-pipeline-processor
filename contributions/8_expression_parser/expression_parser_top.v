module expression_parser_top(
    input wire clk,
    input wire rst,
    input wire input_stb,
    input wire [31:0] input_data,
    input wire is_input_operator,
    output wire input_ack,
    output wire output_stb,
    output wire [31:0] output_data,
    input wire output_ack
);

    wire [31:0] conv_data;
    wire conv_stb, conv_is_op, conv_ack;

    converter u_conv(
        .CLK(clk),
        .RST(rst),
        .input_stb(input_stb),
        .input_data(input_data),
        .is_input_operator(is_input_operator),
        .input_ack(input_ack),
        .output_stb(conv_stb),
        .output_data(conv_data),
        .is_output_operator(conv_is_op),
        .output_ack(conv_ack)
    );

    calculator u_calc(
        .CLK(clk),
        .RST(rst),
        .input_stb(conv_stb),
        .input_data(conv_data),
        .is_input_operator(conv_is_op),
        .input_ack(conv_ack),
        .output_stb(output_stb),
        .output_data(output_data),
        .output_ack(output_ack)
    );

endmodule
