`default_nettype none
`timescale 1ns / 1ns
module tb;

   reg clk, clk_pll, resetn = 0;
   wire Pulse, Sync, FM, P2, P3, P4, RS232_Rx, RS232_Tx;
   wire J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10;
   wire J4_3, J4_4, J4_5, J4_6, J4_7, J4_8, J4_9;

   pulse_gen test(
		  .clk(clk),
		  .clk_pll(clk_pll),
		  .RS232_Rx(RS232_Rx),
		  .RS232_Tx(RS232_Tx),
		  .resetn(resetn),
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
      $dumpfile("pulse_gen_sim_tb.vcd");
      $dumpvars(0, test);

      clk = 1'b0;
      clk_pll = 1'b1;
      #1 resetn = 1;
      #100 resetn = 0;
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
