# TODO: add options to extract the eeprom, make the loading and configuring eeprom variants, and then add loading the appropriate variant to the programming setup
PROJ=pulse_gen
TRELLIS?=/usr/local/share/trellis

PULSEV = src/pulses.v src/pulse_control.v src/uart.v
TARGET = src/pulse_gen

SIMTARGET = src/pulse_gen_sim
SIMOUT = build/pulse_gen_sim

SED_STR1 = '/NOSIM_START/,/NOSIM_END/d'#; 1,/NOSIM2_START/!d'
SED_STR2 = '4iinput clk_pll,'
SED_STR3 = 's/wire/reg/g'

default: all

all: clean ${PROJ}.bit

%.json: src/%.v
	yosys -p "synth_ecp5 -json $@ -top pulse_gen" $< $(PULSEV) ecppll.v > build/make.log

%_out.config: %.json
	nextpnr-ecp5 --pre-pack clk_constraint.py --json $< --textcfg $@ --um5g-85k --package CABGA381 --lpf src/ecp5.lpf 2> build/pnr.log

%.bit: %_out.config
	ecppack --svf $*.svf $< $@
	mv $@ build/

${PROJ}.svf : ${PROJ}.bit

prog: ${PROJ}.svf
	openocd -f src/ecp5.cfg -c "transport select jtag; init; svf $<; exit" 2> build/prog.log

eeprog: ${PROJ}.svf
ifeq ("$(wildcard ftdi_prog.conf)","")
	ftdi_eeprom --read-eeprom src/ftdi_prog.conf
	sed 's/^\x01\x01/\x01\x08/g' eeprom_prog.bin > eeprom_serial.bin
endif
	ftdi_eeprom --flash-eeprom src/ftdi_prog.conf
	openocd -f ecp5.cfg -c "transport select jtag; init; svf $<; exit" 2> prog.log
	ftdi_eeprom --flash-eeprom src/ftdi_serial.conf

clean:
	cp ${PROJ}.svf build/${PROJ}.svf.bak 2>/dev/null || :
	rm -f *.svf build/*.log build/*.bit

simclean:
	rm -f $(SIMOUT)_post $(SIMOUT)_tb.vcd $(SIMOUT).v

nosim: simclean
	sed $(SED_STR1) $(TARGET).v | sed $(SED_STR2) > $(SIMOUT).v
	iverilog -o $(SIMOUT)_post $(SIMOUT).v $(SIMTARGET)_tb.v $(PULSEV)
	vvp $(SIMOUT)_post

sim: simclean nosim
	gtkwave $(SIMOUT)_tb.vcd > /dev/null

.PHONY: prog clean

eeprom:
	ftdi_eeprom --read-eeprom ftdi_prog.conf
	sed 's/^\x01\x01/\x01\x08/g' eeprom_prog.bin > eeprom_serial.bin
	ftdi_eeprom --flash-eeprom ftdi_serial.conf
