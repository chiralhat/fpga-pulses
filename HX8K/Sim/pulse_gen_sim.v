`default_nettype none
module pulse_gen(
		 input 	clk, // 12 MHz base clock
input clk_pll,
		 input 	RS232_Rx, // Receive pin for the FTDI chip
		 input 	resetn, // Reset the cycle
		 output RS232_Tx, // Transmit pin for the FTDI chip
		 output Pulse, // Output pin for the switch
		 output Sync, // Output pin for the SYNC pulse
		//  output FM, // Output pin for the FM pulse
		 output P2
		//  output P3,
		//  output P4,
		//  output J1_4,
		//  output J1_5,
		//  output J1_6,
		//  output J1_7,
		//  output J1_8,
		//  output J1_9,
		//  output J1_10,
		//  output J4_3,
		//  output J4_4,
		//  output J4_5,
		//  output J4_6,
		//  output J4_7,
		//  output J4_8,
		//  output J4_9
		 );

   reg [7:0] 		period;
   reg [15:0] 		p1width;
   reg [15:0] 		delay;
   reg [15:0] 		p2width;
//    reg 		pump;
   reg 		block;
   reg [7:0] 		pulse_block;
//    reg [15:0] 		pulse_block_off;
   reg 	 		cpmg;
   reg				rx_done;
   
//    reg [6:0] 		pre_att;
//    reg [6:0] 		post_att;

   
   // Generating the necessary pulses
   pulses pulses(
		 .clk_pll(clk_pll),
		 .reset(resetn),
		//  .pu(pump),
		.per(period),
		.p1wid(p1width),
		.del(delay),
		.p2wid(p2width),
	//  .pr_att(pre_att),
	//  .po_att(post_att),
		.cp(cpmg),
		.p_bl(pulse_block),
		// .p_bl_off(pulse_block_off),
		.bl(block),
		 .rxd(rx_done),
		 .sync_on(Sync),
		 .pulse_on(Pulse),
		//  .Att1({J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10}),
		//  .Att3({J4_9, J4_8, J4_7, J4_6, J4_5, J4_4, J4_3}),
		 .inhib(P2)
		//  .test({FM, P3, P4})
		 );
   // NOSIM2_START
   parameter att_on_val = 7'b1111111;
   parameter att_off_val = 7'b0000000;
   parameter stperiod = 1; // 1 ms period
   parameter stp1width = 30; // 150 ns
   parameter stp2width = 30;
   parameter stdelay = 200; // 1 us delay
   parameter stpump = 1; // The pump is on by default
   parameter stcpmg = 1; // Do Hahn echo by default
   parameter stblock = 50;
   parameter stblockoff = 100;

   // Initialize pulse values
   always @(posedge clk) begin
      if (resetn) begin
    	 // pump = stpump;
	 period = stperiod;
    	 p1width = stp1width;
    	 delay = stdelay;
    	 p2width = stp2width;
	 pulse_block = stblock;
	 // pulse_block_off = stblockoff;
	 block = 1;
	 cpmg = stcpmg;
      end // if (reset)
   end // always @ (posedge clk)

endmodule // pulse_gen_sim
