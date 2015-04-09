`timescale 1ns / 1ps

`define MVAL_W(MAXVALUE) ($clog2(MAXVALUE)+(((2**$clog2(MAXVALUE))==MAXVALUE)?0:1))
module hijacker
#(parameter
CameraDataDepth=16,//Data from camera
//Set the width parameter for window extraction module
ImageW=640,
ImageH=480,

dispLevel=32, //32
DataDepth=16,
SGMDataDepth=6
)
(
	 input fclk,
	 input clk1,
	 input clk2,
	 
	 input CamADV,
	 input FbWrARst,
	 input CamBDV,
	 input FbWrBRst,
	 
	  
    input [CameraDataDepth-1:0] DI1,
    input [CameraDataDepth-1:0] DI2,
    input [CameraDataDepth-1:0] DIx,
    output [CameraDataDepth-1:0] DO1,
    output [CameraDataDepth-1:0] DO2,
	 output [7:0]LED_O,
	 input [7:0]SW_I,
	 output [7:0]IO_O,
	 
	 
	 input sck,input css,input mosi,inout miso,
	 output spi_DatRdy,output spi_ScreenRst
    );
	 wire miso_;
	 
	 reg misoGate;
	wire mosi;
	 assign miso = (misoGate) ? miso_ : 1'bz;
	 
	 wire clk_p=clk2;
	 always@(posedge clk_p)misoGate<=css;
	 
	 
	reg [8-1:0]SaData[7:0];
	 
	
	wire [8-1:0]dat_i;
	wire [8-1:0]ndat_i;
	wire spi_rdy;
	wire spi_prerdy;
	
	wire sck_posedge;
	reg [8-1:0]feedData;
	

	
	
	SPI_slave SPI_S1(clk_p,sck,css, mosi,miso_,
	feedData,dat_i,ndat_i,sck_posedge,accep_dat_o,spi_rdy,spi_prerdy
	);
	
	reg[8*6-1:0]dataG;
	wire SPIByteRdy=sck_posedge&spi_prerdy;
	
	reg enD;
	always@(posedge clk_p)begin//sec for data shift counter 1, 2, 4 
		enD<=SPIByteRdy&Pix_C[5];
	end
	
	
	wire en_p=(SaData[2]==0)?CamBDV:enD;//enD;
	assign spi_DatRdy=en_p;
	wire rst_p=(SaData[2]==0)?FbWrBRst:spi_ScreenRst;
	
	
	always@(posedge clk_p)begin//sec for data shift counter 1, 2, 4 
		if(SPIByteRdy)dataG<={dataG,ndat_i};
	end
	
	reg [2:0]SPI_C;
	always@(posedge clk_p,negedge css)begin//sec for data shift counter 1, 2, 4 
		if(~css)SPI_C<=1;
		else if(SPIByteRdy)SPI_C<={SPI_C,SPI_C[2]};
	end
	
   reg [5:0]Pix_C;
	always@(posedge clk_p,negedge KGate)begin//sec for data shift counter 1, 2, 4 
		if(~KGate)Pix_C<=1;
		else if(SPIByteRdy)Pix_C<={Pix_C,Pix_C[5]};
	end
	
	reg [8*6-1:0]dat_PixK;
	always@(posedge clk_p)begin//sec for data shift counter 1, 2, 4 
		if(SPIByteRdy&Pix_C[5])dat_PixK<={dataG,ndat_i};
	end
	
	/*
	wire clk_p=clk1;
	wire en_p=CamADV;
	wire rst_p=FbWrARst;*/
	
	always@(posedge clk_p,negedge css)begin
		if(~css) KGate=0;
		else if(SPIByteRdy)begin//new spi data byte comes in
			if(KGate)begin
				feedData=spiRet;
			end
			else begin
				feedData=8'hff;
				
				if(SPI_C[1])begin//receive 2 datas 1st data=dat_Pix[0+:8],2nd data=preData , usually for return data 
					if(dataG[0+:8]==16'h81)
						feedData=SaData[ndat_i];
				end
				else if(SPI_C[2])begin//receive 3 datas 1st data=dat_Pix[8+:8],2nd data=dat_Pix[0+:8] 3rd data at , usually for accept data 
					case(dataG[8+:8])
					8'h80:
						SaData[dataG[0+:8]]=ndat_i;
					8'h55:
						KGate=1;
					8'h40:
						spi_ScreenRst=0;
					8'h41:
						spi_ScreenRst=1;
					default:
						KGate=0;
					endcase
				
				end
			end
		end
	end
	
	
	assign LED_O={Pix_C,KGate,spi_ScreenRst};
	
	
	reg KGate,spi_ScreenRst;
	
	
	
	wire [10:0]pixX;
	wire [10:0]pixY;
	reg [8:0]spiRet;//=MinDataIdx;
	


	wire [DataDepth-1:0]ColorMean1=DI1[11+:5]+DI1[0+:5]+DI1[5+:6];//(DI1[11+:5]+DI1[0+:5]*2+DI1[5+:6]*2);
	wire [DataDepth-1:0]ColorMean2=DI2[11+:5]+DI2[0+:5]+DI2[5+:6];//(DI2[11+:5]+DI2[0+:5]*2+DI2[5+:6]*2);
	
	wire [DataDepth-1:0]DI2r=(SaData[2]==0)?ColorMean2:{dat_PixK[24+23-:5],dat_PixK[24+15-:6],dat_PixK[24+7-:8]};//giv full bit of blue
	
	wire [DataDepth-1:0]DI1r=(SaData[2]==0)?ColorMean1:{dat_PixK[23-:5],dat_PixK[15-:6],dat_PixK[7-:8]};//may kick off red
	parameter GausTableN=5;
	localparam dataW=8;//unsigned data
	localparam sidataW=dataW+1;
	wire signed[sidataW-1:0]DoGOut[0:GausTableN-1-1];
	wire signed[sidataW-1:0]DoGOut2[0:GausTableN-1-1];
	
	always@(*)
	begin
		case(SaData[0])
		 0:spiRet<=DoGOut[0];
		 1:spiRet<=DoGOut[1];
		 2:spiRet<=DoGOut[2];
		 3:spiRet<=DoGOut[3];
		
		 4:spiRet<=DoGOut2[0];
		 5:spiRet<=DoGOut2[1];
		 6:spiRet<=DoGOut2[2];
		 7:spiRet<=DoGOut2[3];
		 
		// 3:spiRet<=DIxL;
		 //4:spiRet<=(DIxL==0)?0:255;
		 8:spiRet<=(pixX>pixY)?pixX:pixY;
		// 9:spiRet<=dat_PixK[40+:8];
		 default:spiRet<=0;
		 endcase
	
	end
	
	wire[8-1:0]OR,OG,OB;
	ColorTranse(spiRet,OR,OG,OB);
	assign DO2=(SW_I[7])?{OR[7-:5],OG[7-:6],OB[7-:5]}:DI2;//(pixX[0])?DIxL:DIxR;
	assign DO1=(SW_I[7])?((pixY[3])?DI1:DI2):DI1;
	//assign DO1={ColorMean2[6-:5],ColorMean1[6-:6],ColorMean2[6-:5]};//(pixX[0])?DIxL:DIxR;
	
	//assign IO_O[7:4]={KGate,spi_DatRdy,css&sck,spi_prerdy};
	PixCoordinator # (.frameW(ImageW),.frameH(ImageH)) 
	Pc1(clk_p,en_p,rst_p,pixX,pixY);
	
	/*
	wire [GausTableN*dataW-1:0]Gaussian1;//unsigned
	wire [GausTableN*dataW-1:0]Gaussian2;
	
	
	octaveModule#(.frameW(ImageW)) 
	OM1(clk_p,en_p,DI1r[0+:8],pixX,pixY,Gaussian1);
	
	
	octaveModule#(.frameW(ImageW),.downS(2)) 
	OM2(clk_p,en_p,DI1r[0+:8],pixX,pixY,Gaussian2);

	generate
		genvar gi;
		 for(gi=0;gi<GausTableN-1;gi=gi+1)
		 begin:FilterL
			wire signed[sidataW-1:0] GaussianA=Gaussian1[gi*dataW+:dataW];
			wire signed[sidataW-1:0] GaussianB=Gaussian1[(gi+1)*dataW+:dataW];
			assign DoGOut[gi]=128+GaussianA-GaussianB;
			
			wire signed[sidataW-1:0] GaussianA2=Gaussian2[gi*dataW+:dataW];
			wire signed[sidataW-1:0] GaussianB2=Gaussian2[(gi+1)*dataW+:dataW];
			assign DoGOut2[gi]=128+GaussianA2-GaussianB2;
			
		 end
	endgenerate	
	*/
	
	

	
		genvar gi;
	
wire [32*3*3-1:0]WinX;
wire [dataW*3*3-1:0]Buff3x3;


ScanLWindow_blkRAM #(.block_height(3),.block_width(3),.frame_width(ImageW)) win1(clk_p,en_p,DI1r[0+:8],WinX);

	

	groupArrReOrderBABA2BBAA#(
	.Arr1EleW(dataW),.Arr2EleW(32-dataW),.Arr3EleW(0),.Arr4EleW(0),
	.ArrL(3*3))gARO(WinX,Buff3x3);
	
	

