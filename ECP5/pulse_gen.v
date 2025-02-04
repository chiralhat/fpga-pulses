`default_nettype none
module pulse_gen(
		 input 	      clk_uart, 
		 input 	      RS232_Rx, // Receive pin for the FTDI chip
		 input 	      resetn, // Reset the cycle
		 output [7:0] led,
		 output       RS232_Tx, // Transmit pin for the FTDI chip
		 output       Pulse, // Output pin for the switch
		 output       Pulse2, // Output pin for the second pulse switch
		 output       Sync, // Output pin for the SYNC pulse
		 output       Pre_Block, 
		 output       Block,
		 output       recv,
		 output [6:0] pre_att,
		 output [6:0] post_att,
		 output       Phase_90,
		 output       Phase_180       
		 );

   wire [31:0] 		      period;
   wire [15:0] 		      p1width;
   wire [15:0] 		      delay;
   wire [15:0] 		      p2width;
   wire [15:0] 		      p1start2;
   wire [15:0] 		      p1width2;
   wire [15:0] 		      delay2;
   wire [15:0] 		      p2width2;
   wire [15:0] 		      nut_del;
   wire [7:0] 		      nut_wid;
   wire 		      block;
   wire [7:0] 		      pulse_block;
   wire [15:0] 		      pulse_block_half;
   wire [7:0] 		      cpmg;
   wire 		      rx_done;
   wire 		      phase_sub;
   
   wire [6:0] 		      pre_att_val;
   wire [6:0] 		      post_att_val;

   // NOSIM_START
   wire 		      clk_pll;
   wire 		      clk_pll_gl;
   wire 		      lock;

   // Setting the PLL to output a 201 MHz clock, based on code from
   // https://gist.github.com/thoughtpolice/8ec923e1b3fc4bb12c11aa23b4dc53b5#file-ice40-v
   // Note: These values are slightly different from those outputted by icepll
   
   pll ecppll(
	      .clkin(clk_uart),
              .clkout0(clk_pll),
	      .locked(lock)
	      );
   // NOSIM_END
   // Setting up communications with LabView over USB
   pulse_control control(
			 .clk(clk_uart),
			 .RS232_Rx(RS232_Rx),
			 .RS232_Tx(RS232_Tx),
			 .per(period),
			 .p1wid(p1width),
			 .del(delay),
			 .p2wid(p2width),
   			 .p1wid2(p1width2),
   			 .del2(delay2),
   			 .p2wid2(p2width2),
			 .p1st2(p1start2),
			 .nut_d(nut_del),
			 .nut_w(nut_wid),
			 .pr_att(pre_att_val),
			 .po_att(post_att_val),
			 .cp(cpmg),
			 .p_bl(pulse_block),
			 .p_bl_hf(pulse_block_half),
			 .bl(block),
			 .rxd(rx_done),
			 .led(led),
			 .recv(recv),
			 .phsub(phase_sub)
			 );
   
   // Generating the necessary pulses
   pulses pulses(
		 .clk(clk_uart),
		 .clk_pll(clk_pll),
		 .reset(resetn),
		 .per(period),
		 .p1wid(p1width),
		 .del(delay),
		 .p2wid(p2width),
   		 .p1wid2(p1width2),
   		 .del2(delay2),
   		 .p2wid2(p2width2),
		 .p1st2(p1start2),
		 .nut_d(nut_del),
		 .nut_w(nut_wid),
		 .pr_att(pre_att_val),
		 .po_att(post_att_val),
		 .cp(cpmg),
		 .p_bl(pulse_block),
		 .p_bl_hf(pulse_block_half),
		 .bl(block),
		 .rxd(rx_done),
		 .sync_on(Sync),
		 .pulse1_on(Pulse),
		 .pulse2_on(Pulse2),
		 .pre_att(pre_att),
		 .post_att(post_att),
		 //		 .led(led),
		 .pre_block(Pre_Block),
		 .inhib(Block),
		 .phsub(phase_sub),
		 .phase90(Phase_90),
		 .phase180(Phase_180)
		 //  .test({FM, P3, P4})
		 );
   // NOSIM2_START
endmodule // pulse_gen
