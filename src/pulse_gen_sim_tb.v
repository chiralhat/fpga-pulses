`default_nettype none
`timescale 1ns / 100ps
module tb;

   reg clk, clk_pll;
   wire Pulse, Sync, RS232_Tx, RS232_Rx, Pre_Block;
//    wire J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10;
//    wire J4_3, J4_4, J4_5, J4_6, J4_7, J4_8, J4_9;

   pulse_gen test(
		  .clk_uart(clk),
		  .clk_pll(clk_pll),
		  .RS232_Rx(RS232_Rx),
		  .RS232_Tx(RS232_Tx),
		  .Pulse(Pulse),
		  .Sync(Sync),
		  .Pre_Block(Pre_Block)
		//   .J1_4(J1_4),
		//   .J1_5(J1_5),
		//   .J1_6(J1_6),
		//   .J1_7(J1_7),
		//   .J1_8(J1_8),
		//   .J1_9(J1_9),
		//   .J1_10(J1_10),
		//   .J4_3(J4_3),
		//   .J4_4(J4_4),
		//   .J4_5(J4_5),
		//   .J4_6(J4_6),
		//   .J4_7(J4_7),
		//   .J4_8(J4_8),
		//   .J4_9(J4_9)
		  );
   
   initial begin
      $dumpfile("build/pulse_gen_sim_tb.vcd");
      $dumpvars(0, test);

      clk = 1'b0;
      clk_pll = 1'b1;
	end
	initial begin
      #3000000 $finish;
	end
   
   always begin
      #5 clk_pll <= ~clk_pll;
   end

   always begin
      #10 clk <= ~clk;
   end
endmodule // tb