parameter FilterOutW=dataW;

wire  [dataW+1-1:0]DH1=(Buff3x3[0*dataW+:dataW]+Buff3x3[1*dataW+:dataW]*2+Buff3x3[2*dataW+:dataW])/2;
wire  [dataW+1-1:0]DH2=(Buff3x3[6*dataW+:dataW]+Buff3x3[7*dataW+:dataW]*2+Buff3x3[8*dataW+:dataW])/2;
wire  [dataW+1-1:0]DV1=(Buff3x3[0*dataW+:dataW]+Buff3x3[3*dataW+:dataW]*2+Buff3x3[6*dataW+:dataW])/2;
wire  [dataW+1-1:0]DV2=(Buff3x3[2*dataW+:dataW]+Buff3x3[5*dataW+:dataW]*2+Buff3x3[8*dataW+:dataW])/2;

wire signed[dataW+2-1:0]SobelXY_[0:2-1];
assign SobelXY_[0]=(DV1-DV2);
assign SobelXY_[1]=(DH1-DH2);


wire signed[dataW-1:0]SobelXY[0:2-1];
parameter satbits=1;
MFP_Saturate#(.InW(dataW+2),.Sat2W(dataW-satbits),.OutW(dataW),.isUnsigned(0)) 
sobelXsat(SobelXY_[0],SobelXY[0]);

