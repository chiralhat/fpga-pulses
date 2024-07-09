# fpga-pulses
Verilog code to turn the [ECP5 Evaluation Board](http://www.latticesemi.com/ecp5-evaluation) into a custom pulse generator for electron spin resonance (ESR) experiments.
As currently programmed it runs at a PLL clock of 200 MHz, for a time resolution of 5 ns.

It is currently set up to control the following components of a homemade pulsed ESR spectrometer:
* Three switches
	* Two that turn one or two continuous-wave (CW) input signals into arbitrary pulses
	* One that blocks power leakage through the first two switches when they are both open
* One digital step attenuator
* An oscilloscope for readout (the FPGA produces a SYNC pulse to trigger the scope)

## Setup
In order to compile and program the board, I recommend the use of the open source
[YosysHQ](https://github.com/YosysHQ/) tools. The provided Makefile assumes their use, particularly yosys and nextpnr.

### USB Communication
The default EEPROM configuration on some ECP5 boards is slightly wrong, and doesn't allow USB communication with the board.
Specifically, the second character in the EEPROM binary config file should be `08` instead of `01`.
To fix this, you need to install ftdi-eeprom (available in software repositories).
Then run `make eeprom`. This saves the default configuration into `eeprom-prog.bin`, and loads the corrected EEPROM to the board.
Finally, you need to solder jumper wires to R34 and R35 on the board.

### Setting up a Linux control computer
Control of the board requires usb access permissions.
Ensure your account is a member of the "plugdev" group, then create "/etc/udev/rules.d/99-ecp5-evn.rules" (or take the one in this repository), and write in it

`SUBSYSTEMS=="usb", MODE="0660", GROUP="plugdev"`

Note that this gives the "plugdev" group permissions to access to any USB device.

## Dynamic Control
Control code is provided in the [pyscan-esr](https://github.com/chiralhat/pyscan-esr) repository. With the current configuration, the FPGA allows active control of:
* Pulse count (up to three independent pulses for one output per period, up to two for the second output)
* Pulse width
  * Independent control of each pulse
* Delay between pulses
* Overall repetition rate (period)
* Attenuation of the signal
  * A digital step attenuator can be controlled
  * The attenuation of the first pulse is by default 3 dB lower than the second pulse

Control signals are sent over the USB cable, and consist of five bytes.
The left-most (most significant) byte is the control byte, and the other four input bytes contain the data to be read in. Time values are in units of number of timesteps, such that a value of 30 would correspond to a time of 150 ns. Entries marked with a \* have their input bytes split in two, the least-significant setting the first switch and the most-significant setting the second switch.
The control byte values are:
1. Set Delay\*
2. Set Period
3. Set First Pulse Width\*
4. Set Second Pulse Width\*
5. Set CW Output
  * When in CW mode, the LSB of the least significant input byte toggles the output between switch 1 (0) and 2 (1).
6. Set Pulsed Mode
	* The LSB of the least-significant byte either sets CW mode (0) or pulsed mode (1).
	* The two most-significant bytes set the time offset between the start of the first pulse for the first switch and the start of the first pulse for the second switch.
7. Set Nutation
	* The two least-significant bytes set the width of the nutation pulse, which comes before the first pulse.
	* The two most-significant bytes set the time offset between the nutation pulse and the first pulse.
8. Set Attenuators
  * The least-significant byte sets the overall attenuation.

# Credits
The UART code comes from Timothy Goddard and Aaron Dahlen.