`default_nettype none
  module pulse_gen_sim(
		       input  clk,
		       input  clk_pll,
		       input  P1,
		       input  reset,
		       output Pulse, // Output pin for the switch
		       output Sync, // Output pin for the SYNC pulse
		       output FM, // Output pin for the FM pulse
		       // output P1,
		       output P2,
		       output P3,
		       output P4,
		       output Att1,
		       output Att3
		       );

   reg 			      resetn = 0;
   reg [31:0] 		    period;
   reg [31:0] 		    p1width;
   reg [31:0] 		    p2width;
   reg [31:0] 		    delay;
   reg [31:0] 		    p2start;
   reg [31:0] 		    pbwidth;
   reg [31:0] 		    sync_up;
   reg [31:0] 		    att_down;
   reg [15:0] 		    offres_input;
   reg [22:0] 		    offres_test;
   reg [31:0] 		    offres_delay;
   reg 			    pump;
   reg 			    double;
   reg [7:0] 		    pulse_block;
   reg 			    block;
   reg [7:0] 		    cpmg;
   
   reg [6:0] 		    pp_pump;
   reg [6:0] 		    pp_probe;
   reg [6:0] 		    post_att;

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
		 .offres_delay(offres_delay),
		 .delay(delay),
		 .double(double),
		 .pulse_block(pulse_block),
		 .block(block),
//		 .cpmg(cpmg),
		 .sync_on(Sync),
		 .pulse_on(Pulse),
		 .Att1(Att1),
		 .Att3(Att3),
		 .inhib(P2),
		 .pump_on(0),
		 .record_start(P3)
		 );
   
   parameter att_on_val = 7'b1111111;
   parameter att_off_val = 7'b0000000;
   parameter stperiod = 32'd20000; // 1 ms period
   parameter stp1width = 32'd30; // 150 ns
   parameter stp2width = 32'd60;
   parameter stdelay = 32'd200; // 1 us delay
   parameter stp2start = stp1width + stdelay;
   parameter stsync_up = stp2start + stp2width;
   parameter att_delay = 32'd2000;
   parameter statt_down = stsync_up + att_delay;
   parameter stpump = 1; // The pump is on by default

   // Initialize pulse values
   always @(posedge clk) begin
      if (reset) begin
	 period = stperiod;
    	 p1width = stp1width;
    	 p2width = stp2width;
	 pbwidth = stp1width;
    	 delay = stdelay;
    	 p2start = stp2start;
    	 sync_up = stsync_up;
    	 att_down = statt_down;
    	 pump = stpump;
    	 double = 1;
	 pulse_block = 8'd50;
	 block = 1;
	 cpmg = 0;
    	 pp_pump = att_off_val;
    	 pp_probe = att_on_val;
    	 post_att = att_on_val;
	 offres_input = 32'd500;
	 offres_delay = stperiod - offres_input - stp1width;
	 resetn = 1;
      end // if (reset)
   end // always @ (posedge clk)
   
endmodule // pulse_gen_sim
