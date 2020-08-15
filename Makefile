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
	PNR = nextpnr-ice40
	GEN = icepack
endif

TARGET = HX8K/pulse_gen
SIMTARGET = HX8K/pulse_gen_sim
SIMINIT = HX8K/pulse_gen_sim_init.v
SIMOUT = HX8K/pulse_gen_sim
PULSEV = HX8K/pulses.v
CONTROLV = HX8K/pulse_control.v
SED_STR1 = '/NOSIM_START/,/NOSIM_END/d; 1,/NOSIM2_START/!d'
# SED_STR1a = '1,/NOSIM2_START/!d'
SED_STR2 = '4iinput clk_pll,'
SED_STR3 = 's/wire/reg/g'

default: all

clean:
	cp $(TARGET).bin $(TARGET).bin.bak 2>/dev/null || :
	rm -f $(TARGET).bin $(TARGET).blif $(TARGET).txt output.log

simclean:
	rm -f $(SIMOUT)_post $(SIMOUT).vcd $(SIMTARGET).v

all: clean
	$(SYN) -p "synth_ice40 -blif $(TARGET).blif" $(TARGET).v icepll.v uart.v $(PULSEV) $(CONTROLV) > make.log
	$(PNR) -d 8k -p HX8K/icebox.pcf $(TARGET).blif -o $(TARGET).txt
	$(GEN) $(TARGET).txt $(TARGET).bin

sim: simclean
	sed $(SED_STR1) $(TARGET).v | sed $(SED_STR2) | sed $(SED_STR3) > $(SIMTARGET).v
	cat $(SIMINIT) >> $(SIMTARGET).v
	iverilog -o $(SIMOUT)_post $(SIMTARGET).v $(SIMOUT)_tb.v $(PULSEV)
	vvp $(SIMOUT)_post
	gtkwave $(SIMOUT).vcd

.PHONY: all clean
