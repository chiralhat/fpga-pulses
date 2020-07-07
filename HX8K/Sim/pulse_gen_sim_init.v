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
