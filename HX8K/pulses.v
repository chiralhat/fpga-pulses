module pulses(
	      /* This module sets up the output logic, including the pulse and block switches, the attenuator(s),
	       and the scope trigger. It needs to have two modes:
	       
	       A CW mode, which holds both switches open, and outputs a trigger for the scope and the SynthHD.
	       This mode is chosen by setting the 'mode' input to 0.
	       Inputs are 'period', 'pre_att', and 'post_att'.
	       
	       A pulsed mode, which opens the pulse switch to chop the pulses up, closes the block switch for
	       only the period after each pi pulse where we expect the echo to be (if blocking is on).
	       This mode is chosen by setting the 'mode' input to a nonzero value, denoting the number of pi pulses.
	       If 'mode' is 1, a Hahn echo is taken, otherwise it's CPMG. 
	       Inputs are 'pum
	       */
	      input 	   clk_pll, // The 200 MHz clock
	      input 	   reset, // Used only in simulation
	      input 	   pump, // First pulse on (1) or off (0), set by LabView (LV)
	      input [31:0] period, // Duty cycle (LV)
	      input [31:0] p1width, // Width of the first pulse (LV)
	      input [31:0] delay, // Delay between main pulses (LV)
	      input [31:0] p2width, // Width of the second pulse (LV)
	      input [6:0]  pre_att, // Attenuation for pump pulse (LV)
	      input [6:0]  post_att, // Attenuation for second attenuator (LV)
	      input [7:0]  cpmg, // Set mode to CW (0), Hahn echo (1), or CPMG (>1) (LV)
		  input [7:0]  pulse_block, // Time after the second pulse to keep the block switch closed (LV)
	      input [15:0] pulse_block_off, // Width of the signal window when we open the block switch (LV)
	      input 	   block, // Blocking on (1) or off (0) (LV)
	      output 	   sync_on, // Wire for scope trigger pulse
	      output 	   pulse_on, // Wire for switch pulse
	      output [6:0] Att1, // Wires for main attenuator
	      output [6:0] Att3, // Wires for second attenuator
	      output 	   inhib // Wire for blocking switch pulse
	      // input [31:0] sync_up, // Time from the cycle beginning to the second pulse end, indirectly set by LabView (iLV)
	      //	      input [31:0] p2start, // Time of the second pulse beginning (iLV)
	      //	      input [31:0] pbwidth, // Extra pulse width (LV)
	      //	      input [31:0] att_down, // Wait time before the attenuator switches after the second pulse for pump probe experiments (iLV)
	      //	      input [6:0]  pp_probe, // Attenuation for probe pulse (LV)
	      //	      input [31:0] offres_delay, // Delay between extra pulse and first pulse (LV)
	      //	      input 	   double, // Extra pulse on (1) or off (0) (LV)
	      //	      input 	   pump_on, // Physical input to control the extra pulse being on (0) or off (1)
	      //	      input [7:0]  cpmg, // Number of extra CPMG pulses to perform (LV)
	      //	      output 	   pump_on,
	      //	      output 	   record_start // Wire for boxcar trigger pulse (currently unused)
	      );

   // reg 			   reset = 0;
   reg 			   pump_up = 1;
   reg 			   pump_on = 1;
   reg [31:0] 		   counter = 32'd0; // 32-bit for times up to 21 seconds
   // reg [6:0] 	     Att1 = att_on_val;
   reg 			   sync;
   reg 			   pulse;
   reg [6:0] 		   A1;
   reg [6:0] 		   A3;
   reg 			   inh;
   reg 			   rec = 0;
   reg [7:0] 		   ccount = 0; // Which pi pulse are we on right now
   reg [31:0] 		   cdelay; // What is the time of the next pi pulse beginning
   reg [31:0] 		   cpulse; // What is the time of the next pi pulse ending
   reg [31:0] 		   cblock_delay; // When to stop blocking before the next return signal
   reg [31:0] 		   cblock_on; // When to start blocking after the next return signal
   
