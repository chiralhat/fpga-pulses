`default_nettype none
`timescale 1ns / 1ns
module tb;

   reg clk, clk_pll, reset = 0, RS232_Rx, RS232_Tx;
   wire Pulse, Sync, FM, P2, P3, P4;
   wire J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10;
   wire J4_3, J4_4, J4_5, J4_6, J4_7, J4_8, J4_9;

   pulse_gen test(
		  .clk(clk),
		  .RS232_Rx(RS232_Rx),
		  .RS232_Tx(RS232_Tx),
		  .clk_pll(clk_pll),
		  .reset(reset),
		  .Pulse(Pulse),
		  .Sync(Sync),
		  .FM(FM),
		  .P2(P2),
		  .P3(P3),
		  .P4(P4),
		  .J1_4(J1_4),
		  .J1_5(J1_5),
		  .J1_6(J1_6),
		  .J1_7(J1_7),
		  .J1_8(J1_8),
		  .J1_9(J1_9),
		  .J1_10(J1_10),
		  .J4_3(J4_3),
		  .J4_4(J4_4),
		  .J4_5(J4_5),
		  .J4_6(J4_6),
		  .J4_7(J4_7),
		  .J4_8(J4_8),
		  .J4_9(J4_9)
		  );

   initial begin
      $dumpfile("HX8K/pulse_gen_sim.vcd");
      $dumpvars(0, test);

      clk = 1'b0;
      clk_pll = 1'b1;
      #1 reset = 0;
      #100 reset = 1;
      //      #150000 P1 = 1;
      //     #1500000 P1 = 0;
      #3000000 $finish;
   end
   
   always begin
      #5 clk_pll <= ~clk_pll;
   end

   always begin
      #87 clk <= ~clk;
   end
endmodule // tb
