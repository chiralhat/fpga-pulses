# fpga-pulses-ice
Verilog code to turn the [iCEstick FPGA board](http://www.latticesemi.com/icestick) into a custom pulse generator for electron spin resonance (ESR) experiments.
As currently programmed it runs at a PLL clock of 200 MHz, for a time resolution of 5 ns.

It is currently set up to control the following components of a homemade pulsed ESR spectrometer:
* A switch that turns an input continuous-wave signal into arbitrary pulses
* Two attenuators, one immediately after the switch (pre-att) and one after the signal has interacted with the sample (post-att)
  * The attenuators used are digital step attenuators, such that each bit in a byte toggles a different order of attenuation
* An oscilloscope for readout (the FPGA produces a SYNC pulse to trigger the scope)

## Setup
In order to compile and program the board, I recommend the use of the open source
[IceStorm](http://www.clifford.at/icestorm/) tools. The provided Makefile assumes their use.

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
* Pulse count (1 or 2)
* Pulse width
  * Independent control of each pulse
* Delay between pulses
* Overall repetition rate (period)
* Attenuation of the signal
  * Independent control of pre-att and post-att
  * Multiple pulses can have different attenuations

Control signals are sent over the USB cable, and consist of five bytes.
The left-most (most significant) byte is the control byte, and the other four input bytes contain the data to be read in.
The control byte values are:
1. Set Delay
2. Set Period
3. Set First Pulse Width
4. Set Second Pulse Width
  * For the above four states, the value in the input bytes sets the new value, in units of 5 ns
  (*i.e.* a value of 30 would correspond to a time of 150 ns).
5. Enable/Disable First Pulse
  * The LSB of the least significant input byte turns the first pulse on (1) or off (0).
6. Set Attenuators
  * From least to most significant input bytes, this sets:
    1. The pre-att
    2. The post-att
    3. The pre-att value for the first pulse (optional, currently disabled, defaulting to 0 dB)
    4. Whether each pulse has a different attenuation (on if LSB is 1, off if 0)

# Credits
The UART code is adapted from https://github.com/cyrozap/iCEstick-UART-Demo/pull/3/files#diff-bca38f311bb7e3ea53c7f1f8993dcf59

The PLL code is adapted from https://gist.github.com/thoughtpolice/8ec923e1b3fc4bb12c11aa23b4dc53b5#file-ice40-v
