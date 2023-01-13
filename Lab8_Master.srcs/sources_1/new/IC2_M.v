`timescale 1ns / 1ps

module Lab8_Master_Top(
    output  SCL, //���VCLK�u�A��V�iinput
    output  SDA, //inout�A���V��ƽu
    output  [7:0] data_out,  //��slave�Ǧ^���ƾڡA��ܦbLED(�ȮɥN���A��)
//    input   wire [7:0] data_in,  //��slave�ƾ�
    input   EN_FSM, //�d�ݪ��A�� OR ����O��
    input   [6:0] addr_in,  //���wLED(�Ϋ����}��)�A��Slave�G�A7+1    
//    input   rw,         //Write=0�ARead=1�A�ۤv�M�w(�Ϋ���)
    input   en,         //�M�w�ʧ@�A���U�}�lWrite(Dout)�A����Din
    input   ack,        //�ȩw��ʿ�J�B�~�Խu
    input   clk,
    input   rst 
    );
    
wire div_clk,div_clk_fast,div_clk_btn,de_R;

de_jump de_right(.Din(~en),.Dout(de_R),.clk(div_clk_btn),.reset(~rst));  //���s���u��
div div_go(.div_clk(div_clk),.div_clk_fast(div_clk_fast),.div_clk_btn(div_clk_btn),.clk(clk),.rst(~rst));  //���W[0]�B[1]�B[5]

IC2_M IC2_M1(.SCL(SCL),.SDA(SDA),.data_out(data_out),.EN_FSM(EN_FSM),.addr_in({1'b0,addr_in}),.rw(1'b0),
              .en(de_R),.ack(ack),.div_clk_fast(div_clk_fast),.div_clk(div_clk),.rst(~rst) );

endmodule

module div(div_clk,div_clk_fast,div_clk_btn,clk,rst); // divclk_2 ��23�@��

output div_clk,div_clk_fast,div_clk_btn;
input clk,rst;
reg [28:0]divclkcnt;

assign div_clk_btn  = divclkcnt[13]; //���s���u��
assign div_clk_fast = divclkcnt[21]; 
assign div_clk      = divclkcnt[26]; 


always@(posedge clk or negedge rst)begin
    if(~rst)
        divclkcnt = 0;
    else
        divclkcnt = divclkcnt + 1;
end

endmodule

module de_jump(Din,Dout,clk,reset);
input Din,clk,reset;
output Dout;

reg Dout;
reg [3:0] as,cs;

always @(*)begin
	case(cs)
	4'd0:
		as<=(Din)? 4'd0:4'd1;
	4'd1:
		as<=(Din)? 4'd0:4'd2;
	4'd2:
		as<=(Din)? 4'd0:4'd3;
	4'd3:
		as<=(Din)? 4'd0:4'd4;
	4'd4: //���ɡA0-4���U�A4-8��}
		as<=(Din)? 4'd5:4'd4;
	4'd5:
		as<=(Din)? 4'd6:4'd4;
	4'd6:
		as<=(Din)? 4'd7:4'd4;
	4'd7:
		as<=(Din)? 4'd8:4'd4;
	4'd8:
		as<=(Din)? 4'd0:4'd4;
	default:
		as<=4'd0;
	endcase
end

always@(posedge clk or negedge reset)
	if(!reset)
		cs <= 4'd0;
	else
		cs <=as;
	
always@(*)begin
	case(cs)
	4'd0:
		Dout<=1'b0;
	4'd1:
		Dout<=1'b0;
	4'd2:
		Dout<=1'b0;
	4'd3:
		Dout<=1'b0;
	4'd4: //����
		Dout<=1'b1;
	4'd5:
		Dout<=1'b1;
	4'd6:
		Dout<=1'b1;
	4'd7:
		Dout<=1'b1;
	4'd8:
		Dout<=1'b1;
	default:
		Dout<=1'b0;
	endcase
end

endmodule

module IC2_M(
    output  SCL, //���VCLK�u�A��V�iinput
    output  SDA, //inout�A���V��ƽu
    output  [7:0] data_out,  //��slave�Ǧ^���ƾڡA��ܦbLED(�ȮɥN���A��)
//    input   wire [7:0] data_in,  //��slave�ƾ�
    input   EN_FSM, //�d�ݪ��A�� OR ����O��
    input   [7:0] addr_in,  //���wLED(�Ϋ����}��)�A��Slave�G    
    input   rw,         //Write=0�ARead=1�A�ۤv�M�w(�Ϋ���)
    input   en,         //�M�w�ʧ@�A���U�}�lWrite(Dout)�A����Din
    input   ack,
    input   div_clk_fast,
    input   div_clk,
    input   rst    
);

reg [3:0] state;
reg [7:0] data_reg;
reg [3:0] cnt_data;
reg start,stop; //Stop=> start =0
reg sda_out;
reg SCL_reg;
reg [7:0] data_out_reg;

//assign data_out = EN_FSM? data_reg : {3'b000,state}; //(�Ȯ�)
assign data_out = data_out_reg;
assign SDA = sda_out;
assign SCL = SCL_reg;

always @(state or data_reg or EN_FSM)begin
		case(EN_FSM)
			1'b0 : data_out_reg = data_reg;
			1'b1 : data_out_reg = {3'b000,state};
			default : data_out_reg = data_reg;
		endcase
end  



always@(posedge div_clk or negedge rst) begin
    if(~rst) begin
        start   <= 0;
    end
    else if(en) start <= 1;
    else if(stop) start <= 0; //stop=1���U
end

always@(posedge div_clk_fast or negedge rst) begin
    if(~rst)        
        SCL_reg <= 1'b1;
    else if(start==1) 
        SCL_reg <= div_clk;
    else
        SCL_reg <= 1'b1;
end

always@(negedge SCL_reg or negedge rst) begin
    if(~rst) begin
        sda_out <= 1'b1;
        state <= 3'b000;
        data_reg <= 8'b0000_0000;
        stop <= 0;
    end
    else begin
         case (state)
            3'b000: begin
                state <= 3'b001;   
                data_reg <= addr_in;
                stop <= 0;                 
            end
            3'b001: begin
                state <= 3'b010;
                data_reg <= addr_in; 
                stop <= 0;
            end
            3'b010: begin
                sda_out <= data_reg[0];
                state <= 3'b011;        
            end 
            3'b011: begin
                sda_out <= data_reg[1];
                state <= 3'b100;                
            end           
            3'b100: begin
                sda_out <= data_reg[2];
                state <= 3'b101;                
            end   
            3'b101: begin
                sda_out <= data_reg[3];
                state <= 3'b110;        
            end 
            3'b110: begin
                sda_out <= data_reg[4];
                state <= 3'b111;                
            end           
            3'b111: begin
                sda_out <= data_reg[5];
                state <= 4'b1000;                
            end
            4'b1000: begin
                sda_out <= data_reg[6];
                state <= 4'b1001;
            end
            4'b1001: begin //�ȩwWrite�A��8��bit
                sda_out <= rw;
                state <= 4'b1010;
            end
            4'b1010: begin
                if(ack==0) state <= 3'b001;
                else begin //ack==1
                    state <= 3'b000;
                    stop <= 1;
                end                
            end  
             
        endcase
    end
end   
    
    
    
endmodule
