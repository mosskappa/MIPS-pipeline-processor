module System #(parameter   DATA_WIDTH=64,
                            ADDRESS_WIDTH=13)
(   input INT,
    input CLK,
    input RST,
    output DONE,
    input Interpolate_DONE,
    output Interpolate_Enable);

    wire [ADDRESS_WIDTH-1:0]    RAM_ADD_RD1,RAM_ADD_RD2,RAM_ADD_WR;
    wire [DATA_WIDTH-1:0]   RAM_DATA_RD1,RAM_DATA_RD2,RAM_DATA_WR;
    wire RAM_ENABLE_WR;


    RAM #(ADDRESS_WIDTH,DATA_WIDTH,2**ADDRESS_WIDTH) Memory(CLK,1'b0,RAM_ENABLE_WR,RAM_ADD_RD1,RAM_ADD_RD2,RAM_ADD_WR,
    RAM_DATA_RD1,RAM_DATA_RD2,RAM_DATA_WR);

    Euler Main(INT,CLK,RST,DONE,Interpolate_DONE,Interpolate_Enable,
                RAM_DATA_RD1,RAM_DATA_RD2,RAM_ADD_RD1,RAM_ADD_RD2,RAM_ADD_WR,RAM_DATA_WR,RAM_ENABLE_WR);

endmodule