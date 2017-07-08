module pulses(
	      input 	   clk_pll,
	      input 	   resetn,
	      input 	   pump,
	      input [31:0] period,
	      input [31:0] sync_up,
	      input [31:0] p1width,
	      input [31:0] p2start,
	      input [31:0] pbwidth,
	      input [31:0] att_down,
	      input [6:0]  pp_pump,
	      input [6:0]  pp_probe,
	      input [6:0]  post_att,
	      input [31:0] delay,
	      input [31:0] offres_delay,
	      input 	   double,
	      input [7:0]  pulse_block,
	      input 	   block,
	      input 	   pump_on,
	      output 	   sync_on,
	      output 	   pulse_on,
	      output [6:0] Att1,
	      output [6:0] Att3,
	      output 	   inhib,
//	      output 	   pump_on,
	      output 	   record_start
	      );

   // reg 			   resetn = 0;
   reg 			   pump_up = 1;
   reg [31:0] 		   counter = 32'd0; // 32-bit for times up to 21 seconds
   // reg [6:0] 	     Att1 = att_on_val;
   reg 			   sync;
   reg 			   pulse;
   reg [6:0] 		   A1;
   reg [6:0] 		   A3;
   reg 			   inh;
   reg 			   rec;

   assign sync_on = sync;
   assign pulse_on = pulse;
   assign Att1 = A1;
   assign Att3 = A3;
   assign inhib = inh;
   assign record_start = rec;
   
   // The main loops runs on the 200 MHz PLL clock
   always @(posedge clk_pll) begin
      if (resetn) begin
	 counter <= (counter < period) ?
      		    counter + 1 : 0;

	 sync <= (counter < sync_up) ? 1 : 0;
	 // pulse <= (counter < p1width) ? pump_up : 
	 pulse <= (counter < p1width) ? pump : 
      		     ((counter < p2start) ? 0 :
      		      ((counter < sync_up) ? 1 :// 0))
//		       ((counter < (offres_delay)) ? 0 :
		       ((double & (counter > (offres_delay - pbwidth)) & (counter < offres_delay)) ? !pump_on : 0)));
//			((counter < (offres_delay + p1width)) ? pump_up : 0))));
	 A1 <= ((counter < (p1width + 1)) || (counter > att_down)) ? pp_pump : pp_probe;
//	 A3 <= post_att;
	 A3 <= ((counter < (sync_up - 32'd30)) || (counter > att_down)) ? post_att : 0;
	 
	 inh <= ((counter < (sync_up + pulse_block)) || (counter > att_down)) ? block : 0;
//	 inh <= 0;
	 
//	 rec <= 0;
	 rec <= (counter < (sync_up + delay-32'd50)) ? 0 : ((counter < att_down) ? 1 : 0);
	 
//	 if (counter == 0)
//	   pump_up <= double ? !pump_on : 0;
	 
      end // if (resetn)
      else begin
	 counter = 0;
      end
   end // always @ (posedge clk_pll)
endmodule // pulses
