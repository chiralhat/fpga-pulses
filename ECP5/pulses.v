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
	input 		 clk,
	input 	     clk_pll, // The 200 MHz clock
	input 	     reset, // Used only in simulation
	input [23:0]  per,
	input [15:0] p1wid,
	input [15:0] del,
	input [15:0] p2wid,
	input [7:0] nut_w,
	input [15:0] nut_d,
	// input [6:0]  pr_att,
	//       input [6:0]  po_att,
	input [7:0]  cp,
	input [7:0]  p_bl,
	input [15:0] p_bl_off,
	input 	     bl,
	input		 rxd,
	// 	 input [31:0] period, // Duty cycle (LV)
	//   input [31:0] p1width, // Width of the first pulse (LV)
	//   input [31:0] delay, // Delay between main pulses (LV)
	//   input [31:0] p2width, // Width of the second pulse (LV)
	// //   input [6:0]  pre_att, // Attenuation for pump pulse (LV)
	// //   input [6:0]  post_att, // Attenuation for second attenuator (LV)
	//   input 	  cpmg, // Set mode to CW (0), Hahn echo (1) (LV)
	//   input [7:0]  pulse_block, // Time after the second pulse to keep the block switch closed (LV)
	//   input [15:0] pulse_block_off, // Width of the signal window when we open the block switch (LV)
	//   input 	   block, // Blocking on (1) or off (0) (LV)
	output 	   sync_on, // Wire for scope trigger pulse
	output 	   pulse_on, // Wire for switch pulse
	//   output [6:0] Att1, // Wires for main attenuator
	//   output [6:0] Att3, // Wires for second attenuator
	output 	   inhib // Wire for blocking switch pulse
	);

	reg [31:0] 		   counter = 32'd0; // 32-bit for times up to 21 seconds
	reg 			   sync;
	reg 			   pulse;
	reg 			   pulses;
	reg 			   nut_pulse;
	//    reg [6:0] 		   A1;
	//    reg [6:0] 		   A3;
	reg 			   inh;
	reg 			   rec = 0;
   
	// Running at a 201-MHz clock, our time step is ~5 (4.975) ns.
	// All the times are thus divided by 4.975 ns to get cycles.
	// 32-bit allows times up to 21 seconds
	parameter stperiod = 1; // 1 ms period
	parameter stp1width = 30; // 150 ns
	parameter stp2width = 30;
	parameter stdelay = 200; // 1 us delay
	parameter stblock = 100; // 500 ns block open
	parameter stcpmg = 3; // Do Hahn echo by default
   
	reg [23:0] 			    period = stperiod << 16;
	reg [15:0] 			    p1width = stp1width;
	reg [15:0] 			    delay = stdelay;
	reg [15:0] 			    p2width = stp2width;
	reg [7:0] 			    pulse_block = 8'd50;
	reg [15:0] 			    pulse_block_off = stblock;
	reg [7:0]  			    cpmg = stcpmg;
	reg 				   	block = 1;
	reg 					rx_done = 0;

	reg [15:0] p2start = stp1width+stdelay;
	reg [15:0] sync_down = stp1width+stdelay+stp2width;
	reg [15:0] block_off = stp1width+stdelay+stdelay+stp2width-8'd50;
	reg [15:0] block_on = stp1width+stdelay+stdelay+stp2width;
	//    reg [15:0] block_on = stp1width+2*stdelay+stp2width-8'd50+stblock;

	reg  		nutation_pulse = 0;
	reg [7:0]  nutation_pulse_width = 8'd50;
	reg [15:0]  nutation_pulse_delay = 16'd300;
	reg [23:0]  nutation_pulse_start;
	reg [23:0]  nutation_pulse_stop;

	reg [7:0] 		   ccount = 0; // Which pi pulse are we on right now
	reg [31:0] 		   cdelay; // What is the time of the next pi pulse beginning
	reg [31:0] 		   cpulse; // What is the time of the next pi pulse ending
	reg [31:0] 		   cblock_delay; // When to stop blocking before the next return signal
	reg [31:0] 		   cblock_on; // When to start blocking after the next return signal

	reg [1:0] xfer_bits = 1;
   
	assign sync_on = sync; // The scope trigger pulse
	assign pulse_on = pulse; // The switch pulse
	//    assign Att1 = A1; // The main attenuator control
	//    assign Att3 = A3; // The second attenuator control
	assign inhib = inh; // The blocking switch pulse
	// assign inhib = ccount[1];

	
	always @(posedge clk) begin
		{ rx_done, xfer_bits } <= { xfer_bits, rxd };
		
		if (rx_done) begin
			period  <= per;
			p1width <= p1wid;
			p2width <= p2wid;
			delay <= del;
			nutation_pulse_delay <= nut_d;
			nutation_pulse_width <= nut_w;
			pulse_block <= p_bl;
			pulse_block_off <= p_bl_off;
			cpmg <= cp;
			block <= bl;
		end
		
		p2start <= p1width + delay;
		sync_down <= p1width + delay + p2width;
		block_off <= p1width + delay + p2width + delay - pulse_block;
		block_on <= p1width + delay + p2width + delay;
		
		if (reset) begin
			counter <= 0;
		end
		
	end
	
	/* The main loops runs on the 200 MHz PLL clock.
	*/
	always @(posedge clk_pll) begin
		if (!reset) begin			
			nutation_pulse_start <= per - nutation_pulse_delay - nutation_pulse_width;
			nutation_pulse_stop <= per - nutation_pulse_delay;
			
			nut_pulse <= (counter < nutation_pulse_start) ? 0 :
				((counter < nutation_pulse_stop) ? 1 : 0);

			case (cpmg)
			0 : begin //cpmg=0 : CW (switch always open)
				pulse <= 1;
			end
			1: begin //cpmg=1 : Hahn echo with nutation pulse

				pulses <= (counter < p1width) ? 1 :// Switch pulse goes up at 0 if the pump is on
				((counter < p2start) ? 0 : // then down after p1width
				((counter < sync_down) ? 1 : 0));
				
				inh <= (counter < block_off) ? block : 
				((counter < block_on) ? 0 : block); // Turn the blocking switch on except for a window after the second pulse.

				sync <= (counter < sync_down) ? 1 : 0;

				// A1 <= pre_att;
				// A3 <= ((counter < (cblock_delay - 32'd30)) || (counter > cblock_on)) ? post_att : 0; // Set the second_attenuator to post_att except for a window after the second pulse. The 32'd30 was found to be good through testing.
			end
			default : begin //cpmg > 1 : CPMG with # pulses given by value of cpmg
				case (counter) //case blocks generally seem to be faster than if-else, from what I've seen
					0: begin
					sync <= 1;
					pulses <= 1;
					inh <= block;
					//A1 = pre_att;
					//A3 = post_att;

					cdelay <= p1width + delay;
					cpulse <= p1width + delay + p2width;
					cblock_delay <= p1width + delay + p2width + delay;
					cblock_on <= p1width + delay + p2width + delay + pulse_block_off;
					ccount <= 0;
					
					end // case: 0

					p1width: begin
						pulses <= 0;
					end //case: p1width

					cdelay: begin
						pulses <= (ccount < cpmg) ? 1 : pulses;

					end // case: c1delay

					cpulse: begin		 
						if (ccount < cpmg) begin
						pulses <= 0;

						cdelay <= cpulse + delay + delay;
						cpulse <= cpulse + delay + delay + p2width;

						end
						
						sync <= (ccount == cpmg - 1) ? 0 : sync;
					end //case: cpulse

					cblock_delay: begin
						if (ccount < cpmg) begin
							inh <= 0;
						end
					end // case: cblock_delay

					cblock_on: begin
						if (ccount < cpmg) begin
							inh <= block;

							cblock_delay <= cpulse + delay;
							cblock_on <= cpulse + delay + pulse_block_off;
		
							ccount <= ccount + 1;
						end
					end //case: cblock_on
				endcase // case (counter)
			end
		endcase
		counter <= (counter < period) ? counter + 1 : 0; // Increment the counter until it reaches the period
		pulse <= pulses || nut_pulse;
		end// if (!reset)

	end // always @ (posedge clk_pll)
endmodule // pulses
