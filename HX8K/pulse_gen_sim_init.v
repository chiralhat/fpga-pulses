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
      if (resetn) begin
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
//	 cpmg = 0;
    	 pp_pump = att_off_val;
    	 pp_probe = att_on_val;
    	 post_att = att_on_val;
//	 offres_input = 32'd500;
//	 offres_delay = stperiod - offres_input - stp1width;
	 offres_delay = stperiod - 32'd500 - stp1width;
      end // if (reset)
   end // always @ (posedge clk)

endmodule // pulse_gen_sim
