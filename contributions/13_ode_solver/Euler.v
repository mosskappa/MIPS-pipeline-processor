module Euler
    #(parameter ADDRESS_WIDTH=13,
                DATA_WIDTH=64,
                CUR_DATA_WIDTH=16)
    (input INT,
     input CLK,
     input RST,
     output reg DONE,
     input Interpolate_DONE,
     output reg Interpolate_Enable,
     input  [DATA_WIDTH-1:0] RAM_DATA_RD1,RAM_DATA_RD2,
     output reg [ADDRESS_WIDTH-1:0] RAM_ADD_RD1,RAM_ADD_RD2,RAM_ADD_WR,
     output reg [DATA_WIDTH-1:0] RAM_DATA_WR,
     output reg RAM_ENABLE_WR);

parameter   Start=3'b000,
            Prepare=3'b001,
            Interpolate=3'b010,
            Load1=3'b011,
            Load2=3'b100,
            Final_Calc=3'b101;

    reg  [2:0] state,next;
    reg  [ADDRESS_WIDTH-1:0] A_ADD,B_ADD,X_ADD,U_ADD,h_ADD,XNew_ADD,n_ADD,m_ADD;
    reg  [ADDRESS_WIDTH-1:0] RES1_ADD,RES2_ADD;

    reg  Back, Matrix_Multiplication1_Enable, Matrix_Multiplication2_Enable, Final_Calc_Enable;
    reg  [DATA_WIDTH-1:0] n_val, m_val, h_val;
    reg  [CUR_DATA_WIDTH-1:0] MATRIX_CNT,VECTOR_CNT,MATRIX_ADD,VECTOR_ADD,VECTOR2_ADD,Element_Result,RESULT_ADD;
    wire [CUR_DATA_WIDTH-1:0] NEW_Element_Result,NEW_MATRIX_CNT,NEW_VECTOR_CNT,NEW_MATRIX_ADD,NEW_VECTOR_ADD,NEW_VECTOR2_ADD,NEW_RESULT_ADD,Addition_Result,FINAL_RESULT;
    wire [CUR_DATA_WIDTH-1:0] Multiplication_Result,h_VECTOR_RESULT;
    reg  [1:0] counter;
    wire invalid[8:0], cout[8:0], overflow[1:0];

    always@(negedge CLK) begin
        
        if(RST) begin
            n_ADD=13'd0;
            m_ADD=13'd1;
            A_ADD=13'd7;
            B_ADD=13'd2507;
            X_ADD=13'd5207;
            U_ADD=13'd5257;
            RES1_ADD=13'd5307;
            RES2_ADD=13'd5357;
            XNew_ADD=13'd5407;
            h_ADD=13'd5457;
            counter=2'd0;
            Back=1'b0;
            state=Start;
            next=Start;
            RAM_ADD_RD1=13'd0;
            RAM_ADD_RD2=13'd0;
            RAM_ADD_WR=13'd0;
            RAM_DATA_WR=64'd0;
            RAM_ENABLE_WR=1'b0;
            Interpolate_Enable=1'b0;
            Matrix_Multiplication1_Enable=1'b0;
            Matrix_Multiplication2_Enable=1'b0;
            Final_Calc_Enable=1'b0;
            n_val={CUR_DATA_WIDTH{1'b0}};
            m_val={CUR_DATA_WIDTH{1'b0}};
            h_val={CUR_DATA_WIDTH{1'b0}};
            MATRIX_CNT={CUR_DATA_WIDTH{1'b0}};
            VECTOR_CNT={CUR_DATA_WIDTH{1'b0}};
            MATRIX_ADD={CUR_DATA_WIDTH{1'b0}};
            VECTOR_ADD={CUR_DATA_WIDTH{1'b0}};
            VECTOR2_ADD={CUR_DATA_WIDTH{1'b0}};
            Element_Result={CUR_DATA_WIDTH{1'b0}};
            RESULT_ADD={CUR_DATA_WIDTH{1'b0}};

        end
        else begin
            
                state=next;

                case(state)
                    Interpolate:    RAM_ADD_RD1=h_ADD;

                    Load1:  begin
                        VECTOR_ADD=NEW_VECTOR_ADD;
                        MATRIX_ADD=NEW_MATRIX_ADD;
                        VECTOR_CNT=NEW_VECTOR_CNT;
                        Element_Result=NEW_Element_Result;
                        RAM_ADD_RD1=MATRIX_ADD;
                        RAM_ADD_RD2=VECTOR_ADD;
                        RAM_DATA_WR=Element_Result;
                        RAM_ADD_WR=RESULT_ADD;

                        RAM_ENABLE_WR=1'b0;

                        if(VECTOR_CNT==m_val)   begin
                            RAM_ENABLE_WR=1'b1;
                            VECTOR_CNT={CUR_DATA_WIDTH{1'b0}};
                            MATRIX_CNT=NEW_MATRIX_CNT;
                            VECTOR_ADD=U_ADD;
                            RAM_ADD_RD2=VECTOR_ADD;
                            RESULT_ADD=NEW_RESULT_ADD;
                        end
                    end

                    Load2:  begin
                        VECTOR_ADD=NEW_VECTOR_ADD;
                        MATRIX_ADD=NEW_MATRIX_ADD;
                        VECTOR_CNT=NEW_VECTOR_CNT;
                        Element_Result=NEW_Element_Result;
                        RAM_ADD_RD1=MATRIX_ADD;
                        RAM_ADD_RD2=VECTOR_ADD;
                        RAM_DATA_WR=Element_Result;
                        RAM_ADD_WR=RESULT_ADD;

                        RAM_ENABLE_WR=1'b0;

                        if(VECTOR_CNT==n_val)   begin
                            RAM_ENABLE_WR=1'b1;
                            VECTOR_CNT={CUR_DATA_WIDTH{1'b0}};
                            MATRIX_CNT=NEW_MATRIX_CNT;
                            VECTOR_ADD=X_ADD;
                            RAM_ADD_RD2=VECTOR_ADD;
                            RESULT_ADD=NEW_RESULT_ADD;
                        end
                        
                    end

                    Final_Calc: begin
                        RAM_ADD_RD2=MATRIX_ADD;
                        RAM_ADD_WR=RESULT_ADD;
                        RAM_ENABLE_WR=1'b0;

                        case (counter)
                            0:  begin
                                RAM_ADD_RD1=VECTOR2_ADD;
                                VECTOR_ADD=NEW_VECTOR_ADD;
                                counter=2'b01;
                            end 

                            1:  begin
                                Element_Result=RAM_DATA_RD1;
                                RAM_ADD_RD1=VECTOR_ADD;
                                counter=2'b10;
                            end

                            2:  begin
                                RAM_ENABLE_WR=1;
                                RAM_DATA_WR=FINAL_RESULT;
                                VECTOR2_ADD=NEW_VECTOR2_ADD;
                                MATRIX_ADD=NEW_MATRIX_ADD;
                                RESULT_ADD=NEW_RESULT_ADD;
                                VECTOR_CNT=NEW_VECTOR_CNT;
                                counter=2'b00;
                            end
                            default:    counter=0;

                        endcase
                    end
                endcase


            if(~INT)    begin
                state=Start;
                Back=0;
            end
            
            case (state)
                Start:      begin
                    if(!Back)   begin
                        next=Prepare;
                        RAM_ADD_RD1=n_ADD;
                        RAM_ADD_RD2=m_ADD;
                        RAM_ENABLE_WR=1'b0;
                    end
                    else next=Start;
                end
                
                Prepare:    begin
                    next=Interpolate;
                    Back=1;
                    n_val=RAM_DATA_RD1;
                    m_val=RAM_DATA_RD2;
                end

                Interpolate:    begin
                    Interpolate_Enable=1'b1;
                    h_val=RAM_DATA_RD1;
                    if(Interpolate_DONE) begin
                        next=Load1;
                        Interpolate_Enable=1'b0;
                        Matrix_Multiplication1_Enable=1'b1;
                    end
                end
                
                Load1:  begin
                    
                    if(Matrix_Multiplication1_Enable) begin
                        Matrix_Multiplication1_Enable=1'b0;
                        VECTOR_CNT={CUR_DATA_WIDTH{1'b0}};
                        MATRIX_CNT={CUR_DATA_WIDTH{1'b0}};
                        Element_Result={CUR_DATA_WIDTH{1'b0}};
                        VECTOR_ADD=U_ADD;
                        MATRIX_ADD=B_ADD;
                        RESULT_ADD=RES1_ADD;
                        RAM_ADD_RD1=B_ADD;
                        RAM_ADD_RD2=U_ADD;
                        RAM_ADD_WR=RES1_ADD;
                    end
                    if (VECTOR_CNT==0) Element_Result={CUR_DATA_WIDTH{1'b0}};

                    if (MATRIX_CNT==n_val)  begin
                        next=Load2;
                        Matrix_Multiplication2_Enable=1'b1;
                    end
                end
                Load2:  begin
                    
                    if(Matrix_Multiplication2_Enable) begin
                        Matrix_Multiplication2_Enable=1'b0;
                        VECTOR_CNT={CUR_DATA_WIDTH{1'b0}};
                        MATRIX_CNT={CUR_DATA_WIDTH{1'b0}};
                        Element_Result={CUR_DATA_WIDTH{1'b0}};
                        VECTOR_ADD=X_ADD;
                        MATRIX_ADD=A_ADD;
                        RESULT_ADD=RES2_ADD;
                        RAM_ADD_RD1=A_ADD;
                        RAM_ADD_RD2=X_ADD;
                        RAM_ADD_WR=RES2_ADD;
                    end
                    if (VECTOR_CNT==0) Element_Result={CUR_DATA_WIDTH{1'b0}};

                    if(MATRIX_CNT==n_val)  begin
                        next=Final_Calc;
                        Final_Calc_Enable=1'b1;
                    end
                end

                Final_Calc: begin
                    if(Final_Calc_Enable)   begin
                        Final_Calc_Enable=1'b0;
                        VECTOR_CNT={CUR_DATA_WIDTH{1'b0}};
                        VECTOR_ADD=RES1_ADD;
                        MATRIX_ADD=RES2_ADD;
                        VECTOR2_ADD=X_ADD;
                        RESULT_ADD=XNew_ADD;
                        RAM_ADD_RD1=X_ADD;
                        RAM_ADD_RD2=RES2_ADD;
                        RAM_ADD_WR=XNew_ADD;
                    end

                    if(VECTOR_CNT==n_val)   next=Start;
                end
                default:    next=Start;
            endcase
        end

        
        if(INT && state==Start && Back)    DONE=1;
        else DONE=0;

    end


    multiplier_16bit MUL(RAM_DATA_RD1[CUR_DATA_WIDTH-1:0],RAM_DATA_RD2[CUR_DATA_WIDTH-1:0],Multiplication_Result,1'b1,overflow[0]);
    add_sub_cla ELEMENT_adder(1'b0,Element_Result,Multiplication_Result,1'b0,NEW_Element_Result,cout[0],invalid[0]);
    

    add_sub_cla VECTOR_ADD_adder(1'b0,VECTOR_ADD,{16{1'b0}},1'b1,NEW_VECTOR_ADD,cout[1],invalid[1]);
    add_sub_cla MATRIX_ADD_adder(1'b0,MATRIX_ADD,{16{1'b0}},1'b1,NEW_MATRIX_ADD,cout[2],invalid[2]);
    add_sub_cla VECTOR_CNT_adder(1'b0,VECTOR_CNT,{16{1'b0}},1'b1,NEW_VECTOR_CNT,cout[3],invalid[3]);
    add_sub_cla MATRIX_CNT_adder(1'b0,MATRIX_CNT,{16{1'b0}},1'b1,NEW_MATRIX_CNT,cout[4],invalid[4]);
    add_sub_cla RESULT_ADD_adder(1'b0,RESULT_ADD,{16{1'b0}},1'b1,NEW_RESULT_ADD,cout[5],invalid[5]);
    add_sub_cla VECTOR2_ADD_adder(1'b0,VECTOR2_ADD,{16{1'b0}},1'b1,NEW_VECTOR2_ADD,cout[6],invalid[6]);


    add_sub_cla VEC1_VEC2_adder(1'b0,RAM_DATA_RD1[CUR_DATA_WIDTH-1:0],RAM_DATA_RD2[CUR_DATA_WIDTH-1:0],1'b0,Addition_Result,cout[7],invalid[7]);

    multiplier_16bit h_MUL(Addition_Result,h_val[CUR_DATA_WIDTH-1:0],h_VECTOR_RESULT,1'b1,overflow[1]);

    add_sub_cla FINAL_RESULT_adder(1'b0,h_VECTOR_RESULT,Element_Result,1'b0,FINAL_RESULT,cout[8],invalid[8]);

endmodule