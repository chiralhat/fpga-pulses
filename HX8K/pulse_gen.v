`default_nettype none
module pulse_gen(
		     input  clk, // 12 MHz base clock
		     input  RS232_Rx, // Receive pin for the FTDI chip
		     output RS232_Tx, // Transmit pin for the FTDI chip
		     output Pulse, // Output pin for the switch
		     output Sync, // Output pin for the SYNC pulse
		     output FM, // Output pin for the FM pulse
		     output P1,
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

   wire 		  clk_pll;
   wire 		  lock;
   
   // Setting the PLL to output a 200 MHz clock, based on code from
   // https://gist.github.com/thoughtpolice/8ec923e1b3fc4bb12c11aa23b4dc53b5#file-ice40-v
   // Note: These values are slightly different from those outputted by icepll
   icepll pll(
	      .clk(clk),
	      .clkout(clk_pll),
	      .locked(lock)
	      );
   
   // Control the pulses
   //  reg [2:0] 			pulses;
   reg 			    sync_on = 0;
   reg 			    pulse_on = 0;
   reg 			    fm_on = 0;
   reg 			    pp_on = 1;
   reg 			    inhib = 0;
   reg 			    p1_on = 0;
   reg 			    double = 0;
   
   // Control the attenuators
   parameter att_on_val = 7'b1111111;
   parameter att_off_val = 7'b0000000;
//   reg [6:0] 		    Att1 = att_on_val;
   reg [6:0] 		    Att3 = att_off_val;
   reg [6:0] 		    pp_pump = att_off_val;
   reg [6:0] 		    pp_probe = att_on_val;
   reg [6:0] 		    post_att = att_off_val;
   
   // Running at a 200-MHz clock, our time step is 5 ns.
   // All the times are thus divided by 5 ns to get cycles.
   // 32-bit allows times up to 21 seconds

   parameter stperiod = 32'd200000; // 1 ms period
   parameter stp1width = 32'd30; // 150 ns
   parameter stp2width = 32'd30;
   parameter stdelay = 32'd200; // 1 us delay
   parameter stp2start = stp1width + stdelay;
   parameter stsync_up = stp2start + stp2width;
   // The attenuator pulse switches down 10 us after the sync pulse,
   // because when it turns off there is a burst of noise, and this
   // moves that noise well after the signal
   parameter att_delay = 32'd20000;
   parameter statt_down = stsync_up + att_delay;
   parameter stpump = 1; // The pump is on by default
   
   reg [31:0] 		    period = stperiod;
   reg [31:0] 		    p1width = stp1width;
   reg [31:0] 		    p2width = stp2width;
   reg [31:0] 		    delay = stdelay;
   reg [31:0] 		    p2start = stp2start;
   reg [31:0] 		    sync_up = stsync_up;
   reg [31:0] 		    att_down = statt_down;
   reg 			    pump = stpump;
   

   
//   assign Sync = sync_on;//pulses[0];
//   assign Pulse = pulse_on;//pulses[1];
   assign FM = period[16];//fm_on;//pulses[2];
//   assign P1 = pump_on;
//   assign P2 = inhib;
//   assign P3 = counter[0];
//   assign P4 = clk_pll;
   
   //   assign J1_3 = Att1[7];
   // assign J1_4 = Att1[6];
   // assign J1_5 = Att1[5];
   // assign J1_6 = Att1[4];
   // assign J1_7 = Att1[3];
   // assign J1_8 = Att1[2];
   // assign J1_9 = Att1[1];
   // assign J1_10 = Att1[0];
   assign J4_3 = Att3[0];
   assign J4_4 = Att3[1];
   assign J4_5 = Att3[2];
   assign J4_6 = Att3[3];
   assign J4_7 = Att3[4];
   assign J4_8 = Att3[5];
   assign J4_9 = Att3[6];
   //   assign J4_10 = Att3[7];
   
   //   assign P1 = p1_on;
   

   pulses pulses(
		 .clk_pll(clk_pll),
		 .pump(pump),
		 .period(period),
		 .sync_up(sync_up),
		 .p1width(p1width),
		 .p2start(p2start),
		 .att_down(att_down),
		 .pp_pump(pp_pump),
		 .pp_probe(pp_probe),
		 .delay(delay),
		 .double(double),
		 .sync_on(Sync),
		 .pulse_on(Pulse),
		 .Att1({J1_4, J1_5, J1_6, J1_7, J1_8, J1_9, J1_10}),
		 // .J1_4(J1_4),
		 // .J1_5(J1_5),
		 // .J1_6(J1_6),
		 // .J1_7(J1_7),
		 // .J1_8(J1_8),
		 // .J1_9(J1_9),
		 // .J1_10(J1_10),
		 .inhib(P2),
		 .pump_on(P1),
		 .record_start(P3)
		 );
   
//    // The main loops runs on the 200 MHz PLL clock
//    always @(posedge clk_pll) begin
//       if (resetn) begin
// 	 counter <= (counter < period) ?
//       		    counter + 1 : 0;

// 	 sync_on <= (counter < sync_up) ? 1 : 0;
// 	 pulse_on <= (counter < p1width) ? pump_on : 
//       		     ((counter < p2start) ? 0 :
//       		      ((counter < sync_up) ? 1 : 0));
// 	 Att1 <= ((counter < (p1width + 1)) || (counter > att_down)) ? pp_pump : pp_probe;
// 	 inhib <= (counter < (sync_up + delay - 10)) ? 1 : ((counter > (sync_up + delay + 40)) ? 1 : 0);

// 	 if (counter == period)
// 	   pump_on <= !pump_on;
//       end // if (resetn)
//       else begin
// 	 counter = 0;
// 	 resetn = 1;
// //	 p1_on = 0;
// //	 inhib = 0;
//       end
//    end // always @ (posedge clk_pll)

   // Setup necessary for UART
   wire 		   reset = 0;
   reg 			   transmit;
   reg [7:0] 		   tx_byte;
   wire 		   received;
   wire [7:0] 		   rx_byte;
   wire 		   is_receiving;
   wire 		   is_transmitting;
   wire 		   recv_error;

   // UART module, from https://github.com/cyrozap/osdvu
   uart uart0(
	      .clk(clk),                    // The master clock for this module
	      .rst(reset),                      // Synchronous reset
	      .rx(RS232_Rx),                // Incoming serial line
	      .tx(RS232_Tx),                // Outgoing serial line
	      .transmit(transmit),              // Signal to transmit
	      .tx_byte(tx_byte),                // Byte to transmit
	      .received(received),              // Indicated that a byte has been received
	      .rx_byte(rx_byte),                // Byte received
	      .is_receiving(is_receiving),      // Low when receive line is idle
	      .is_transmitting(is_transmitting),// Low when transmit line is idle
	      .recv_error(recv_error)           // Indicates error in receiving packet.
	      );

   // input and output to be communicated
   reg [31:0] 		   vinput;  // input and output are reserved keywords
   reg [7:0] 		   vcontrol; // Control byte, the MSB (most significant byte) of the transmission
   reg [7:0] 		   voutput;
   reg [7:0] 		   vcheck; // Checksum byte; the input bytes are summed and sent back as output
   
   // We need to receive multiple bytes sequentially, so this sets up both
   // reading and writing. Adapted from the uart-adder from
   // https://github.com/cyrozap/iCEstick-UART-Demo/pull/3/files
   parameter read_A                 = 1'd0;
   parameter read_wait              = 1'd1;
   parameter write_A                = 1'd0;
   parameter write_done             = 1'd1;

   reg 			   writestate = write_A;
   reg [5:0] 		   writecount = 0;
   reg [1:0] 		   readstate = read_A;
   reg [5:0] 		   readcount = 0;

   parameter STATE_RECEIVING   = 2'd0;
   parameter STATE_CALCULATING = 2'd1;
   parameter STATE_SENDING     = 2'd2;

   // These set the behavior based on the control byte
   parameter CONT_SET_DELAY = 8'd0;
   parameter CONT_SET_PERIOD = 8'd1;
   parameter CONT_SET_PUMP = 8'd2;
   parameter CONT_SET_PROBE = 8'd3;
   parameter CONT_TOGGLE_PUMP = 8'd4;
   parameter CONT_SET_ATT = 8'd5;
   parameter CONT_READ_TEST = 8'd6;

   reg [2:0] 		   state = STATE_RECEIVING;

      // The communication runs at the 12 MHz clock rather than the 200 MHz clock.
   always @(posedge clk) begin
      
      case (state) 
	
        STATE_RECEIVING: begin
           transmit <= 0;
	   case (readstate)
	     read_A: begin
		if(received) begin
		   if(readcount == 6'd32) begin // Last byte in the transmission
		      vcontrol <= rx_byte;
		      state<=STATE_CALCULATING;
		      readcount <= 0;
		      readstate <= read_A;
		   end
		   else begin // Read the first bytes into vinput
		      vinput[readcount +: 8]=rx_byte;
		      readcount = readcount + 8;
		      readstate <= read_wait;
		   end
		end
	     end // case: read_A

	     read_wait: begin // Wait for the next byte to arrive
		if(~received) begin
		   readstate <= read_A;
		end
	     end
	   endcase // case (readstate)
	end // case: STATE_RECEIVING

	// Based on the control byte, assign a new value to the desired pulse parameter
        STATE_CALCULATING: begin
           writestate   <= write_A;
	   vcheck = vinput[31:24] + vinput[23:16] + vinput[15:8] + vinput[7:0];
	   case (vcontrol)

	     CONT_SET_DELAY: begin
		delay <= vinput;
		voutput <= vcheck;
	     end

	     CONT_SET_PERIOD: begin
		period <= vinput;
		voutput <= vcheck;
	     end

	     CONT_SET_PUMP: begin
		p1width <= vinput;
	     end

	     CONT_SET_PROBE: begin
		p2width <= vinput;
		voutput <= vcheck;
	     end

	     CONT_TOGGLE_PUMP: begin
		pump <= vinput[0];
		double <= vinput[1];
		voutput <= vcheck;
	     end

	     CONT_SET_ATT: begin
		pp_probe <= vinput[7:0];
//		Att1 <= vinput[7:0];
//		Att3 <= vinput[15:8];
		post_att <= vinput[15:8];
		pp_pump <= vinput[23:16];
		pp_on <= vinput[24];
		voutput <= vcheck;
	     end

	     CONT_READ_TEST: begin
		voutput <= vcheck;
	     end
	     
	   endcase // case (vcontrol)
//           state <= STATE_SENDING;
           state <= STATE_RECEIVING;
        end

        /*
	 * STATE_SENDING: begin


           case (writestate)

	     write_A: begin
		if (~ is_transmitting) begin
                   transmit <= 1;
		   writestate  <= write_done;
                   tx_byte <= voutput;
                   state     <= STATE_SENDING;
		end
	     end

	     write_done: begin
		if (~ is_transmitting) begin
                   writestate <= write_A; 
                   state     <= STATE_RECEIVING;
                   transmit <= 0;
		end
	     end

           endcase

        end
	 */

        default: begin
           // should not be reached
           state     <= STATE_RECEIVING;
           readcount <= read_A;
        end

      endcase // case (state)

      // After each change, update the pulse parameters
      p2start <= p1width + delay;
      sync_up <= p2start + p2width;   
      att_down <= sync_up + att_delay;
      Att3 <= post_att;

    end // always @ (posedge iCE_CLK)
   
endmodule // pump_probe
