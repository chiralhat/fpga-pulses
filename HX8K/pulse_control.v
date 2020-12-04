`default_nettype none
module pulse_control(
		     input 	   clk,
		     input 	   RS232_Rx,
		     output 	   RS232_Tx,
		     output [23:0] per,
		     output [15:0] p1wid,
		     output [15:0] del,
		     output [15:0] p2wid,
		     // output [6:0]  pr_att,
               //       output [6:0]  po_att,
                     output         cp,
                    //  output [7:0]  p_bl,
                    //  output [15:0] p_bl_off,
		     output 	   bl,
			 output			rxd
		     );

   // Control the pulses

   // Running at a 101.5-MHz clock, our time step is ~10 (9.95) ns.
   // All these numbers are thus multiplied by 9.95 ns to get times.
   // 32-bit allows periods up to 170 ms
   parameter stperiod = 100500 >> 8; // a 1 ms period
   parameter stp1width = 30; // 298.5 ns
   parameter stp2width = 60;
   parameter stdelay = 200; // 1.99 us delay
//    parameter stblock = 100; // 500 ns block open
   parameter stcpmg = 1; // Do Hahn echo by default
   
   reg [23:0] 			   period = stperiod;
   reg [15:0] 			   p1width = stp1width;
   reg [15:0] 			   delay = stdelay;
   reg [15:0] 			   p2width = stp2width;
   reg     			   cpmg = stcpmg;
   reg 				   block = 1;
   reg 					rx_done = 0;
   
//    reg 				   pump;
//    reg [7:0] 			   period;
//    reg [15:0] 			   p1width;
//    reg [15:0] 			   delay;
//    reg [15:0] 			   p2width;
//    reg     			   cpmg;
//    reg 				   block;
//    reg 					rx_done;
   
   // Control the attenuators
//    parameter att_pre_val = 7'd1;
//    parameter att_post_val = 7'd0;
//    reg [6:0] 			   pre_att = att_pre_val;
//    reg [6:0] 			   post_att = att_post_val;

   assign per = period;
   assign p1wid = p1width;
   assign p2wid = p2width;
   assign del = delay;
//    assign pr_att = pre_att;
//    assign po_att = post_att;
   assign cp = cpmg;
//    assign p_bl = pulse_block;
//    assign p_bl_off = pulse_block_off;
   assign bl = block;
   assign rxd = rx_done;
   
   // Setup necessary for UART
   wire 			   reset = 0;
   reg 				   transmit;
   reg [7:0] 			   tx_byte;
   wire 			   received;
   wire [7:0] 			   rx_byte;
   wire 			   is_receiving;
   wire 			   is_transmitting;
   wire 			   recv_error;

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
   reg [31:0] 			   vinput;  // input and output are reserved keywords
   reg [7:0] 			   vcontrol; // Control byte, the MSB (most significant byte) of the transmission
   reg [7:0] 			   voutput;
   reg [7:0] 			   vcheck; // Checksum byte; the input bytes are summed and sent back as output
   
   // We need to receive multiple bytes sequentially, so this sets up both
   // reading and writing. Adapted from the uart-adder from
   // https://github.com/cyrozap/iCEstick-UART-Demo/pull/3/files
   parameter read_A                 = 1'd0;
   parameter read_wait              = 1'd1;
   parameter write_A                = 1'd0;
   parameter write_done             = 1'd1;

   reg 				   writestate = write_A;
   reg [5:0] 			   writecount = 0;
   reg [1:0] 			   readstate = read_A;
   reg [5:0] 			   readcount = 0;

   parameter STATE_RECEIVING   = 2'd0;
   parameter STATE_CALCULATING = 2'd1;
   parameter STATE_SENDING     = 2'd2;

   // These set the behavior based on the control byte
   parameter CONT_SET_DELAY = 8'd0;
   parameter CONT_SET_PERIOD = 8'd1;
   parameter CONT_SET_PULSE1 = 8'd2;
   parameter CONT_SET_PULSE2 = 8'd3;
   parameter CONT_TOGGLE_PULSE1 = 8'd4;
   parameter CONT_SET_CPMG = 8'd5;
   parameter CONT_SET_ATT = 8'd6;

   reg [2:0] 			   state = STATE_RECEIVING;

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
		      readcount <= readcount + 8;
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
	   voutput = vinput[31:24] + vinput[23:16] + vinput[15:8] + vinput[7:0];
	   case (vcontrol)

	     CONT_SET_DELAY: begin
		delay <= vinput[15:0];
	     end

	     CONT_SET_PERIOD: begin
		period <= vinput[31:8];
	     end

	     CONT_SET_PULSE1: begin
		p1width <= vinput[15:0];
	     end

	     CONT_SET_PULSE2: begin
		p2width <= vinput[15:0];
	     end

	     CONT_TOGGLE_PULSE1: begin
		block <= vinput[1];
		// pulse_block <= vinput[15:8];
		// pulse_block_off <= vinput[31:16];
	     end

	     CONT_SET_CPMG: begin
		cpmg <= vinput[0];
	     end

	     // CONT_SET_ATT: begin
		// pre_att <= vinput[7:0];
		// post_att <= vinput[15:8];
	     // end
	     
	   endcase // case (vcontrol)
	   state <= STATE_SENDING;
        end

	STATE_SENDING: begin


           case (writestate)

	     write_A: begin
			 rx_done = 1;
		if (~ is_transmitting) begin
		   transmit <= 1;
		   writestate  <= write_done;
		   tx_byte <= voutput;
		   state     <= STATE_SENDING;
		end
	     end

	     write_done: begin
			 rx_done = 0;
		if (~ is_transmitting) begin
		   writestate <= write_A; 
		   state     <= STATE_RECEIVING;
		   transmit <= 0;
		end
	     end

           endcase

        end

        default: begin
           // should not be reached
           state     <= STATE_RECEIVING;
           readcount <= read_A;
        end

      endcase // case (state)
      
   end // always @ (posedge iCE_CLK)
endmodule // pulse_control
