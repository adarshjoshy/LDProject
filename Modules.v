module Mux2x1(out,in1,in2,s) ;

output reg [1:0] out ;
input [1:0] in1,in2 ;
input s ;

always@(in1,in2,s)
begin 
	if(s == 0) 
		out = in1 ;
	else if(s == 1) 
		out = in2 ;
	else 
		out = 2'bxx ;
end

endmodule 

module Or(out,a,b) ;

output out ;
input a,b ;

or(out,a,b) ;

endmodule 

module PEncoder(out,used,in1,in2,in3,in4) ;

output reg [1:0] out ;
output reg used ;
input in1 ,in2 ,in3 ,in4 ;

always @(in1,in2,in3,in4)
begin
	if({in1,in2,in3,in4} != 0) 
		used = 1 ; 
	if (in1== 1)
		out = 0 ;
	else if(in2 == 1) 
		out = 1 ;
	else if(in3 == 1)
		out = 2 ;
	else if(in4 == 1)
		out = 3 ;
	else 
		out = 2'bxx ;
end

endmodule

module Decoder(o1,o2,o3,o4,in) ;

output reg o1,o2,o3,o4 ;
input [1:0] in ;

always @(in)
begin
	if(in == 0)
	begin 
		o1 = 1 ;
		o2 = 0 ;
		o3 = 0 ;
		o4 = 0 ;
	end 
	if(in == 1)
	begin 
		o1 = 0 ;
		o2 = 1 ;
		o3 = 0 ;
		o4 = 0 ;
	end 
	if(in == 2)
	begin 
		o1 = 0 ;
		o2 = 0 ;
		o3 = 1 ;
		o4 = 0 ;
	end 
	if(in == 3)
	begin 
		o1 = 0 ;
		o2 = 0 ;
		o3 = 0 ;
		o4 = 1 ;
	end 
end

endmodule

module TimerIC(clk,reset,mode,BoardSelect) ;

output reg [1:0] BoardSelect ;
output reg mode ;
input clk ;
input reset ;
reg [5:0] TClock ;

initial 
begin
	mode = 0 ;
	BoardSelect = 0 ;
end

always @(posedge clk) 
begin 
	if(reset)
		TClock = 0 ;
	TClock = TClock + 1 ;
	if(TClock%16==15)
		mode =~ mode ;
	if(TClock%32==31)
		BoardSelect = BoardSelect + 1 ;
end
endmodule

module LightBoard(enable,mode,mode_out,out) ;

output reg mode_out ;
output reg [4:0] out ;
input enable ;
input mode ;

reg [4:0] prevout ;

always@(mode) 
begin
	mode_out = mode ;
	if(enable == 1 )
	begin
		prevout = out ; 
		if(mode==1)
			out = 5'b00110 ; 
		else 
			out = 5'b00111 ;
		# 12 ; 
		out = 5'b01100 ;  // Red Orange LeftGreen FrontGreen RightGreen
	end
	else 
		out = 5'b10100 ;
end

endmodule

module TrafficSignal(clk,imgDataOut,imgData,active,p,e) ;

output reg [1023:0] imgDataOut ;
output reg active ;
input clk ;
input [1023:0] imgData ;
input [3:0] p ,e ;
wire [1:0] BoardSelect,lo,lout,eo,eout ;
wire [3:0] o,S,mode_out ;
wire [4:0] out [3:0] ;
wire mode ;
wire reset ;

TimerIC T(clk,reset,mode,BoardSelect) ; 

PEncoder Load(lo,priority,p[0],p[1],p[2],p[3]) ;      // Mux out , in1 , in2 , s
Mux2x1 Lm(lout,BoardSelect,lo,priority) ;

PEncoder Emer(eo,emergency,e[0],e[1],e[2],e[3]) ;     // out , use , in1 , in2 ,in3 , in4  
Mux2x1 Em(eout,lout,eo,emergency) ;

Decoder D_(o[0],o[1],o[2],o[3],eout) ; 			// out1 , out2 , out3 , out4 , input 

Or o1(S[0],o[0],mode_out[2]) ;   				// out , in1 , in2 
Or o2(S[1],o[1],mode_out[3]) ; 
Or o3(S[2],o[2],mode_out[0]) ;
Or o4(S[3],o[3],mode_out[1]) ;

LightBoard D(S[0],mode,mode_out[0],out[0]) ; 		// enable , mode , mode_out , out 
LightBoard U(S[1],mode,mode_out[1],out[1]) ; 
LightBoard L(S[2],mode,mode_out[2],out[2]) ; 
LightBoard R(S[3],mode,mode_out[3],out[3]) ; 

initial
begin
	active = 0 ;
end

always@(imgData)
begin
	imgDataOut = imgData ;
	active = 1 ; #1 ;
	active = 0 ; 
end

endmodule 

module TrafficSystem(clk,imgDataIn1 ,imgDataIn2 ,imgDataIn3 ,imgDataIn4 ,imgDataIn5,signal,ans) ;

input clk ;
input [1023:0] imgDataIn1 ,imgDataIn2 ,imgDataIn3 ,imgDataIn4 ,imgDataIn5   ;
input [4:0] signal ;
output reg [4:0] ans ;
reg [1023:0] imgData ;

integer Fin ;
integer Fin_ ;
integer i ;
integer j ;
integer max ;
integer maxi ;
integer board ;

reg [4:0] RAM [4:0][1023:0] ;

reg [11:0] similar [260:0] ;
reg [1023:0] Sample [260:0] ;

initial 
begin 
	Fin = $fopen("Samples/pixelArrayInputFile.txt","r") ;
	if (Fin==0)
	begin
    		$display("data_file handle was NULL");
    		$finish;
	end
	for(i=0;i<260;i=i+1)
	begin 
		Fin_ = $fscanf(Fin,"%b",Sample[i]) ;
	end
end

always@(imgDataIn1 ,imgDataIn2 ,imgDataIn3 ,imgDataIn4 ,imgDataIn5) 
begin 
	if(signal==5'b10000)
	begin
		board = 4 ;
		imgData = imgDataIn5 ;
	end
	if(signal==5'b01000)
	begin
		board = 3 ;
		imgData = imgDataIn4 ;
	end
	if(signal==5'b00100)
	begin
		board = 2 ;
		imgData = imgDataIn3 ;
	end
	if(signal==5'b00010)
	begin
		board = 1 ;
		imgData = imgDataIn2 ;
	end
	if(signal==5'b00001)
	begin
		board = 0 ;
		imgData = imgDataIn1 ;
	end
end

always@(imgData)
begin
	for(i=0;i<260;i=i+1)
		similar[i] = 0 ;
	for(i=0;i<260;i=i+1)
		for(j=0;j<1024;j=j+1)
		begin
			if(Sample[i][j] == imgData[j])
				similar[i] = similar[i] + 1 ;
		end
	max = 0 ;
	maxi = 0 ;
	for(i=0;i<260;i=i+1)
		if(similar[i]>max)
		begin 
			max = similar[i] ;
			maxi = i ;
		end
	ans = maxi/10 + 1 ;
	RAM[board][0] = ans ;
end

endmodule 