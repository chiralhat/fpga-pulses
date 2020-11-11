PROJ=pulse_gen
TRELLIS?=/usr/share/trellis

PULSEV = pulses.v
TARGET = pulse_gen
PLLV = ecppll.v

SIMTARGET = Sim/pulse_gen_sim
SIMINIT = Sim/pulse_gen_sim_init
SIMOUT = Sim/pulse_gen_sim
SIMCONTROL = Sim/pulse_control_sim

SED_STR1 = '/NOSIM_START/,/NOSIM_END/d; 1,/NOSIM2_START/!d'
SED_STR2 = '4iinput clk_pll,'
SED_STR3 = 's/wire/reg/g'

all: ${PROJ}.bit

%.json: %.v
	yosys -p "synth_ecp5 -json $@ -top pulse_gen" $< ecppll.v pulse_control.v $(PULSEV) uart.v

%_out.config: %.json
	nextpnr-ecp5 --pre-pack clk_constraint.py --json $< --textcfg $@ --um5g-85k --package CABGA381 --lpf ecp5.lpf

%.bit: %_out.config
	ecppack --svf ${PROJ}.svf $< $@

${PROJ}.svf : ${PROJ}.bit

prog: ${PROJ}.svf
	openocd -f ${TRELLIS}/misc/openocd/ecp5-evn.cfg -c "transport select jtag; init; svf $<; exit"

clean:
	rm -f *.svf *.bit *.config *.json make.log
	
simclean:
	rm -f $(SIMOUT)_post $(SIMOUT)_tb.vcd $(SIMTARGET).v $(SIMCONTROL).v

sim: simclean
	sed $(SED_STR1) $(TARGET).v | sed $(SED_STR2) | sed $(SED_STR3) > $(SIMTARGET).v
	cat $(SIMINIT) >> $(SIMTARGET).v
	iverilog -o $(SIMOUT)_post $(SIMTARGET).v $(SIMOUT)_tb.v $(PULSEV)
	vvp $(SIMOUT)_post
	#gtkwave $(SIMOUT)_tb.vcd

.PHONY: prog clean
