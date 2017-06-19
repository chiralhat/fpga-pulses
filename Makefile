#
# Makefile for pulse generation for iCEstick
#
# Requires the IceStorm tools from https://github.com/cliffordwolf/icestorm

ifdef SYSTEMROOT
	SYN = bin/yosys.exe
	PNR = bin/arachne-pnr.exe
	GEN = bin/icepack.exe
else
	SYN = yosys
	PNR = arachne-pnr
	GEN = icepack
endif

TARGET = HX8K/pulse_gen
SIMTARGET = HX8K/pulse_gen_sim
SIMOUT = HX8K/pulse_gen_sim
PULSEV = HX8K/pulses.v
CONTROLV = HX8K/pulse_control.v

default: all

clean:
	rm -f $(TARGET).bin $(TARGET).blif $(TARGET).txt output.log

simclean:
	rm -f $(SIMOUT)_post $(SIMOUT).vcd

all: clean
	$(SYN) -p "synth_ice40 -blif $(TARGET).blif" $(TARGET).v icepll.v uart.v $(PULSEV) $(CONTROLV) > make.log
	$(PNR) -d 8k -p HX8K/icebox.pcf $(TARGET).blif -o $(TARGET).txt
	$(GEN) $(TARGET).txt $(TARGET).bin

sim: simclean
	iverilog -o $(SIMOUT)_post $(SIMTARGET).v $(SIMOUT)_tb.v $(PULSEV)
	vvp $(SIMOUT)_post
	gtkwave $(SIMOUT).vcd

.PHONY: all clean
