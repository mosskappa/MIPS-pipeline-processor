`timescale 1ns / 1ps

// Top module connecting Converter and Calculator
module expression_parser_top(
    input wire CLK,
    input wire RST,
    // Input to Converter
    input wire input_stb,
    input wire [31:0] input_data,
    input wire is_input_operator,
    output wire input_ack,
    // Output from Calculator
    output wire result_stb,
    output wire [31:0] result_data,
    input wire result_ack
);

    // Interconnect wires
    wire conv_out_stb;
    wire [31:0] conv_out_data;
    wire conv_out_op;
    wire conv_out_ack;

    // Instantiate Converter
    converter u_converter(
        .CLK(CLK),
        .RST(RST),
        .input_stb(input_stb),
        .input_data(input_data),
        .is_input_operator(is_input_operator),
        .input_ack(input_ack),
        .output_stb(conv_out_stb),
        .output_data(conv_out_data),
        .is_output_operator(conv_out_op),
        .output_ack(conv_out_ack)
    );

    // Instantiate Calculator
    calculator u_calculator(
        .CLK(CLK),
        .RST(RST),
        .input_stb(conv_out_stb),
        .input_data(conv_out_data),
        .is_input_operator(conv_out_op),
        .input_ack(conv_out_ack),
        .output_stb(result_stb),
        .output_data(result_data),
        .output_ack(result_ack)
    );

endmodule
