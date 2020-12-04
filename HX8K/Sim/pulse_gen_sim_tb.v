`default_nettype none
`timescale 1ns / 1ns
module tb;

   reg clk, clk_pll, resetn = 0;
   wire Pulse, Sync, Block, RS232_Rx, RS232_Tx;
//    wire J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10;
//    wire J4_3, J4_4, J4_5, J4_6, J4_7, J4_8, J4_9;

   pulse_gen test(
		  .clk(clk),
		  .clk_pll(clk_pll),
		  .RS232_Rx(RS232_Rx),
		  .RS232_Tx(RS232_Tx),
		  // .resetn(resetn),
		  .Pulse(Pulse),
		  .Sync(Sync),
		  .Block(Block)
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
      $dumpfile("Sim/pulse_gen_sim_tb.vcd");
      // $dumpvars(0, test);
      $dumpvars(1, Pulse, Sync, Block);

      clk = 1'b0;
      clk_pll = 1'b1;
      // #1 resetn = 1;
      // #50 resetn = 0;
      //      #150000 P1 = 1;
      //     #1500000 P1 = 0;
      #5000000 $finish;
      // #35000000 $finish;
   end
   
   always begin
      #4.975 clk_pll <= ~clk_pll;
   end

   always begin
      #41.667 clk <= ~clk;
   end
endmodule // tb
