#
# Makefile for pulse generation for iCEstick
#
# Requires the IceStorm tools from https://github.com/cliffordwolf/icestorm
LD_LIBRARY_PATH=/home/denji/anaconda3/lib/

SYN = yosys
PNR = nextpnr-ice40
GEN = icepack

TARGET = pulse_gen
SIMTARGET = Sim/pulse_gen_sim
SIMINIT = Sim/pulse_gen_sim_init.v
SIMOUT = Sim/pulse_gen_sim
PULSEV = pulses.v
CONTROLV = pulse_control.v
SED_STR1 = '/NOSIM_START/,/NOSIM_END/d; 1,/NOSIM2_START/!d'
# SED_STR1a = '1,/NOSIM2_START/!d'
SED_STR2 = '4iinput clk_pll,'
SED_STR3 = 's/wire/reg/g'

default: all

clean:
	cp hardware.bin $(TARGET).bin.bak 2>/dev/null || :
	rm -f hardware.bin $(TARGET).blif $(TARGET).txt output.log

simclean:
	rm -f $(SIMOUT)_post $(SIMOUT).vcd $(SIMTARGET).v

all: clean
	$(SYN) -p "synth_ice40 -json $(TARGET).json" $(TARGET).v icepll.v uart.v $(PULSEV) $(CONTROLV) > make.log
	$(PNR) -freq 201 --hx8k --pcf icebox.pcf --json $(TARGET).json --asc $(TARGET).asc
	$(GEN) $(TARGET).asc hardware.bin

sim: simclean
	sed $(SED_STR1) $(TARGET).v | sed $(SED_STR2) | sed $(SED_STR3) > $(SIMTARGET).v
	cat $(SIMINIT) >> $(SIMTARGET).v
	iverilog -o $(SIMOUT)_post $(SIMTARGET).v $(SIMOUT)_tb.v $(PULSEV)
	vvp $(SIMOUT)_post
	gtkwave $(SIMOUT).vcd

.PHONY: all clean
