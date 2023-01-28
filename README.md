# fpga-pulses-ice
Verilog code to turn the [ECP5 Evaluation Board](http://www.latticesemi.com/ecp5-evaluation) into a custom pulse generator for electron spin resonance (ESR) experiments.
As currently programmed it runs at a PLL clock of 100.5 MHz, for a time resolution of 9.95 ns.

It is currently set up to control the following components of a homemade pulsed ESR spectrometer:
* Three switches
	* Two that turn one or two continuous-wave (CW) input signals into arbitrary pulses
	* One that blocks the high-power pulses from reaching the sensitive detection electronics (pulse blocking)
* Two digital step attenuators
* An oscilloscope for readout (the FPGA produces a SYNC pulse to trigger the scope)
* The CW frequency sweep starting trigger for an [RF source] (https://windfreaktech.com/product/microwave-signal-generator-synthhd/)

## Setup
In order to compile and program the board, I recommend the use of the open source
[YosysHQ](https://github.com/YosysHQ/) tools. The provided Makefile assumes their use, particularly yosys and nextpnr.

### Drivers and interfacing with LabView (Windows 7)
I have only set up to communicate with the FPGA on Windows 7, and I started with the driver installation guide
[here](https://github.com/FPGAwars/libftdi-cross-builder/wiki#driver-installation).
Using Zadig allowed me to successfully program the FPGA, but more work is necessary in order to allow LabView to 
communicate with the board.

In Device Manager there are entries for the board under both libusbK and USB controllers.
The entry under USB controllers will be something like "USB Serial Converter B". Right click it, go to properties,
and under the Advanced tab check the "Load VCP" box. After that, a reboot and disconnection/reconnection of the device
should bring up a new entry in Ports (COM & LPT), named "USB Serial Port (COMX)" where X is a number.
LabView should now be able to see that port and communicate over VISA.

## Dynamic Control
This code configures the FPGA to allow programming of:
* Pulse count (up to three independent pulses per switch per period, and up to 255 identical copies of the final pulse)
* Pulse width
  * Independent control of each pulse
* Delay between pulses
* Overall repetition rate (period)
* Attenuation of the signal
  * Independent control of each attenuator
  * Multiple pulses can have different attenuations

Control signals are sent over the USB cable, and consist of five bytes.
The left-most (most significant) byte is the control byte, and the other four input bytes contain the data to be read in. Time values are in units of number of timesteps, such that a value of 30 would correspond to a time of 298.5 ns. Entries marked with a \* have their input bytes split in two, the least-significant setting the first switch and the most-significant setting the second switch.
The control byte values are:
1. Set Delay\*
2. Set Period
3. Set First Pulse Width\*
4. Set Second Pulse Width\*
5. Set Block
  * The LSB of the least significant input byte turns the pulse blocking on (1) or off (0).
  * The second and third bytes set the time offset between the end of the second pulse and the closing of the blocking switch.
6. Set CPMG (Experimental)
	* The least-significant byte either sets CW mode (0) or sets the number of final pulses (1-255).
	* The two most-significant bytes set the time offset between the start of the first pulse for the first switch and the start of the first pulse for the second switch.
7. Set Attenuators
  * The least-significant byte sets the pre-att, the next-least-significant byte sets the post-att.
8. Set Nutation
	* The two least-significant bytes set the width of the nutation pulse, which comes before the first pulse.
	* The two most-significant bytes set the time offset between the nutation pulse and the first pulse.

# Credits
The UART code comes from Timothy Goddard and Aaron Dahlen.