`default_nettype none
  module pulse_gen(
		     input  clk, // 12 MHz base clock
		     input  RS232_Rx, // Receive pin for the FTDI chip
		     input P1,
		     output RS232_Tx, // Transmit pin for the FTDI chip
		     output Pulse, // Output pin for the switch
		     output Sync, // Output pin for the SYNC pulse
		     output FM, // Output pin for the FM pulse
//		     output P1,
		     output P2,
		     output P3,
		     output P4,
		     output J1_4,
		     output J1_5,
		     output J1_6,
		     output J1_7,
		     output J1_8,
		     output J1_9,
		     output J1_10,
//		     output Att1,
		     output J4_3,
		     output J4_4,
		     output J4_5,
		     output J4_6,
		     output J4_7,
		     output J4_8,
		     output J4_9
		     );

   wire 		    clk_pll;
   wire 		    lock;

   wire [31:0] 		    period;
   wire [31:0] 		    p1width;
   wire [31:0] 		    p2width;
   wire [31:0] 		    pbwidth;
   wire [31:0] 		    delay;
   wire [31:0] 		    p2start;
   wire [31:0] 		    sync_up;
   wire [31:0] 		    att_down;
   wire [31:0] 		    offres_delay;
   wire 			    pump;
   wire 			    double;
   wire 			    block;
   wire [7:0] 		    pulse_block;
   
   wire [6:0] 		    pp_pump;
   wire [6:0] 		    pp_probe;
   wire [6:0] 		    post_att;

   reg 			    resetn = 1;
   
   // Setting the PLL to output a 200 MHz clock, based on code from
   // https://gist.github.com/thoughtpolice/8ec923e1b3fc4bb12c11aa23b4dc53b5#file-ice40-v
   // Note: These values are slightly different from those outputted by icepll
   icepll pll(
	      .clk(clk),
	      .clkout(clk_pll),
	      .locked(lock)
	      );

   // Generating the necessary pulses
   pulses pulses(
		 .clk_pll(clk_pll),
		 .resetn(resetn),
		 .pump(pump),
		 .period(period),
		 .sync_up(sync_up),
		 .p1width(p1width),
		 .p2start(p2start),
		 .p2width(p2width),
		 .pbwidth(pbwidth),
		 .att_down(att_down),
		 .pp_pump(pp_pump),
		 .pp_probe(pp_probe),
		 .post_att(post_att),
		 .delay(delay),
		 .offres_delay(offres_delay),
		 .double(double),
		 .pulse_block(pulse_block),
		 .block(block),
		 .sync_on(Sync),
		 .pulse_on(Pulse),
		 .Att1({J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10}),
		 .Att3({J4_9, J4_8, J4_7, J4_6, J4_5, J4_4, J4_3}),
		 .inhib(P2),
		 .pump_on(P1),
		 .record_start(P3)
		 );

   // Setting up communications with LabView over USB
   pulse_control control(
   			 .clk(clk),
   			 .RS232_Rx(RS232_Rx),
   			 .RS232_Tx(RS232_Tx),
   			 .del(delay),
   			 .per(period),
   			 .s_up(sync_up),
   			 .p1wid(p1width),
   			 .p2st(p2start),
   			 .p2wid(p2width),
			 .pbwid(pbwidth),
   			 .att_d(att_down),
			 .offr_d(offres_delay),
   			 .pp_pu(pp_pump),
   			 .pp_pr(pp_probe),
   			 .pu(pump),
   			 .doub(double),
   			 .p_att(post_att),
			 .p_bl(pulse_block),
			 .bl(block)
   			 );
   
endmodule // pulse_gen
