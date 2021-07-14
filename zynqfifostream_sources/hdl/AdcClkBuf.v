`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.05.2021 12:17:25
// Design Name: 
// Module Name: AdcClkBuf
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


module AdcClkBuf(
	input AdcClkP_i,
	input AdcClkN_i,

	output AdcClk_o
    );


IBUFDS #(
	.DIFF_TERM("TRUE"),       // Differential Termination
	.IBUF_LOW_PWR("FALSE"),     // Low power="TRUE", Highest performance="FALSE" 
	.IOSTANDARD("DEFAULT")     // Specify the input I/O standard
)	AdcBufClk (
	.O(AdcClk_o),  // Buffer output
	.I(AdcClkP_i),  // Diff_p buffer input (connect directly to top-level port)
	.IB(AdcClkN_i) // Diff_n buffer input (connect directly to top-level port)
);

endmodule
