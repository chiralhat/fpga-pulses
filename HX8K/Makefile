#
# Makefile for pulse generation for iCEstick
#
# Requires the IceStorm tools from https://github.com/cliffordwolf/icestorm

SYN = yosys
PNR = nextpnr-ice40
GEN = icepack

TARGET = pulse_gen
SIMTARGET = Sim/pulse_gen_sim
SIMINIT = Sim/pulse_gen_sim_init
SIMOUT = Sim/pulse_gen_sim
PULSEV = pulses.v pulse_control.v uart.v
# CONTROLV = pulse_control.v
SED_STR1 = '/NOSIM_START/,/NOSIM_END/d'
# SED_STR1 = '/NOSIM_START/,/NOSIM_END/d; 1,/NOSIM2_START/!d'
# SED_STR1a = '1,/NOSIM2_START/!d'
SED_STR2 = '4iinput clk_pll,'
SED_STR3 = 's/wire/reg/g'

default: all

clean:
	cp hardware.bin $(TARGET).bin.bak 2>/dev/null || :
	rm -f hardware.bin $(TARGET).blif $(TARGET).txt make.log pnr.log

simclean:
	rm -f $(SIMOUT)_post* $(SIMOUT)_tb*.vcd $(SIMTARGET).v

all: clean
	$(SYN) -p "synth_ice40 -json $(TARGET).json" $(TARGET).v icepll.v $(PULSEV) > make.log
	$(PNR) --pre-pack clk_constraint.py --hx8k --pcf icebox.pcf --json $(TARGET).json --asc $(TARGET).asc 2> pnr.log
	$(GEN) $(TARGET).asc hardware.bin

sim: simclean
	# sed $(SED_STR1) $(TARGET).v | sed $(SED_STR2) | sed $(SED_STR3) > $(SIMTARGET).v
	sed $(SED_STR1) $(TARGET).v | sed $(SED_STR2) > $(SIMTARGET).v
	# cat $(SIMINIT) >> $(SIMTARGET).v
	iverilog -o $(SIMOUT)_post $(SIMTARGET).v $(SIMOUT)_tb.v $(PULSEV) 2> sim.log
	vvp $(SIMOUT)_post
	gtkwave $(SIMOUT)_tb.vcd

.PHONY: all clean
