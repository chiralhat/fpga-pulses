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
	      input 	   clk_pll, // The PLL clock
	      input 	   clk, // The 12 MHz clock
	      // input 	   reset, // Used only in simulation
	      input [23:0]  per, // TODO: restore full 32-bit nature
	      input [15:0] p1wid,
	      input [15:0] del,
	      input [15:0] p2wid,
	      // input [6:0]  pr_att,
              //       input [6:0]  po_att,
              input 	   cp,
              //  input [7:0]  p_bl,
              //  input [15:0] p_bl_off,
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
	      output 	   pulse_on, // Wire for switch pulse
	      //   output [6:0] Att1, // Wires for main attenuator
	      //   output [6:0] Att3, // Wires for second attenuator
	      output 	   inhib // Wire for blocking switch pulse
	      );

   reg [31:0] 		   counter = 0; // 32-bit for times up to 21 seconds
   reg 			   sync;
   reg 			   pulse;
   //    reg [6:0] 		   A1;
   //    reg [6:0] 		   A3;
   reg 			   inh;
   reg 			   rec = 0;
   reg 			   cw = 0; 			   
   
   // Running at a 101.5-MHz clock, our time step is ~10 (9.95) ns.
   // All these numbers are thus multiplied by 9.95 ns to get times.
   // 24-bit allows periods up to 170 ms
   parameter stperiod = 100500 >> 8; // 1 is a 0.652 ms period
   // parameter stp1width = 30; // 298.5 ns
   // parameter stp2width = 30;
   // parameter stdelay = 200; // 1.99 us delay
   // //    parameter stblock = 100; // 500 ns block open
   // parameter stcpmg = 1; // Do Hahn echo by default
   
   // reg [31:0] 		   period = stperiod;
   // reg [15:0] 		   p1width = stp1width;
   // reg [15:0] 		   delay = stdelay;
   // reg [15:0] 		   p2width = stp2width;
   // reg [7:0] 		   pulse_block = 8'd50;
   // //    reg [15:0] 			   pulse_block_off = stblock;
   // reg 			   cpmg = stcpmg;
   // reg 			   block = 1;
   // reg 			   rx_done = 0;

   // reg [15:0] 		   p2start = stp1width+stdelay;
   // reg [15:0] 		   sync_down = stp1width+stdelay+stp2width;
   // reg [15:0] 		   block_off = stp1width+2*stdelay+stp2width-8'd50;
   //    reg [15:0] block_on = stp1width+2*stdelay+stp2width-8'd50+stblock;

   reg [23:0] 		   period = stperiod;
   reg [15:0] 		   p1width;
   reg [15:0] 		   delay;
   reg [15:0] 		   p2width;
   reg 			   cpmg;
   reg 			   block;
   reg [7:0] 		   pulse_block = 8'd50;
   reg 			   rx_done;
   reg [15:0] 		   p2start;
   reg [23:0] 		   sync_down;
   reg [15:0] 		   block_off;

   // reg  		nutation_pulse = 0;
   // reg [31:0]  nutation_pulse_width = 32'd50;
   // reg [31:0]  nutation_pulse_delay = 32'd300;
   // reg [31:0]  nutation_pulse_start;
   // reg [31:0]  nutation_pulse_stop;

   // reg [1:0] 		   xfer_bits = 0;
   
   assign sync_on = sync; // The scope trigger pulse
   assign pulse_on = pulse; // The switch pulse
   //    assign Att1 = A1; // The main attenuator control
   //    assign Att3 = A3; // The second attenuator control
   assign inhib = inh; // The blocking switch pulse
   // assign inhib = ccount[1];

   // parameter FIRST_PULSE_ON = 4'd0;
   // parameter FIRST_DELAY = 4'd1;
   // parameter SECOND_PULSE_ON = 4'd2;
   // parameter POST_PI_PULSE = 4'd3;
   // parameter FIRST_BLOCK_OFF = 4'd4;
   // parameter FIRST_BLOCK_ON = 4'd5;
   // parameter CPMG_PULSE_ON = 4'd6;
   // parameter POST_CPMG_PULSE = 4'd7;
   // parameter CPMG_BLOCK_OFF = 4'd8;
   // parameter CPMG_BLOCK_ON = 4'd9;
   // parameter NUTATION_PULSE_ON = 4'd10;

   always @(posedge clk) begin
      // { rx_done, xfer_bits } <= { xfer_bits, rxd };

      // if (rx_done) begin

	 period <= per;
	 p1width <= p1wid;
	 p2width <= p2wid;
	 delay <= del;
	 cpmg <= cp;
	 block <= bl;

      // end
      // if (reset) begin
      // 	counter <= 0;
      // end
      p2start <= p1width + delay;
      sync_down <= (cpmg > 0) ? p2start + p2width : period << 7;
      block_off <= p2start + p2width + delay - pulse_block;

      cw <= (cpmg > 0) ? 0 : 1;
	 
   end

   /* The main loops runs on the 100.5 MHz PLL clock.
    */
   always @(posedge clk_pll) begin
      // if (!reset) begin
	 
	 
	 // if (cpmg > 0) begin
	    // block_on <= block_off + pulse_block_off;

	    // p2start <= p1width + delay;
	    // sync_down <= p2start + p2width;
	    // block_off <= sync_down + delay - pulse_block;

      case (counter)
	0: begin
	   pulse <= 1;
	   inh <= block;
	   sync <= 1;
	end

	p1width: begin
	   pulse <= cw;
	end

	p2start: begin
	   pulse <= 1;
	end

	sync_down: begin
	   pulse <= cw;
	   sync <= 0;
	end

	block_off: begin
	   inh <= 0;
	end
	
      endcase // case (counter)
      
	    
	    // pulse <= (counter < p1width) ? 1 : // Switch pulse goes up at 0 if the pump is on
      	    // 	     ((counter < p2start) ? cw : // then down after p1width
      	    // 	      ((counter < sync_down) ? 1 : cw));
	    
	    // // inh <= ((counter < block_off) || (counter > block_on)) ? block : 0; // Turn the blocking switch on except for a window after the second pulse.
	    // 	       inh <= (counter < (block_off)) ? block : 0; // Turn the blocking switch on except for a window after the second pulse.
	    
	    // sync <= (counter < sync_down) ? 1 : 0;
	    
	 // end // if (cpmg > 0)
      
	 // else begin
	 //    pulse <= 1;
	 //    inh <= 0;
	 //    sync <= (counter < (period >> 1)) ? 1 : 0;
	 // end // else: !if(cpmg > 0)
      
	 // sync <= (counter < sync_down) ? 1 : 0;
	 // counter <= ((counter < period) && !reset) ? counter + 1 : 0; // Increment the counter until it reaches the period
	 counter <= (counter < (period << 8)) ? counter + 1 : 0; // Increment the counter until it reaches the period
      // end // if (!reset)
      //   else begin
      //  counter <= 0;
      //   end

   end // always @ (posedge clk_pll)
endmodule // pulses
