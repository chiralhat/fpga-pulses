module pulses(
	      input 	   clk_pll, // The 200 MHz clock
	      input 	   reset, // Used only in simulation
	      input 	   pump, // First pulse on (1) or off (0), set by LabView (LV)
	      input [31:0] period, // Duty cycle (LV)
	      input [31:0] sync_up, // Time from the cycle beginning to the second pulse end, indirectly set by LabView (iLV)
	      input [31:0] p1width, // Width of the first pulse (LV)
	      input [31:0] p2start, // Time of the second pulse beginning (iLV)
	      input [31:0] p2width, // Width of the second pulse (LV)
	      input [31:0] pbwidth, // Extra pulse width (LV)
	      input [31:0] att_down, // Wait time before the attenuator switches after the second pulse for pump probe experiments (iLV)
	      input [6:0]  pp_pump, // Attenuation for pump pulse (LV)
	      input [6:0]  pp_probe, // Attenuation for probe pulse (LV)
	      input [6:0]  post_att, // Attenuation for second attenuator (LV)
	      input [31:0] delay, // Delay between main pulses (LV)
	      input [31:0] offres_delay, // Delay between extra pulse and first pulse (LV)
	      input 	   double, // Extra pulse on (1) or off (0) (LV)
	      input [7:0]  pulse_block, // Time after the second pulse to keep the blocking switch closed (LV)
	      input 	   block, // Blocking on (1) or off (0) (LV)
//	      input 	   pump_on, // Physical input to control the extra pulse being on (0) or off (1)
//	      input [7:0]  cpmg, // Number of extra CPMG pulses to perform (LV)
	      output 	   sync_on, // Wire for scope trigger pulse
	      output 	   pulse_on, // Wire for switch pulse
	      output [6:0] Att1, // Wires for main attenuator
	      output [6:0] Att3, // Wires for second attenuator
	      output 	   inhib, // Wire for blocking switch pulse
//	      output 	   pump_on,
	      output 	   record_start // Wire for boxcar trigger pulse (currently unused)
	      );

   // reg 			   reset = 0;
   reg 			   pump_up = 1;
   reg 				pump_on = 1;
   reg [31:0] 		   counter = 32'd0; // 32-bit for times up to 21 seconds
   // reg [6:0] 	     Att1 = att_on_val;
   reg 			   sync;
   reg 			   pulse;
   reg [6:0] 		   A1;
   reg [6:0] 		   A3;
   reg 			   inh;
   reg 			   rec = 0;
   reg [7:0] 		   ccount = 0;
   reg [31:0] 		   cdelay;
   reg [31:0] 		   cpulse;
   
   reg [7:0] cpmg = 0;
   
   
   assign sync_on = sync; // The scope trigger pulse
   assign pulse_on = pulse; // The switch pulse
   assign Att1 = A1; // The main attenuator control
   assign Att3 = A3; // The second attenuator control
   assign inhib = inh; // The blocking switch pulse
   assign record_start = rec; // The boxcar trigger pulse (currently unused)
   
   // The main loops runs on the 200 MHz PLL clock
   always @(posedge clk_pll) begin
      if (!reset) begin
	 counter <= (counter < period) ? counter + 1 : 0; // Increment the counter until it reaches the period

	 if (cpmg > 0) begin
	    case (counter)
	      0: begin
		 cdelay = sync_up + delay;
		 cpulse = cdelay + p2width;
		 ccount = 0;
	      end

	      cpulse: begin
		 if (ccount < cpmg) begin
		    cdelay = cpulse + delay;
		    cpulse = cdelay + p2width;
		    ccount = ccount + 1;
		 end
	      end
	    endcase // case (counter)
	 end // if (cpmg > 0)
	 
	 sync <= (counter < sync_up) ? 1 : 0; // Scope trigger pulse goes up at 0 and down at the end of the pulse
	 // pulse <= (counter < p1width) ? pump_up : 
	 pulse <= (counter < p1width) ? pump : // Switch pulse goes up at 0 if the pump is on
      		     ((counter < p2start) ? 0 : // then down after p1width
      		      ((counter < sync_up) ? 1 : // then up at the start of the second pulse
		       (((cpmg > 0) & (counter > cdelay) & (counter < cpulse)) ? 1 : // optional CPMG sequence
			((double & (counter > (offres_delay - pbwidth)) & (counter < offres_delay)) ? !pump_on : 0)))); // then down until offres_delay-pbwidth, when it goes up if 
	 A1 <= ((counter < (p1width + 1)) || (counter > att_down)) ? pp_pump : pp_probe; // Set the main attenuator to the pump attenuation unless the counter is between p1width+1 and att_down, then set it to the probe att.
	 A3 <= ((counter < (sync_up - 32'd30)) || (counter > att_down)) ? post_att : 0; // Set the second_attenuator to post_att except for a window after the second pulse. The 32'd30 was found to be good through testing.
	 
	 inh <= ((counter < (sync_up + pulse_block*10)) || (counter > att_down)) ? block : 0; // Turn the blocking switch on except for a window after the second pulse.
	 
	 // rec <= (counter < (sync_up + delay-32'd50)) ? 0 : ((counter < att_down) ? 1 : 0);
	 
      end // if (!reset)
      else begin
	 counter <= 0;
      end
   end // always @ (posedge clk_pll)
endmodule // pulses
