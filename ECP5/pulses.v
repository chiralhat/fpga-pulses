module pulses(
	      /* This module sets up the output logic, including the pulse and block switches, the attenuator(s),
	       and the scope trigger. It needs to have two modes:

	       A CW mode, which holds both switches open, and outputs a trigger for the scope and the SynthHD.
	       This mode is chosen by setting the 'cpmg' input to 0.
	       Inputs are 'period', 'pre_att', and 'post_att'.

	       A pulsed mode, which opens the pulse switch to chop the pulses up, closes the block switch for
	       only the period after each pi pulse where we expect the echo to be (if blocking is on).
	       This mode is chosen by setting the 'cpmg' input to 1.
	       */
	      input 	   clk, //The 50 MHz clock
	      input 	   clk_pll, // The 200 MHz clock//TODO: Fix frequency
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
	      input        cp, //CPMG settting: 0 for CW, 1 for Hahn echo
	      input [7:0]  p_bl, //start of block open after pulses
	      input 	   bl,
	      input 	   rxd,
	      output 	   sync_on, // Wire for scope trigger pulse
	      output 	   pulse1_on, // Wire for switch pulse
	      output 	   pulse2_on, 
	      output [6:0] pre_att, // Wires for main attenuator
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
   reg 			   pr_inh;
   reg 			   inh;
   reg 			   rec = 0;
   reg 			   cw = 0;

   
   // Running at a 201-MHz clock, our time step is ~5 (4.975) ns.
   // All the times are thus divided by 4.975 ns to get cycles.
   // 32-bit allows times up to 21 seconds
   
   reg [31:0] 		   period = 10000;
   reg [15:0] 		   p1stop;
   reg [15:0] 		   delay;
   reg [15:0] 		   p2stop;
   reg [15:0] 		   p1stop2;
   reg [15:0] 		   p2stop2;
   //reg [15:0] 		   p1start2;
   reg [15:0] 		   delay2;
   reg [15:0] 		   p2stop2;
   reg      		   cpmg;
   reg 			   block;		   
   reg 			   rx_done;
   
   reg [15:0] 		   p2start;
   reg [15:0] 		   block_off;

   reg [7:0] 		   nutation_pulse_width;
   reg [15:0] 		   nutation_pulse_delay;
   reg [23:0] 		   nutation_pulse_start;
   reg [23:0] 		   nutation_pulse_stop;

   reg [1:0] 		   xfer_bits = 1;
   
   assign sync_on = sync; // The scope trigger pulse
   assign pulse1_on = pulse; // The switch pulse
   assign pulse2_on = pulse2; // The switch pulse
   assign pre_att = pre_att_val; // The main attenuator control
   assign pre_block = pr_inh; // The input blocking pulse (to completely squelch leakage)
   assign inhib = inh; // The blocking switch pulse

   
   //In order to improve timing on clk_pll, do everything possible on slower clk block
   //Since clk is 50 MHz and clk_pll is 200 MHz (even multiple), hopefully should reduce problems with two blocks being out of sync
   // Currently rewriting the logic to make all the additions happen in Python
   // That should reduce the timing burden in the FPGA, and allow for a higher
   // clock, I think. It will also make CPMG much more difficult, so this is
   // only for the no_CPMG branch
   always @(posedge clk) begin
      period  <= per;
      p1stop <= p1wid;
      p2stop <= p2wid;
      //p1start2 <= p1st2;
      p1stop2 <= p1wid2;
      delay2 <= del2;
      p2stop2 <= p2wid2;
      delay <= del;
      nutation_pulse_delay <= nut_d;
      nutation_pulse_width <= nut_w;
      cpmg <= cp;
      block <= bl;

      block_off <= p2stop + p_bl;
      nutation_pulse_start <= per - nutation_pulse_delay - nutation_pulse_width;
      nutation_pulse_stop <= per - nutation_pulse_delay;
      
   end
   
   /* The main loops runs on the 200 MHz PLL clock.
    */
   always @(posedge clk_pll) begin
//      if (!reset) begin
	 //Calculate nutation pulse and regular pulses separately, then combine them later, to improve timing
	 //If nutation pulse is not needed, can just set its width to 0
      sync <= (counter < p2stop) ? 1 : 0;
	 case (cpmg)
	   0 : begin //cpmg=0 : CW (switch always open)
	      pulse <= !block;
	      pulse2 <= block;
	      inh <= 0;
	      pr_inh <= 1;
	      pre_att_val <= pr_att;
	      
	   end

	      
	   default : begin //cpmg > 1 : CPMG with # pulses given by value of cpmg
	      pulses <= (counter < p1stop) ? 1 :// Switch pulse goes up before p1stop
				((counter < delay) ? 0 : //Then down before p2start
			 		((counter < p2stop) ? 1 : 0)); //Then up before p2stop
	      
 	      inh <= (counter < block_off) ? block :
		     	((counter < (nutation_pulse_start-5)) ? 0 : block);
	      
 	      nut_pulse <= (counter < nutation_pulse_start) ? 0 :
			   ((counter < nutation_pulse_stop) ? 1 : 0);

	      pulse2s <= (counter < p1stop2) ? 1 :
      			  ((counter < delay2) ? 0 :
      			   ((counter < p2stop2) ? 1 : 0));

	      pre_att_val <= (counter < p1stop | (counter > p1start2 && counter < p1stop2)) ? pr_att+6 :
				 ((counter < (period-20)) ? pr_att : pr_att+6);
	      
	      pulse <= pulses;// | nut_pulse;
	      pulse2 <= pulse2s | nut_pulse;
	      pr_inh <= pulse | pulse2;
	   end
	 endcase
	 counter <= (counter < period) ? counter + 1 : 0; // Increment the counter until it reaches the period
//      end //if (!reset)
//      else begin
//	 counter <= 0;
//      end		   

   end // always @ (posedge clk_pll)
endmodule // pulses
