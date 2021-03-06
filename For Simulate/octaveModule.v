`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:40:12 04/01/2015 
// Design Name: 
// Module Name:    octaveModule 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module octaveModule
#(parameter
downS=0,
dataW=8,
outoutW=dataW,
frameW=640
)
(
input clk,en,
input [dataW-1:0]dataIn,

input [10-1:0]X,
input [10-1:0]Y,
output [dataW*GausTableN-1:0]dataOut
);



parameter windowSize=19;
parameter windowDataW=6;

parameter sigmaInit=1.6;//1.26
parameter sigmaInc=1.414;//1.26
parameter windowRadi=windowSize/2;

wire [32*windowSize-1:0]WinX;
parameter GausTableN=5;


wire [windowSize*windowDataW-1:0]GaussT[0:GausTableN-1];


assign GaussT[0]={6'd0,6'd0,6'd0,6'd0,6'd0,6'd3,6'd11,6'd29,6'd52,6'd63,6'd52,6'd29,6'd11,6'd3,6'd0,6'd0,6'd0,6'd0,6'd0};
assign GaussT[1]={6'd0,6'd0,6'd0,6'd1,6'd4,6'd9,6'd19,6'd30,6'd41,6'd45,6'd41,6'd30,6'd19,6'd9,6'd4,6'd1,6'd0,6'd0,6'd0};
/*
assign GaussT[2]={6'd1,6'd1,6'd3,6'd5,6'd9,6'd15,6'd21,6'd26,6'd30,6'd31,6'd30,6'd26,6'd21,6'd15,6'd9,6'd5,6'd3,6'd1,6'd1};
assign GaussT[3]={6'd3,6'd5,6'd7,6'd10,6'd13,6'd16,6'd19,6'd21,6'd23,6'd23,6'd23,6'd21,6'd19,6'd16,6'd13,6'd10,6'd7,6'd5,6'd3};
assign GaussT[4]={6'd7,6'd8,6'd10,6'd12,6'd14,6'd15,6'd17,6'd18,6'd18,6'd18,6'd18,6'd18,6'd17,6'd15,6'd14,6'd12,6'd10,6'd8,6'd7};*/

//for even smaller resorce usage we use 5 bits to cotain the gaussian coeff
assign GaussT[2]={5'd1,5'd1,5'd3,5'd5,5'd9,5'd15,5'd21,5'd26,5'd30,5'd31,5'd30,5'd26,5'd21,5'd15,5'd9,5'd5,5'd3,5'd1,5'd1};
assign GaussT[3]={5'd3,5'd5,5'd7,5'd10,5'd13,5'd16,5'd19,5'd21,5'd23,5'd23,5'd23,5'd21,5'd19,5'd16,5'd13,5'd10,5'd7,5'd5,5'd3};
assign GaussT[4]={5'd7,5'd8,5'd10,5'd12,5'd14,5'd15,5'd17,5'd18,5'd18,5'd18,5'd18,5'd18,5'd17,5'd15,5'd14,5'd12,5'd10,5'd8,5'd7};

	//^^^^^^^  change downS to get different down sample
	//(0:original, 1:down by 2 ,2:down by 4 .... )
	parameter downSBufferL=(frameW/(2**downS));
	wire ys=(downS==0)?1:(Y[0+:(downS==0)?1:downS]==0);
	wire xs=(downS==0)?1:(X[0+:(downS==0)?1:downS]==0);
	//
	wire en_op=ys&xs&en;




	ScanLWindow_blkRAM #(.block_height(windowSize),.block_width(1),.frame_width(downSBufferL)) win1(clk,en_op,dataIn,WinX);
	 //vertical sliding window extracter
	 //19X1 window
	
	
	wire [windowSize*dataW-1:0]W1;
	

	groupArrReOrderBABA2BBAA#(
	.Arr1EleW(dataW),.Arr2EleW(32-dataW),.Arr3EleW(0),.Arr4EleW(0),
	.ArrL(windowSize))gARO(WinX,W1);
	//the ScanLWindow_blkRAM uses 

	wire [dataW*GausTableN-1:0]FilterOutData;
	genvar gi;
	generate
		 for(gi=0;gi<2;gi=gi+1)//6bit table
		 begin:FilterL6b

			  wire [dataW-1:0]MAC_Ver_rounded;
			  
			  MFP_MAC_symmetric_par #(.In1W(dataW),.In2W(windowDataW),.In2EQW(dataW),
			  .ArrL(windowSize),.PordW_ROUND(dataW+2),.AccW_ROUND(dataW),
			  .pipeInterval(2),.isFloor(0),.isUnsigned(1))
			  MACpV(clk,en_op,W1,GaussT[gi],MAC_Ver_rounded);
			  

			  reg [dataW*windowSize-1:0]HerizontalBuff;
			  always@(posedge clk)if(en_op)HerizontalBuff<={HerizontalBuff,MAC_Ver_rounded};
					

			  MFP_MAC_symmetric_par #(.In1W(dataW),.In2W(windowDataW),.In2EQW(dataW),
			  .ArrL(windowSize),.PordW_ROUND(dataW+2),.AccW_ROUND(dataW),
			  .pipeInterval(2),.isFloor(0),.isUnsigned(1))
			  MACpH(clk,en_op,HerizontalBuff,GaussT[gi],FilterOutData[dataW*gi+:dataW]);
		 end
		 
		for(gi=2;gi<GausTableN;gi=gi+1)//5bit table
		 begin:FilterL5b

			  wire [dataW-1:0]MAC_Ver_rounded;
			  //the In2W must be changed to 5
			  MFP_MAC_symmetric_par #(.In1W(dataW),.In2W(5),.In2EQW(dataW),
			  .ArrL(windowSize),.PordW_ROUND(dataW+2),.AccW_ROUND(dataW),
			  .pipeInterval(2),.isFloor(0),.isUnsigned(1))
			  MACpV(clk,en_op,W1,GaussT[gi],MAC_Ver_rounded);
			  

			  reg [dataW*windowSize-1:0]HerizontalBuff;
			  always@(posedge clk)if(en_op)HerizontalBuff<={HerizontalBuff,MAC_Ver_rounded};
					

			  MFP_MAC_symmetric_par #(.In1W(dataW),.In2W(5),.In2EQW(dataW),
			  .ArrL(windowSize),.PordW_ROUND(dataW+2),.AccW_ROUND(dataW),
			  .pipeInterval(2),.isFloor(0),.isUnsigned(1))
			  MACpH(clk,en_op,HerizontalBuff,GaussT[gi],FilterOutData[dataW*gi+:dataW]);
		 end
		 
		 
		 if(downS==0)MFP_RegOWire#(.dataW(dataW*GausTableN),.isWire(0)) RoW(clk,en_op,FilterOutData,dataOut);
		 else
			downSamplePixMem
			#(.downSBufferL(downSBufferL),.dataW(dataW*GausTableN)) dSMEM
			(clk, xs&en, ys&en,FilterOutData,dataOut);
	//
	
	endgenerate
	
endmodule