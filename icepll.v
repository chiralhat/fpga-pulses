module icepll( input wire clk
		    , output wire clkout
		    , output wire locked
		    );
   SB_PLL40_CORE #(
		   .FEEDBACK_PATH("SIMPLE"),
		   .PLLOUT_SELECT("GENCLK"),
		   .DIVR(4'b0000),
		   .DIVF(7'b1000010),
		   .DIVQ(3'b010),
		   .FILTER_RANGE(3'b001)
		   ) uut (
			  .LOCK(locked),
			  .RESETB(1'b1),
			  .BYPASS(1'b0),
			  .REFERENCECLK(clk),
			  .PLLOUTCORE(clkout)
			  );
endmodule // icepll
