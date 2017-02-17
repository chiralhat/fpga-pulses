# fpga-pulses-ice
Verilog code to turn the [iCEstick FPGA board](http://www.latticesemi.com/icestick) into a custom pulse generator for electron spin resonance (ESR) experiments.
As currently programmed it runs at a PLL clock of 200 MHz, for a time resolution of 5 ns.

It is currently set up to control the following components of a homemade pulsed ESR spectrometer:
* A switch that turns an input continuous-wave signal into arbitrary pulses
* Two attenuators, one immediately after the switch and one after the signal has interacted with the sample
* An oscilloscope for readout (the FPGA produces a SYNC pulse to trigger the scope)

## Setup
In order to compile and program the board, I recommend the use of the open source
[IceStorm](http://www.clifford.at/icestorm/) tools. The provided Makefile assumes their use.

### Drivers and interfacing with LabView
I have only set up to communicate with the FPGA on Windows 7, and I started with the driver installation guide
[here](https://github.com/FPGAwars/libftdi-cross-builder/wiki#driver-installation).

## More to come
