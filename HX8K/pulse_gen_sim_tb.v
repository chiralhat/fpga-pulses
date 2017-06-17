`default_nettype none
`timescale 1ns / 1ns
  module tb;

   reg clk, clk_pll, reset = 0, P1 = 0;
   wire Pulse, Sync, FM, P2, P3, P4;
   wire [6:0] Att1;
   wire [6:0] Att3;

   pulse_gen_sim test(
		      .clk(clk),
		      .clk_pll(clk_pll),
		      .reset(reset),
		      .Pulse(Pulse),
		      .Sync(Sync),
		      .FM(FM),
		      .P1(P1),
		      .P2(P2),
		      .P3(P3),
		      .P4(P4),
		      .Att1(Att1),
		      .Att3(Att3)
		      );

   initial begin
      $dumpfile("Tests/HX8K/pulse_gen_sim.vcd");
      $dumpvars(0, test);

      clk = 1'b0;
      clk_pll = 1'b1;
      #1 reset = 1;
      #100 reset = 0;
      #150000 P1 = 1;
      #1500000 P1 = 0;
      #3000000 $finish;
   end
   
   always begin
      #5 clk_pll <= ~clk_pll;
   end

   always begin
      #87 clk <= ~clk;
   end
endmodule // tb
