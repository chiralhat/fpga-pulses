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
	      input 	   clk, //The 12 MHz clock
	      input 	   clk_pll, // The 200 MHz clock
	      input [31:0] per, //Period
	      input [15:0] p1wid, //Width of channel 1 pulse 1
	      input [15:0] del, //Delay between channel 1 pulses
	      input [15:0] p2wid, //Width of channel 1 pulse 2
	      input [15:0] p1wid2, //Width of channel 2 pulse 1
	      input [15:0] del2, //Delay between channel 2 pulses
	      input [15:0] p2wid2, //Width of channel 2 pulse 2
	      input [15:0] p1st2, //Start offset of channel 2 pulse 1
	      input [7:0]  nut_w, //Width of nutation pulse
	      input [15:0] nut_d, //Nutation pulse delay - ends this many cycles before new period starts
	      input [6:0]  pr_att, //Attenuation level
	      input 		 cp, //CPMG settting: 0 for CW, 1 for Hahn echo
	      input 	   bl, //Toggle for which channel is on in CW mode
	      output 	   sync_on, // Wire for scope trigger pulse
	      output 	   pulse1_on, // Wire for channel 1 switch pulse
	      output 	   pulse2_on,  // Wire for channel 2 switch pulse
	      output [6:0] pre_att, // Wires for main attenuator
	      output [6:0] post_att, // Wires for second attenuator
	      output 	   pre_block // Wire for leakage block switch
	      );

   reg [31:0] 		   counter = 32'd0; // 32-bit for times up to 21 seconds
   reg 			   sync;
   reg 			   pulse; //overall output for channel 1 - is 1 if pulses is 1
   reg 			   pulses; //channel 1 pulse register
   reg 			   pulse2; //overall output for channel 2 - is 1 if pulse2s or nut_pulse is 1
   reg 			   pulse2s; //channel 2 pulse register
   reg 			   nut_pulse; //nutation pulse register
   reg [6:0] 		   pre_att_val;
   reg 			   pr_inh;
   reg 			   rec = 0;
   
   // Running at a 201-MHz clock, our time step is ~5 (4.975) ns.
   // All the times are thus divided by 4.975 ns to get cycles.
   // 32-bit allows times up to 21 seconds
   // All registers are described further down
   
   reg [31:0] 		   period;
   reg [15:0] 		   p1width;
   reg [15:0] 		   delay;
   reg [15:0] 		   p2width;
   reg [15:0] 		   p1width2;
   reg [15:0] 		   p2width2;
   reg [15:0] 		   p1start2;
   reg [15:0] 		   p2start2;
   reg [15:0] 		   p2stop2;
   reg 		 		   cpmg;
   reg 			   block;
   reg 			   phase_sub; 			   
   reg 			   rx_done;
   
   reg [15:0] 		   p2start;
   reg [15:0] 		   sdown;
   reg [15:0] 		   sync_down;

   reg [7:0] 		   nutation_pulse_width;
   reg [15:0] 		   nutation_pulse_delay;
   reg [23:0] 		   nutation_pulse_start;
   reg [23:0] 		   nutation_pulse_stop;
   
   assign sync_on = sync; // The scope trigger pulse
   assign pulse1_on = pulse; // The channel 1 switch pulse
   assign pulse2_on = pulse2; // The channel 2 switch pulse
   assign pre_att = pre_att_val; // The main attenuator control
   assign pre_block = pr_inh; // The leakage blocking pulse

   
   //In order to improve timing on clk_pll, do everything possible on slower clk block
   always @(posedge clk) begin
      period  <= per; //Cycle repetition time
      p1width <= p1wid; //Width of channel 1 pulse 1
      p2width <= p2wid; //Width of channel 1 pulse 2
      p2width2 <= p2wid2; //Width of channel 2 pulse 2
      p1start2 <= p1st2; //Start offset of channel 2 pulse 1
      delay <= del; //Delay between channel 1 pulses
      nutation_pulse_delay <= nut_d; //Nutation pulse delay - ends this many cycles before new period starts
      nutation_pulse_width <= nut_w; //Width of nutation pulse
      cpmg <= cp; //CPMG settting: 0 for CW, 1 for Hahn echo
      block <= bl; //Toggle for which channel is on in CW mode
      
      //Calculate these values here, since they only change when their components are updated - better for timing
      p2start <= p1width + delay; //Start time of channel 1 pulse 2
      p1width2 <= p1wid2 + p1start2; //End time of channel 2 pulse 1
      p2start2 <= p1width2 + del2; //Start time of channel 2 pulse 2
      p2stop2 <= p2start2 + p2width2; //End time of channel 2 pulse 2
      sdown <= p2start + p2width; //End time of sync pulse and channel 1 pulse 2
      nutation_pulse_start <= per - nutation_pulse_delay - nutation_pulse_width; //Start time of nutation pulse
      nutation_pulse_stop <= per - nutation_pulse_delay; //End time of nutation pulse
      
   end
   
   /* The main loops runs on the 200 MHz PLL clock.
    */
   always @(posedge clk_pll) begin
	 //Calculate nutation pulse and regular pulses separately, then combine them later, to improve timing
	 //If nutation pulse is not needed, can just set its width to 0
	 sync <= (counter < sdown) ? 1 : 0;
	 case (cpmg)
	   0 : begin //cpmg=0 : CW (one switch always open)
	      pulse <= !block;
	      pulse2 <= block;
	      pr_inh <= 1;
	      pre_att_val <= pr_att;
	      
	   end
	   default : begin //cpmg > 1 : CPMG with # pulses given by value of cpmg

	      pulses <= (counter < p1width) ? 1 :// Switch pulse goes up before p1width
			((counter < p2start) ? 0 : //Then down (if cw mode not on) before p2start
			 ((counter < sdown) ? ((p2width > 0) ? 1 : 0) : 0));
	      
 	      nut_pulse <= (counter < nutation_pulse_start) ? 0 :
			   ((counter < nutation_pulse_stop) ? 1 : 0);

	      pulse2s <= (counter < p1start2) ? 0 :
      			 ((counter < p1width2) ? 1 :
      			  ((counter < p2start2) ? 0 :
      			   ((counter < p2stop2) ? 1 : 0)));

	      pre_att_val <= (counter < p1width | (counter > p1start2 && counter < p1width2)) ? pr_att+6 :
				 ((counter < (period-20)) ? pr_att : pr_att+6);
	      
	      pulse <= pulses;// | nut_pulse;
	      pulse2 <= pulse2s | nut_pulse;
	      pr_inh <= pulse | pulse2;
	   end
	 endcase
	 counter <= (counter < period) ? counter + 1 : 0; // Increment the counter until it reaches the period   

   end // always @ (posedge clk_pll)
endmodule // pulses
