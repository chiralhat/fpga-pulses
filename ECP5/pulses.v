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
	      input 	   clk, //The 50 MHz clock
	      input 	   clk_pll, // The 200 MHz clock
	      input 	   reset, // Used only in simulation
	      input [31:0] per, //Period
	      input [15:0] p1wid, //Width of pulse 1
	      input [15:0] del, //Delay between pulses
	      input [15:0] p2wid, //Width of pulse 2/cpmg pulses
	      input [15:0] p1wid2,
	      input [15:0] del2,
	      input [15:0] p2wid2,
	      input [15:0] p1st2,
	      input [7:0]  nut_w, //Width of nutation pulse
	      input [15:0] nut_d, //Nutation pulse delay - ends this many cycles before new period starts
	      input [6:0]  pr_att,
	      input [6:0]  po_att,
	      input [7:0]  cp, //CPMG settting: 0 for CW, 1 for Hahn echo, N>1 for CPMG with N pulses
	      input [7:0]  p_bl, //start of block open after pulses
	      input [15:0] p_bl_hf, //half of pulse_block
	      input 	   bl,
	      input 	   rxd,
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
	      output 	   pulse1_on, // Wire for switch pulse
	      output 	   pulse2_on, 
	      output [6:0] pre_att, // Wires for main attenuator
	      output [6:0] post_att, // Wires for second attenuator
	      output 	   pre_block,
	      output 	   inhib // Wire for blocking switch pulse
	      );

   reg [31:0] 		   counter = 32'd0; // 32-bit for times up to 21 seconds
   reg 			   sync;
   reg 			   pulse; //overall output - is 1 if pulses or nut_pulse is 1
   reg 			   pulses; //pulse register
   reg 			   pulse2;
   reg 			   pulse2s;
   reg 			   nut_pulse; //nutation pulse register
   reg [6:0] 		   pre_att_val;
   reg [6:0] 		   post_att_val;
   reg 			   pr_inh;
   reg 			   inh;
   reg 			   rec = 0;
   reg 			   cw = 0;
   
   // Running at a 201-MHz clock, our time step is ~5 (4.975) ns.
   // All the times are thus divided by 4.975 ns to get cycles.
   // 32-bit allows times up to 21 seconds
   /*parameter stperiod = 1; // 0.328 ms period
    parameter stp1width = 30; // 150 ns
    parameter stp2width = 30; //150 ns
    parameter stdelay = 200; // 1 us delay
    parameter stblock = 100; // 500 ns block open
    parameter stcpmg = 3; // Do cpmg with 3 pulses by default*/
   
   reg [31:0] 		   period;
   reg [15:0] 		   p1width;
   reg [15:0] 		   delay;
   reg [15:0] 		   p2width;
   reg [15:0] 		   p1width2;
   reg [15:0] 		   p2width2;
   reg [15:0] 		   p1start2;
   reg [15:0] 		   p2start2;
   reg [15:0] 		   p2stop2;
   reg [7:0] 		   pulse_block;
   reg [15:0] 		   pulse_block_half;
   reg [7:0] 		   cpmg;
   reg 			   block;
   reg 			   rx_done;

   //   assign led = cpmg;
   

   //reg [15:0] p2start = stp1width+stdelay;
   //reg [15:0] sync_down = stp1width+stdelay+stp2width;
   //reg [15:0] block_off = stp1width+stdelay+stdelay+stp2width-8'd50;
   //reg [15:0] block_on = stp1width+stdelay+stdelay+stp2width;
   //    reg [15:0] block_on = stp1width+2*stdelay+stp2width-8'd50+stblock;
   
   reg [15:0] 		   p2start;
   reg [15:0] 		   sdown;
   reg [15:0] 		   sync_down;
   reg [15:0] 		   block_off;
   reg [15:0] 		   block_on;

   reg [7:0] 		   nutation_pulse_width;
   reg [15:0] 		   nutation_pulse_delay;
   reg [23:0] 		   nutation_pulse_start;
   reg [23:0] 		   nutation_pulse_stop;

   reg [7:0] 		   ccount = 0; // Which pi pulse are we on right now
   reg [31:0] 		   cdelay; // What is the time of the next pi pulse beginning
   reg [31:0] 		   cpulse; // What is the time of the next pi pulse ending
   reg [31:0] 		   cblock_delay; // When to stop blocking before the next return signal
   reg [31:0] 		   cblock_on; // When to start blocking after the next return signal

   reg [1:0] 		   xfer_bits = 1;
   
   assign sync_on = sync; // The scope trigger pulse
   assign pulse1_on = pulse; // The switch pulse
   assign pulse2_on = pulse2; // The switch pulse
   assign pre_att = pre_att_val; // The main attenuator control
   assign post_att = post_att_val; // The second attenuator control
   assign pre_block = pr_inh; // The input blocking pulse (to completely squelch leakage)
   assign inhib = inh; // The blocking switch pulse
   //	assign pulse1_on = clk_pll;

   
   //In order to improve timing on clk_pll, do everything possible on slower clk block
   //Since clk is 50 MHz and clk_pll is 200 MHz (even multiple), hopefully should reduce problems with two blocks being out of sync
   always @(posedge clk) begin
      //{ rx_done, xfer_bits } <= { xfer_bits, rxd };
      
      //assign registers to input values when communication from PC is received
      //if (rx_done) begin
      period  <= per;
      p1width <= p1wid;
      p2width <= p2wid;
      p1width2 <= p1wid2;
      p2width2 <= p2wid2;
      p1start2 <= p1st2;
      delay <= del;
      nutation_pulse_delay <= nut_d;
      nutation_pulse_width <= nut_w;
      pulse_block <= p_bl;
      pulse_block_half <= p_bl_hf;
      cpmg <= cp;
      block <= bl;
      //end
      
      // period <= 4000;
      // p1width <= 30;
      // p2width <= 60;
      // delay <= 200;
      // nutation_pulse_delay <= 0;
      // nutation_pulse_width <= 0;
      // pulse_block <= 100;
      // pulse_block_half <= pulse_block/2;
      // cpmg <= 1;
      // block <= 1;
      
      //Calculate these values here, since they only change when their components are updated - better for timing
      p2start <= p1width + delay;
      p2start2 <= p1start2 + p1width2 + del2;
      p2stop2 <= p2start2 + p2width2;
      sdown <= p2start + p2width;// + 10;
      block_off <= sdown + pulse_block;
      block_on <= period - 10;
      nutation_pulse_start <= per - nutation_pulse_delay - nutation_pulse_width;
      nutation_pulse_stop <= per - nutation_pulse_delay;
      //		block_on <= period - nutation_pulse_delay - nutation_pulse_width - 10;
      // block_on <= block_off + pulse_block;
      
      //For some reason, this was reducing timing massively when in the clk_pll block, and it doesn't need to be
      //if (reset) begin
      //	counter <= 0;
      //end
      
      //Improves clk_pll timing, though not implemented exactly the same as in HX8K code due to presence of CPMG logic changing things
      cw <= (cpmg > 0) ? 0 : 1;
      
   end
   
   /* The main loops runs on the 200 MHz PLL clock.
    */
   always @(posedge clk_pll) begin
