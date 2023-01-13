`timescale 1ns / 1ps

module I2C_S (
    input  SCL,
    input  SDA,
    input  EN_FSM, //查看狀態機 OR 收到燈號
    output [7:0] data_out, //暫時代表狀態機
//    input  wire [7:0] data_in,
    input  push_ack,  //指撥開關
    output ack,
//    input  rw,         //Write=0，Read=1，自己決定(用指撥開關，暫時無用)
    input  rst_top
);

reg ack_reg;
reg [7:0] data_reg;
reg [3:0] state;
reg [7:0] data_out_reg;
wire rst;
//reg Din,Dout;

assign rst = ~ rst_top;
assign ack = ack_reg;
assign data_out = data_out_reg;
//assign data_out=EN_FSM? data_reg:state; //(暫時)

always @(state or data_reg or EN_FSM)begin
		case(EN_FSM)
			1'b0 : data_out_reg = data_reg;
			1'b1 : data_out_reg = {3'b000,state};
			default : data_out_reg = data_reg;
		endcase
end 


always @ (negedge SCL or negedge rst) begin
    if(~rst) begin
        state <= 3'b000;
        data_reg <= 8'b0000_0000;
        ack_reg <= 0;
    end
    else begin
    case (state)
        3'b000: begin
            state <= 3'b001;
        end
        3'b001: begin
            state <= 3'b010;
        end
        3'b010: begin
            data_reg[0] <= SDA;
            state <= 3'b011;
        end
        3'b011: begin
            data_reg[1] <= SDA;
            state <= 3'b100;
        end
        3'b100: begin
            data_reg[2] <= SDA;
            state <= 3'b101;
        end
        3'b101: begin
            data_reg[3] <= SDA;
            state <= 3'b110;
        end
        3'b110: begin
            data_reg[4] <= SDA;
            state <= 3'b111;
        end
        3'b111: begin
            data_reg[5] <= SDA;
            state <= 4'b1000;
        end
        4'b1000: begin
            data_reg[6] <= SDA;
            state <= 4'b1001;
        end
        4'b1001: begin
            data_reg[7] <= SDA;
            state <= 4'b1010;
            if (push_ack) ack_reg <= 1; //想停下來
        end
        4'b1010: begin            
            if (push_ack) begin //想停下來
                state <= 3'b000;
                ack_reg <= 1;
            end
            else begin
                state <= 3'b001;
                ack_reg <= 0;
            end
        end
    endcase
    end
end

endmodule