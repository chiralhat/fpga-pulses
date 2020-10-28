`default_nettype none
`timescale 1ns / 100ps
module tb;

   reg clk, clk_pll, resetn = 0;
   wire Pulse, Sync, P2, RS232_Tx;
   reg RS232_Rx;
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

	parameter CONT_SET_DELAY = 8'd0;
	parameter CONT_SET_PERIOD = 8'd1;
	parameter CONT_SET_PULSE1 = 8'd2;
	parameter CONT_SET_PULSE2 = 8'd3;
	parameter CONT_TOGGLE_PULSE1 = 8'd4;
	parameter CONT_SET_CPMG = 8'd5;
	parameter CONT_SET_ATT = 8'd6;
	parameter CONT_SET_NUTW = 8'd7;
	parameter CONT_SET_NUTD = 8'd8;
   
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
	initial begin //sending data to test uart - 434.03 (435 to be safe) cycles of 50 MHz clock = 1 bit at 115200 baud
		//must wait 5*435 = 2175 cycles so that uart can read each bit 5 times
		#10000 RS232_Rx <= 1'b0; //starting bit - data begins on next bit
		#3 RS232_Rx <= 1'b0; //data starts here - 32 bits for changing delay to 100 cycles
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b1;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b1;
		#2175 RS232_Rx <= 1'b1;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
		#2175 RS232_Rx <= 1'b0;
	end
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
