module pulses(
	      input 	   clk_pll,
	      input 	   pump,
	      input [31:0] period,
	      input [31:0] sync_up,
	      input [31:0] p1width,
	      input [31:0] p2start,
	      input [31:0] att_down,
	      input [6:0]  pp_pump,
	      input [6:0]  pp_probe,
	      input [31:0] delay,
	      input 	   double,
	      output 	   sync_on,
	      output 	   pulse_on,
	      output [6:0] Att1,
	      // output 	   J1_4,
	      // output 	   J1_5,
	      // output 	   J1_6,
	      // output 	   J1_7,
	      // output 	   J1_8,
	      // output 	   J1_9,
	      // output 	   J1_10,
	      output 	   inhib,
	      output 	   pump_on,
	      output 	   record_start
	      );

   
   parameter att_on_val = 7'b1111111;
   reg 			   resetn = 0;
   reg 		     pump_up = 1;
   reg [31:0] 	     counter = 32'd0; // 32-bit for times up to 21 seconds
   // reg [6:0] 	     Att1 = att_on_val;
   
   assign pump_on = !pump_up;
   // assign J1_4 = Att1[6];
   // assign J1_5 = Att1[5];
   // assign J1_6 = Att1[4];
   // assign J1_7 = Att1[3];
   // assign J1_8 = Att1[2];
   // assign J1_9 = Att1[1];
   // assign J1_10 = Att1[0];

   // The main loops runs on the 200 MHz PLL clock
   always @(posedge clk_pll) begin
      if (resetn) begin
	 counter <= (counter < period) ?
      		    counter + 1 : 0;

	 sync_on <= (counter < sync_up) ? 1 : 0;
	 pulse_on <= (counter < p1width) ? pump_up : 
      		     ((counter < p2start) ? 0 :
      		      ((counter < sync_up) ? 1 : 0));
	 Att1 <= ((counter < (p1width + 1)) || (counter > att_down)) ? pp_pump : pp_probe;
	 // inhib <= (counter < (sync_up + delay - 10)) ? 1 : ((counter > (sync_up + delay + 60)) ? 1 : 0);
	 inhib <= 0;
	 record_start <= (counter < (sync_up + delay - 20)) ? 0 : ((counter < att_down) ? 1 : 0);
	 
	 if (counter == period)
	   pump_up <= double ? !pump_up : pump;
      end // if (resetn)
      else begin
	 counter = 0;
	 resetn = 1;
      end
   end // always @ (posedge clk_pll)
endmodule // pulses
