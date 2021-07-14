`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.06.2021 13:15:00
// Design Name: 
// Module Name: CtrlFifoBufAdc
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CtrlFifoBufAdc(

	output FifoWriteEn_o,
	output FifoReadEn_o
);

assign FifoReadEn_o = 1'b1;
assign FifoWriteEn_o = 1'b1;

endmodule