//      if (!reset) begin
	 //Calculate nutation pulse and regular pulses separately, then combine them later, to improve timing
	 //If nutation pulse is not needed, can just set its width to 0
	 case (cpmg)
	   0 : begin //cpmg=0 : CW (switch always open)
	      pulses <= 1;
	      pulse2s <= 0;
	      sync <= (counter < sdown) ? 0 : 1;
	      inh <= 0;
	      pre_att_val <= pr_att;
//	      post_att_val <= po_att;
	      
	   end
// 	   1: begin //cpmg=1 : Hahn echo with nutation pulse

	      




// 	      pre_att_val <= (counter < p1width) ? pr_att : 0;
// 	      post_att_val <= (counter < block_off) ? po_att :
// 			      ((counter < (nutation_pulse_start-5)) ? 0 : po_att);
// 	      // A1 <= pre_att;
// 	      // A3 <= ((counter < (cblock_delay - 32'd30)) || (counter > cblock_on)) ? post_att : 0; // Set the second_attenuator to post_att except for a window after the second pulse. The 32'd30 was found to be good through testing.
// 	   end
	   default : begin //cpmg > 1 : CPMG with # pulses given by value of cpmg
 	      sync <= (counter < sync_down) ? 1 : 0; //Leave sync on until sync_down (end of pulses)

	      pulses <= (counter < p1width) ? 1 :// Switch pulse goes up before p1width
			((counter < cdelay) ? 0 : //Then down (if cw mode not on) before p2start
			 ((counter < cpulse) ? (((ccount < cpmg) && (p2width > 0)) ? 1 : 0) : 0));
	      
 	      inh <= (counter < cblock_delay) ? block :
		     ((counter < cblock_on) ? ((ccount < cpmg) ? 0 : inh) :
 		      ((counter < (nutation_pulse_start-5)) ? inh : block));
	      
 	      nut_pulse <= (counter < nutation_pulse_start) ? 0 :
			   ((counter < nutation_pulse_stop) ? 1 : 0);

	      pulse2s <= (counter < p1start2) ? 0 :
      			 ((counter < p1width2) ? 1 :
      			  ((counter < p2start2) ? 0 :
      			   ((counter < p2stop2) ? 1 : 0)));

	      pre_att_val <= (counter < p1width | (counter > p1start2 && counter < p1width2)) ? pr_att+6 :
