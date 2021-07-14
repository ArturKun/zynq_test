`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.06.2021 13:21:27
// Design Name: 
// Module Name: AdcInvertSignBit
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


module AdcInvertSignBit(
    input [15:0] AdcData_i,
    output [15:0] AdcData_SignBitInvert_o
    );

assign AdcData_SignBitInvert_o = {~AdcData_i[15], AdcData_i[14:0]};

endmodule