MFP_Saturate#(.InW(dataW+2),.Sat2W(dataW-satbits),.OutW(dataW),.isUnsigned(0)) 
sobelYsat(SobelXY_[1],SobelXY[1]);

parameter corWinDataW=2*dataW;
parameter cornorwindowSize=5;
parameter cornorwindowDim=cornorwindowSize*cornorwindowSize;


	
wire [32*cornorwindowDim-1:0]WinX_cornor;
wire [corWinDataW*cornorwindowDim-1:0]corWin;

	 
ScanLWindow_blkRAM #(.block_height(cornorwindowSize),.block_width(cornorwindowSize),
.frame_width(ImageW)) cornorWindow(clk_p,en_p,{SobelXY[0],SobelXY[1]},WinX_cornor);


groupArrReOrderBABA2BBAA#(
.Arr1EleW(corWinDataW),.Arr2EleW(32-corWinDataW),.Arr3EleW(0),.Arr4EleW(0),
.ArrL(cornorwindowDim))gARO_cornerWin(WinX_cornor,corWin);

 
parameter abcCoeffW=dataW+$clog2(cornorwindowDim)+1+1;
wire [abcCoeffW*cornorwindowDim-1:0]aij_arr;
wire [abcCoeffW*cornorwindowDim-1:0]cij_arr;
wire [abcCoeffW*cornorwindowDim-1:0]bij_arr;