//			     ((counter < (cdelay-18) | counter < (p2start2-18)) ? 255 :
//			      ((counter < (cpulse-18) | counter < (p2stop2-18)) ? pr_att :
//			       ((counter < (nutation_pulse_start-20)) ? 255 :
//				((counter < nutation_pulse_stop) ? pr_att :
				 ((counter < (period-20)) ? pr_att : pr_att+6);

	      case (counter) //case blocks generally seem to be faster than if-else, from what I've seen
		0: begin //at 0, turn on sync, pulses, and block, then calculate initial values of time markers
		   sync_down <= sdown;

		   cdelay <= p1width + delay; //start of first CPMG pulse after initial pulse
		   cpulse <= sdown; //end of first CPMG pulse
		   // cblock_delay <= p1width + delay + p2width + delay - pulse_block_half; //start of first block open 
		   cblock_delay <= sdown + pulse_block; //start of first block open 
		   cblock_on <= sdown + 2*delay-5; //end of first block open
		   //					cblock_delay <= p1width + delay + p2width + pulse_block; //start of first block open 
		   //					cblock_on <= p1width + delay + p2width + delay + pulse_block_half; //end of first block open
		   ccount <= 0;
		   
		end // case: 0

		// p1width: begin
		//    pulses <= 0; //turn pulses off at end of first pulse
		//    // pre_att_val <= 255;
		// end //case: p1width

// 		cdelay: begin
// 		   pulses <= (ccount < cpmg) ? ((p2width > 0) ? 1 : 0) : pulses; //set pulses high again if we have not yet reached the last CPMG pulse
// //		   pre_att_val <= (ccount < cpmg) ? ((p2width > 0) ? pr_att : 255) : pre_att_val;
		   
// 		end // case: cdelay

		cpulse: begin		 
		   if (ccount < cpmg) begin //if we have not yet reached the last pulse, set pulses to 0 and recalculate time marker values
		      cdelay <= cpulse + delay + delay; //start of next pulse = current place + 2*delay
		      cpulse <= cpulse + delay + delay + p2width; //end of next pulse = current place + 2*delay + width of next pulse
		      sync_down <= cpulse;
//delay + delay + p2width + 10;
		      
		   end
		   // else begin
		   //    sync <= 0;
		   //    end
		   
		end //case: cpulse

		// sync_down: begin
		//    sync <= (ccount == cpmg - 1) ? 0 : sync; //turn sync off if we have finished the last pulse
		// end

		// cblock_delay: begin
		//    if (ccount < cpmg) begin //open block if we have not reached the last pulse
		//       inh <= 0;
		//       post_att_val <= 0;
		   
		//    end
		// end // case: cblock_delay

		cblock_on: begin
		   if (ccount < (cpmg-1)) begin //if we have not reached the last pulse, close block and recalculate block marker values
		      
		      cblock_delay <= cpulse + pulse_block; //start of next open period = end of next pulse + block delay
		      cblock_on <= cpulse + 2*delay-5; //end of next open period = end of next pulse + block off
		      
		   end
		   ccount <= ccount + 1;
		end //case: cblock_on

// 		(nutation_pulse_start-5): begin
// 		   inh <= block;
// //		   pre_att_val <= pr_att;
// 		   post_att_val <= po_att;
		   
// 		end

//		nutation_pulse_stop: begin
//		   pre_att_val <= 255;
//		end
		
	      endcase // case (counter)
	   end
	 endcase
	 counter <= (counter < period) ? counter + 1 : 0; // Increment the counter until it reaches the period
	 pulse <= pulses;// | nut_pulse;
	 pulse2 <= pulse2s | nut_pulse;
	 pr_inh <= pulse | pulse2;
//      end //if (!reset)
//      else begin
//	 counter <= 0;
//      end		   

   end // always @ (posedge clk_pll)
endmodule // pulses
