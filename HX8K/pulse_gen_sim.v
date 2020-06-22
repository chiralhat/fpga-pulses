`default_nettype none
module pulse_gen(
		 input 	clk, // 12 MHz base clock
input clk_pll,
		 input 	RS232_Rx, // Receive pin for the FTDI chip
		 input 	resetn, // Reset the cycle
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

   reg [31:0] 		period;
   //   reg [31:0] 		sync_up;
   reg [31:0] 		p1width;
   reg [31:0] 		delay;
   reg [31:0] 		p2width;
   //   reg [31:0] 		pbwidth;
   //   reg [31:0] 		p2start;
   //   reg [31:0] 		att_down;
   //   reg [31:0] 		offres_delay;
   reg 		pump;
   //   reg 		double;
   reg 		block;
   reg [7:0] 		pulse_block;
   reg [15:0] 		pulse_block_off;
   reg [7:0] 		cpmg;
   
   //   reg [6:0] 		pp_pump;
   //   reg [6:0] 		pp_probe;
   reg [6:0] 		pre_att;
   reg [6:0] 		post_att;

   
   // Generating the necessary pulses
   pulses pulses(
		 .clk_pll(clk_pll),
		 .reset(resetn),
		 .pump(pump),
		 .period(period),
		 .p1width(p1width),
		 .delay(delay),
		 .p2width(p2width),
		 .pre_att(pre_att),
		 .post_att(post_att),
		 .pulse_block(pulse_block),
		 .pulse_block_off(pulse_block_off),
		 .cpmg(cpmg),
		 .block(block),
		 .sync_on(Sync),
		 .pulse_on(Pulse),
		 .Att1({J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10}),
		 .Att3({J4_9, J4_8, J4_7, J4_6, J4_5, J4_4, J4_3}),
		 .inhib(P2)
		 //		 .sync_up(sync_up),
		 //		 .p2start(p2start),
		 //		 .pbwidth(pbwidth),
		 //		 .att_down(att_down),
		 //		 .pp_pump(pp_pump),
		 //		 .pp_probe(pp_probe),
		 //		 .offres_delay(offres_delay),
		 //		 .double(double),
		 //		 .pump_on(P1),
		 //		 .record_start(P3)
		 );
   // NOSIM2_START
   parameter att_on_val = 7'b1111111;
   parameter att_off_val = 7'b0000000;
   parameter stpump = 1; // The pump is on by default
   parameter stperiod = 32'd20000; // 1 ms period
   parameter stp1width = 32'd30; // 150 ns
   parameter stdelay = 32'd200; // 1 us delay
   parameter stp2width = 32'd60;
   parameter stblock = 8'd50;
   parameter stblockoff = 16'd100;
   parameter stcpmg = 8'd10;

   // Initialize pulse values
   always @(posedge clk) begin
      if (resetn) begin
    	 pump = stpump;
	 period = stperiod;
    	 p1width = stp1width;
    	 delay = stdelay;
    	 p2width = stp2width;
	 pulse_block = stblock;
	 pulse_block_off = stblockoff;
	 block = 1;
	 cpmg = stcpmg;
    	 pre_att = att_off_val;
    	 post_att = att_on_val;
      end // if (reset)
   end // always @ (posedge clk)

endmodule // pulse_gen_sim