generate
	for(gi=0;gi<cornorwindowDim;gi=gi+1)begin:addL
			wire signed[dataW-satbits-1:0]Ix,Iy;
			assign Ix=corWin[gi*corWinDataW+:dataW-satbits];
			assign Iy=corWin[gi*corWinDataW+dataW+:dataW-satbits];
			
			
			wire [dataW-1:0]IxIx;//signed
			MFP_Multi #(.In1W(dataW-satbits),.OutW(dataW),.isUnsigned(0)) 
			m_a(Ix,Ix,IxIx);
			wire [dataW-1:0]IyIy;
			MFP_Multi #(.In1W(dataW-satbits),.OutW(dataW),.isUnsigned(0)) 
			m_c(Iy,Iy,IyIy);
			wire signed[dataW-1:0]IxIy;
			MFP_Multi #(.In1W(dataW-satbits),.OutW(dataW),.isUnsigned(0)) 
			m_b(Iy,Ix,IxIy);
			
			assign aij_arr[gi*(abcCoeffW)+:abcCoeffW]=IxIx;
			assign cij_arr[gi*(abcCoeffW)+:abcCoeffW]=IyIy;
			
			wire signed[abcCoeffW-1:0]IxIyEx=IxIy;//extend sign
			assign bij_arr[gi*(abcCoeffW)+:abcCoeffW]=IxIyEx;
				
	end
	
	wire [abcCoeffW-1:0]aij;
	wire [abcCoeffW-1:0]cij;
	wire signed[abcCoeffW-1:0]bij;
	 MFP_AdderTree
    #(.data_depth(abcCoeffW),.ArrL(cornorwindowDim),.isUnsigned(0)
     )AdderTree_aij(
       clk_p,en_p,aij_arr,aij);
	 MFP_AdderTree
    #(.data_depth(abcCoeffW),.ArrL(cornorwindowDim),.isUnsigned(0)
     )AdderTree_cij(
       clk_p,en_p,cij_arr,cij);
	 MFP_AdderTree
    #(.data_depth(abcCoeffW),.ArrL(cornorwindowDim),.isUnsigned(0)
     )AdderTree_bij(
		clk_p,en_p,bij_arr,bij);
	 
	 
	
	
	parameter tc=0;
	//assign DataOutPix[0]=addL[cornorwindowSize*cornorwindowSize-1].aij*2/cornorwindowDim;
	wire [dataW-1+1:0]aij_ave=aij*2/cornorwindowDim-tc;
	wire [dataW-1+1:0]cij_ave=cij*2/cornorwindowDim-tc;
	wire signed[dataW-1+1:0]bij_ave=bij*2/cornorwindowDim;
	
	wire signed[dataW-1+3:0]aijcij;
	MFP_Multi #(.In1W(dataW+1),.OutW(dataW+3),.isUnsigned(0)) m_ac(aij_ave,cij_ave,aijcij);		
	
	wire[dataW-1+3:0]bijbij;
	MFP_Multi #(.In1W(dataW+1),.OutW(dataW+3),.isUnsigned(0)) m_bb(bij_ave,bij_ave,bijbij);	
	
	
	wire signed[dataW-1+1:0]acSbb=aijcij/2-bijbij/2;
	
	
	assign DoGOut[1]=128+bijbij/4;
	assign DoGOut[0]=128+aijcij/4;
	assign DoGOut[2]=(acSbb[dataW])?0:acSbb;
endgenerate
	
	
	
	
	
endmodule
