`timescale 1ns / 1ps

module i2c_slave (
    input  wire scl,
    input      sda,
    output reg [7:0] data_out,
    input  wire [7:0] data_in,
    input  wire start,
    input  wire stop,
    input  wire read,
    input  wire write,
    input rst
);

reg [7:0] data_reg;
reg [2:0] state;
reg Din,Dout;
reg en;


assign sda=en? Dout:1'bz; //1¡GDout¡A0¡GDin¡A«eif «áelse
always@(posedge scl or negedge rst) begin 
    if (rst)
        Din<= 1'b0;
    else if(!en)
        Din <= sda;
end


always @ (posedge scl or negedge rst) begin
    if(~rst) state <= 3'b000;
    else begin
    case (state)
        3'b000: begin
            if (start) begin
                state <= 3'b001;
                data_reg <= 8'b00000000;
            end
        end
        3'b001: begin
            if (sda == 1'b0) begin
                state <= 3'b010;
            end
        end
        3'b010: begin
            data_reg <= {data_reg[6:0], sda};
            state <= 3'b011;
        end
        3'b011: begin
            data_reg <= {data_reg[6:0], sda};
            state <= 3'b100;
        end
        3'b100: begin
            data_reg <= {data_reg[6:0], sda};
            state <= 3'b101;
        end
        3'b101: begin
            data_reg <= {data_reg[6:0], sda};
            state <= 3'b110;
        end
        3'b110: begin
            data_reg <= {data_reg[6:0], sda};
            state <= 3'b111;
        end
        3'b111: begin
            data_reg <= {data_reg[6:0], sda};
            state <= 4'b1000;
        end
        4'b1000: begin
            data_reg <= {data_reg[6:0], sda};
            state <= 4'b1001;
        end
        4'b1001: begin
            if (read) begin
                data_out <= data_reg;
            end
            if (stop) begin
                state <= 3'b000;
            end
            else begin
                state <= 3'b001;
            end
        end
    endcase
    end
end

endmodule