//    reg [7:0] 		   cpmg = 1;
   
   
   assign sync_on = sync; // The scope trigger pulse
   assign pulse_on = pulse; // The switch pulse
   assign Att1 = A1; // The main attenuator control
   assign Att3 = A3; // The second attenuator control
   assign inhib = inh; // The blocking switch pulse
   //    assign record_start = rec; // The boxcar trigger pulse (currently unused)

   /* The main loops runs on the 200 MHz PLL clock.
    This wants to be a case structure, I think, rather than a conditional chain.
    */
   always @(posedge clk_pll) begin
      if (!reset) begin
	 counter <= (counter < period) ? counter + 1 : 0; // Increment the counter until it reaches the period

	 if (cpmg > 0) begin
	    case (counter)
	      0: begin
		 sync = 1;
		 pulse = pump;
		 inh = block;
		 A1 = pre_att;
		 A3 = post_att;
		 
		 cdelay = p1width + delay;
		 cpulse = cdelay + p2width;
		 cblock_delay = cpulse + pulse_block;
		 cblock_on = cblock_delay + pulse_block_off;
		 ccount = 0;
	      end // case: 0

	      p1width: begin
		 pulse = 0;
	      end

	      cdelay: begin
		 if (ccount < cpmg) begin
		    pulse = 1;
		 end
	      end

	      cpulse: begin		 
		 if (ccount < cpmg) begin
		    pulse = 0;
		    
		    cdelay = cpulse + delay;
		    cpulse = cdelay + p2width;
		 end
	      end

	      cblock_delay: begin
		 if (ccount == 0) begin
		    sync = 0;
		 end

		 if (ccount < cpmg) begin
		    inh = 0;
		 end
	      end // case: cblock_delay

	      cblock_on: begin
		 if (ccount < cpmg) begin
		    inh = block;
		    
		    cblock_delay = cpulse + pulse_block;
		    cblock_on = cblock_delay + pulse_block_off;
		    ccount = ccount + 1;
		 end
	      end
	    endcase // case (counter)
	 end // if (cpmg > 0)
	 
	 // sync <= (counter < sync_up) ? 1 : 0; // Scope trigger pulse goes up at 0 and down at the end of the pulse
	 // // pulse <= (counter < p1width) ? pump_up : 
	 // pulse <= (counter < p1width) ? pump : // Switch pulse goes up at 0 if the pump is on
      	 // 	  ((counter < p2start) ? 0 : // then down after p1width
      	 // 	   ((counter < sync_up) ? 1 : // then up at the start of the second pulse
	 // 	    (((cpmg > 0) & (counter > cdelay) & (counter < cpulse)) ? 1 : // optional CPMG sequence
	 // 	     ((double & (counter > (offres_delay - pbwidth)) & (counter < offres_delay)) ? !pump_on : 0)))); // then down until offres_delay-pbwidth, when it goes up if 
	 // A1 <= ((counter < (p1width + 1)) || (counter > att_down)) ? pp_pump : pp_probe; // Set the main attenuator to the pump attenuation unless the counter is between p1width+1 and att_down, then set it to the probe att.
	 // A3 <= ((counter < (sync_up - 32'd30)) || (counter > att_down)) ? post_att : 0; // Set the second_attenuator to post_att except for a window after the second pulse. The 32'd30 was found to be good through testing.
	 
	 // inh <= ((counter < (sync_up + pulse_block*10)) || (counter > att_down)) ? block : 0; // Turn the blocking switch on except for a window after the second pulse.
	 
	 // rec <= (counter < (sync_up + delay-32'd50)) ? 0 : ((counter < att_down) ? 1 : 0);
	 
      end // if (!reset)
      else begin
	 counter <= 0;
      end
   end // always @ (posedge clk_pll)
endmodule // pulses
