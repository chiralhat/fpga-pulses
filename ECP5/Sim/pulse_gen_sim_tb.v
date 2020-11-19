`default_nettype none
`timescale 1ns / 100ps
module tb;

   reg clk, clk_pll, resetn = 0;
   wire Pulse, Sync, P2, RS232_Tx, RS232_Rx;
//    wire J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10;
//    wire J4_3, J4_4, J4_5, J4_6, J4_7, J4_8, J4_9;

   pulse_gen test(
		  .clk(clk),
		  .clk_pll(clk_pll),
		  .RS232_Rx(RS232_Rx),
		  .RS232_Tx(RS232_Tx),
		  .resetn(resetn),
		  .Pulse(Pulse),
		  .Sync(Sync),
		  .P2(P2)
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
      $dumpvars(0, test);

      clk = 1'b0;
      clk_pll = 1'b1;
      resetn = 0;
	  #1 resetn = 1;
	end
	initial 
      #1000 resetn = 0;
	initial begin
      //      #150000 P1 = 1;
      //     #1500000 P1 = 0;
      #3000000 $finish;
	end
   
   always begin
      #2.5 clk_pll <= ~clk_pll;
   end

   always begin
      #10 clk <= ~clk;
   end
endmodule // tb
