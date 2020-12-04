`default_nettype none
module pulse_gen(
		 input 	clk, // 12 MHz base clock
		 input 	RS232_Rx, // Receive pin for the FTDI chip
		 // input 	resetn, // Reset the cycle
		 output RS232_Tx, // Transmit pin for the FTDI chip
		 output Pulse, // Output pin for the switch
		 output Sync, // Output pin for the SYNC pulse
		 //  output FM, // Output pin for the FM pulse
		 output Block
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

   wire [23:0] 		period;
   wire [15:0] 		p1width;
   wire [15:0] 		delay;
   wire [15:0] 		p2width;
   wire 		block;
   wire [7:0] 		pulse_block;
   //    wire [15:0] 		pulse_block_off;
   wire 		cpmg;
   wire 		rx_done;
   
   //    wire [6:0] 		pre_att;
   //    wire [6:0] 		post_att;

   // NOSIM_START
   wire 		clk_pll;
   wire 		clk_pll_gl;
   wire 		lock;

   // Setting the PLL to output a 100.5 MHz clock, based on code from
   // https://gist.github.com/thoughtpolice/8ec923e1b3fc4bb12c11aa23b4dc53b5#file-ice40-v
   // Note: These values are slightly different from those outputted by icepll
   //    icepll pll(
   // 	      .REFERENCECLK(clk),
   //               .PLLOUTCORE(clk_pll),
   //               .PLLOUTGLOBAL(clk_pll_gl),
   //               .RESET(!resetn),
   // 	      .LOCK(lock)
   // 	      );
   pll icepll(
	      .clock_in(clk),
              .clock_out(clk_pll),
	      .locked(lock)
	      );
   // NOSIM_END

   // Setting up communications with LabView over USB
   pulse_control control(
   			 .clk(clk),
   			 .RS232_Rx(RS232_Rx),
   			 .RS232_Tx(RS232_Tx),
   			 .per(period),
   			 .p1wid(p1width),
   			 .del(delay),
   			 .p2wid(p2width),
   			 //  .pr_att(pre_att),
   			 //  .po_att(post_att),
			 .cp(cpmg),
			 //  .p_bl(pulse_block),
			 //  .p_bl_off(pulse_block_off),
			 .bl(block),
			 .rxd(rx_done)
   			 );
   
   // Generating the necessary pulses
   pulses pulses(
		 .clk_pll(clk_pll),
		 .clk(clk),
		 // .reset(resetn),
		 .per(period),
		 .p1wid(p1width),
		 .del(delay),
		 .p2wid(p2width),
		 //  .pr_att(pre_att),
		 //  .po_att(post_att),
		 .cp(cpmg),
		 // .p_bl(pulse_block),
		 // .p_bl_off(pulse_block_off),
		 .bl(block),
		 .rxd(rx_done),
		 .sync_on(Sync),
		 .pulse_on(Pulse),
		 //  .Att1({J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10}),
		 //  .Att3({J4_9, J4_8, J4_7, J4_6, J4_5, J4_4, J4_3}),
		 .inhib(Block)
		 //  .test({FM, P3, P4})
		 );

endmodule // pulse_gen
