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

TARGET = pulse_gen

default: all

clean:
	rm -f $(TARGET).bin $(TARGET).blif $(TARGET).txt output.log

all: clean
	$(SYN) -p "synth_ice40 -blif $(TARGET).blif" $(TARGET).v icepll.v uart.v
	$(PNR) -d 1k -p icestickfull.pcf $(TARGET).blif -o $(TARGET).txt
	$(GEN) $(TARGET).txt $(TARGET).bin

.PHONY: all clean
