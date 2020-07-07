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
	      );

   reg [31:0] 		   counter = 32'd0; // 32-bit for times up to 21 seconds
   reg 			   sync;
   reg 			   pulse;
   reg [6:0] 		   A1;
   reg [6:0] 		   A3;
   reg 			   inh;
   reg 			   rec = 0;
   reg [7:0] 		   ccount = 1; // Which pi pulse are we on right now
   reg [31:0] 		   cdelay = 32'd230; // What is the time of the next pi pulse beginning
   reg [31:0] 		   cpulse = 32'd260; // What is the time of the next pi pulse ending
   reg [31:0] 		   cblock_delay = 32'd360; // When to stop blocking before the next return signal
   reg [31:0] 		   cblock_on; // When to start blocking after the next return signal
	reg [31:0]	sync_down;
   
   assign sync_on = sync; // The scope trigger pulse
   assign pulse_on = pulse; // The switch pulse
   assign Att1 = A1; // The main attenuator control
   assign Att3 = A3; // The second attenuator control
   assign inhib = inh; // The blocking switch pulse

   /* The main loops runs on the 200 MHz PLL clock.
    */
   always @(posedge clk_pll) begin
      if (!reset) begin
	 
	if (cpmg > 0) begin
		if (counter < p1width) begin
			cdelay = p1width + delay;
			cpulse = cdelay + p2width;
			cblock_delay = cpulse + pulse_block;
			cblock_on = cblock_delay + pulse_block_off;
			sync_down = cblock_delay;
			ccount = 1;
		end else if (counter > cpulse) begin
			if (ccount < cpmg) begin
				cdelay = cpulse + 2*delay;
				cpulse = cdelay + p2width;
			end
		end else if (counter > cblock_on) begin
			if (ccount < cpmg) begin
				cblock_delay = cpulse + pulse_block;
				cblock_on = cblock_delay + pulse_block_off;
				ccount = ccount + 1;
			end
		end
		
		sync <= (counter < sync_down) ? 1 : 0; // Scope trigger pulse goes up at 0 and down at the end of the pulse
		pulse <= (counter < p1width) ? pump : // Switch pulse goes up at 0 if the pump is on
				((counter < cdelay) ? 0 : // then down after p1width
				((counter < cpulse) ? 1 : 0));// then up at the start of the second pulse
		
		A1 <= pre_att;
		A3 <= ((counter < (cblock_delay - 32'd30)) || (counter > cblock_on)) ? post_att : 0; // Set the second_attenuator to post_att except for a window after the second pulse. The 32'd30 was found to be good through testing.
		
		inh <= ((counter < cblock_delay) || (counter > cblock_on)) ? block : 0; // Turn the blocking switch on except for a window after the second pulse.
		
		counter <= (counter < period) ? counter + 1 : 0; // Increment the counter until it reaches the period

	end else begin
		pulse <= 1;
		sync <= (counter < (period - 50)) ? 0 : 1;
	end
      end // if (!reset)
      else begin
	 counter <= 0;
      end

   end // always @ (posedge clk_pll)
endmodule // pulses
