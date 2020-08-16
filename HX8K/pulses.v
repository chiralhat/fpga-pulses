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
	    //   input 	   reset, // Used only in simulation
	      input 	   pump, // First pulse on (1) or off (0), set by LabView (LV)
	      input [31:0] period, // Duty cycle (LV)
	      input [31:0] p1width, // Width of the first pulse (LV)
	      input [31:0] delay, // Delay between main pulses (LV)
	      input [31:0] p2width, // Width of the second pulse (LV)
	    //   input [6:0]  pre_att, // Attenuation for pump pulse (LV)
	    //   input [6:0]  post_att, // Attenuation for second attenuator (LV)
	      input [7:0]  cpmg, // Set mode to CW (0), Hahn echo (1), or CPMG (>1) (LV)
	      input [7:0]  pulse_block, // Time after the second pulse to keep the block switch closed (LV)
	      input [15:0] pulse_block_off, // Width of the signal window when we open the block switch (LV)
	      input 	   block, // Blocking on (1) or off (0) (LV)
	      output 	   sync_on, // Wire for scope trigger pulse
	      output 	   pulse_on, // Wire for switch pulse
	    //   output [6:0] Att1, // Wires for main attenuator
	    //   output [6:0] Att3, // Wires for second attenuator
	      output 	   inhib // Wire for blocking switch pulse
	      );

   reg [31:0] 		   counter = 32'd0; // 32-bit for times up to 21 seconds
   reg 			   sync;
   reg 			   pulse;
//    reg [6:0] 		   A1;
//    reg [6:0] 		   A3;
   reg 			   inh;
   reg 			   rec = 0;
   reg [31:0] 		   cblock_delay = 32'd310; // When to stop blocking before the next return signal
   reg [31:0] 		   cblock_on; // When to start blocking after the next return signal
	reg [31:0]	sync_down = 32'd50;
	reg [31:0]  first_cycle = 32'd100;
	reg [31:0]  pulse_end;
	reg [3:0]   pulse_state = 1;

	reg  		nutation_pulse = 0;
	reg [31:0]  nutation_pulse_width = 32'd50;
	reg [31:0]  nutation_pulse_delay = 32'd300;
	reg [31:0]  nutation_pulse_start;
	reg [31:0]  nutation_pulse_stop;
   
   assign sync_on = sync; // The scope trigger pulse
   assign pulse_on = pulse; // The switch pulse
//    assign Att1 = A1; // The main attenuator control
//    assign Att3 = A3; // The second attenuator control
   assign inhib = inh; // The blocking switch pulse
	// assign inhib = ccount[1];

	parameter FIRST_PULSE_ON = 4'd0;
	parameter FIRST_DELAY = 4'd1;
	parameter SECOND_PULSE_ON = 4'd2;
	parameter POST_PI_PULSE = 4'd3;
	parameter FIRST_BLOCK_OFF = 4'd4;
	parameter FIRST_BLOCK_ON = 4'd5;
	parameter CPMG_PULSE_ON = 4'd6;
	parameter POST_CPMG_PULSE = 4'd7;
	parameter CPMG_BLOCK_OFF = 4'd8;
	parameter CPMG_BLOCK_ON = 4'd9;
	parameter NUTATION_PULSE_ON = 4'd10;

   /* The main loops runs on the 200 MHz PLL clock.
    */
   always @(posedge clk_pll) begin
    //   if (!reset) begin
		  
	if (cpmg > 0) begin
		
		if (counter < 2) begin
			pulse_state <= FIRST_PULSE_ON;
			sync_down <= p1width + delay + p2width;
			nutation_pulse_start <= period - nutation_pulse_delay - nutation_pulse_width;
			nutation_pulse_stop <= period - nutation_pulse_delay;
			
			// cblock_delay <= p1width + delay + p2width + delay - pulse_block;
			// cblock_on <= p1width + delay + p2width + delay - pulse_block + pulse_block_off;
		end

		sync <= (counter < sync_down) ? 1 : 0;

		case (pulse_state)

			FIRST_PULSE_ON: begin
				// sync <= 1;
				pulse <= pump;
				inh <= block;
				// A3 <= post_att;

				if (counter == p1width) begin
					pulse_state <= FIRST_DELAY;
				end
			end

			FIRST_DELAY: begin
				pulse <= 0;
				inh <= block;
				// A3 <= post_att;

				if (counter == (p1width+delay)) begin
					pulse_state <= SECOND_PULSE_ON;
				end
			end

			SECOND_PULSE_ON: begin
				pulse <= 1;
				inh <= block;
				// A3 <= post_att;

				if (counter == sync_down) begin
					pulse_state <= POST_PI_PULSE;
				end
			end

			POST_PI_PULSE: begin
				pulse <= 0;
				inh <= block;
				// A3 <= post_att;

				if (counter == (p1width + delay + p2width + delay - pulse_block)) begin
					pulse_state <= FIRST_BLOCK_OFF;
				end
			end

			FIRST_BLOCK_OFF: begin
				pulse <= 0;
				inh <= 0;
				// A3 <= 0;

				if (counter == (p1width + delay + p2width + delay - pulse_block + pulse_block_off)) begin
					pulse_state <= FIRST_BLOCK_ON;
				end
			end

			FIRST_BLOCK_ON: begin
				pulse <= 0;
				inh <= block;
				// A3 <= post_att;

				if (nutation_pulse) begin
					if (counter == nutation_pulse_start) begin
						pulse_state <= NUTATION_PULSE_ON;
					end
				end
			end

			NUTATION_PULSE_ON: begin
				pulse <= 1;
				inh <= block;
				// A3 <= post_att;

				if (counter == nutation_pulse_stop) begin
					pulse_state <= FIRST_BLOCK_ON;
				end
			end

		endcase
		
		// A1 <= pre_att;
		// A3 <= ((counter < (cblock_delay - 32'd30)) || (counter > cblock_on)) ? post_att : 0; // Set the second_attenuator to post_att except for a window after the second pulse. The 32'd30 was found to be good through testing.
		
		counter <= (counter < period) ? counter + 1 : 0; // Increment the counter until it reaches the period


		// if (counter < (first_cycle-32'd10)) begin
		// 	sync_down = cpulse;

		// 	ccount = 8'd1;
		// // end else if (counter > cpulse) begin
		// // 	if (ccount < cpmg) begin
		// // 		cdelay = cpulse + 2*delay;
		// // 		cpulse = cdelay + p2width;
		// // 	end
		// end else if (counter < cblock_on) begin
		// 	change_pulse = 1;
		// end else if (counter > cblock_on) begin // This doesn't work right
		// 	if (((ccount) < cpmg) && change_pulse) begin
		// 		// cblock_delay = cpulse + pulse_block;
		// 		// cblock_on = cblock_delay + pulse_block_off;
		// 		ccount = ccount + 8'd1;
		// 		change_pulse = 0;
		// 	end
		// end
	end else begin
		pulse <= 1;
		sync <= (counter < (period - 50)) ? 0 : 1;
	end
    //   end // if (!reset)
    //   else begin
	//  counter <= 0;
	//  pulse_state <= 0;
    //   end

   end // always @ (posedge clk_pll)
endmodule // pulses
