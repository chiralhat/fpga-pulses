# -*- coding: utf-8 -*-
"""
Created on Dec 21 2022

@author: Charles Collett

Driver to control the Lattice ECP5 FPGA Evaluation Board
Import the ecp5evn class, then call it with the FPGA's USB address
Example to set the first pulse to 995 ns:
from ecp5_driver import ecp5evn
fpga = ecp5evn('/dev/ttyUSB1')
fpga.pulse1 = 100

Note that because of how the control logic is coded, setting some
values (such as the delay length) cannot be done just for one switch,
and so it sets the other switch's value to be a saved value. If that
value has been previously set, this won't be a problem, but if not
then the saved value will be the default, and might cause some
unexpected behavior. It would be possible to change this by setting
all values when the FPGA is initialized, but for a variety of reasons
I have chosen not to do so.
"""


import struct
from serial import Serial
import numpy as np

freq = .1005
tstep = 1/freq

# period_shift = 1 << 16
period_shift = 1


class ecp5evn(object):
    '''
    Class to control Lattice ECP5 FPGA (ecp5-evn)

    '''

    def __init__(self, serial_string):
        self.instrument = Serial(serial_string, timeout=1)
        self.read = self.instrument.read
        
        self._delay = 200*tstep
        self._delay2 = 200*tstep
        self._period = 1*period_shift*tstep
        self._pulse1 = 30*tstep
        self._pulse2 = 30*tstep
        self._pulse2_1 = 30*tstep
        self._pulse2_2 = 30*tstep
        self._cpmg = 1
        self._pump = 1
        self._block = 1
        self._pulse_block = 250
        self._pulse_block_off = 500
        self._nutation_width = 0
        self._nutation_delay = 0
        self.se_port = 0
        
    __getitem__ = object.__getattribute__
    __setitem__ = object.__setattr__
    __delitem__ = object.__delattr__

    def keys(self):
        return self.__dict__.keys()

    def values(self):
        return self.__dict__.values()

    def items(self):
        return self.__dict__.items()


    control_byte = {
        'delay': 0,
        'period': 1,
        'pulse1': 2,
        'pulse2': 3,
        'toggle': 4,
        'cpmg': 5,
        'attenuators': 6,
        'nutation': 7
        }
    
    pack_fmt = {
        1: 'B',
        2: 'H',
        4: 'I'
    }

    freq = freq
    tstep = tstep


    def readcheck(self, out):
#         self.instrument.open()
        self.instrument.write(out)
        check = self.read()
#         self.instrument.close()
        out_check = np.sum(out[:-1])
        if out_check > 255:
            out_check = out_check - 256
        in_check = struct.unpack('B', check)[0]
        assert out_check-in_check==0
        return out
    

    def intToByte(self, num, nBytes=4):
        unpack_str="{}B".format(nBytes)
        pack_str = self.pack_fmt[nBytes]
        return struct.unpack(unpack_str, struct.pack(pack_str, num))


    def set_param(self, param, num):
        out = bytearray([self.control_byte[param]])
        # if (param=='period'):
        #     num = int(np.round(num/period_shift))
        #     ret = num*period_shift
        # else:
        #     ret = num
        ret = num
        [out.insert(0, b) for b in self.intToByte(num)[::-1]]
        return self.readcheck(out)


    def set_time(self, param, t_ns):
        num = int(np.round(t_ns/self.tstep))
        self.set_param(param, num)
        return num*self.tstep


    def set_p2time(self, param, t_ns1, t_ns2):
        num1 = int(np.round(t_ns1/self.tstep))
        num2 = int(np.round(t_ns2/self.tstep))
        nums = num1 + (num2 << 16)
        self.set_param(param, nums)
        return (num1*self.tstep, num2*self.tstep)
    
    
    def set_times(self, pulse1, pulse2, delay, period):
        self.pulse1 = pulse1
        self.pulse2 = pulse2
        self.delay = delay
        self.period = period
    
    
    def set_times2(self, pulse1, pulse2, delay, period):
        self.pulse2_1 = pulse1
        self.pulse2_2 = pulse2
        self.delay2 = delay
        self.period = period
    

    def toggle(self, pump=1, block=1,
               pulse_block=200, pulse_block_off=1500):
        pblock = int(np.round(pulse_block/self.tstep))
        pblock_off = int(np.round(pulse_block_off/self.tstep))
        out = bytearray([self.control_byte['toggle']])
        pbo_byte = self.intToByte(pblock_off, 2)
        [out.insert(0, b) for b in pbo_byte[::-1]]
        out.insert(0, self.intToByte(pblock, 1)[0])
        out.insert(0, self.intToByte(block, 1)[0])
        return self.readcheck(out)

    @property
    def pump(self):
        return self._pump

    @pump.setter
    def pump(self, pump):
        self.toggle(pump, self._block, self._pulse_block, self._pulse_block_off)
        self._pump = pump

    @property
    def block(self):
        return self._block

    @block.setter
    def block(self, block):
        self.toggle(self._pump, block, self._pulse_block, self._pulse_block_off)
        self._block = block

    @property
    def pulse_block(self):
        return self._pulse_block*self.tstep

    @pulse_block.setter
    def pulse_block(self, pulse_block):
        num = int(np.round(pulse_block/self.tstep))
        self.toggle(self._pump, self._block, pulse_block, self._pulse_block_off)
        self._pulse_block = num

    @property
    def pulse_block_off(self):
        return self._pulse_block_off*self.tstep

    @pulse_block_off.setter
    def pulse_block_off(self, pulse_block_off):
        num = int(np.round(pulse_block_off/self.tstep))
        self.toggle(self._pump, self._block, self._pulse_block, pulse_block_off)
        self._pulse_block_off = num

    @property
    def delay(self):
        return self._delay

    @delay.setter
    def delay(self, delay):
        self._delay = self.set_p2time('delay', delay, self._delay2)[0]

    @property
    def delay2(self):
        return self._delay2

    @delay2.setter
    def delay2(self, delay2):
        self._delay2 = self.set_p2time('delay', self._delay, delay2)[1]

    @property
    def period(self):
        return self._period

    @period.setter
    def period(self, period):
        self._period = self.set_time('period', period)

    @property
    def pulse1(self):
        return self._pulse1

    @pulse1.setter
    def pulse1(self, pulse1):
        self._pulse1 = self.set_p2time('pulse1', pulse1, self._pulse2_1)[0]

    @property
    def pulse2(self):
        return self._pulse2

    @pulse2.setter
    def pulse2(self, pulse2):
        self._pulse2 = self.set_p2time('pulse2', pulse2, self.pulse2_2)[0]
    
    @property
    def pulse2_1(self):
        return self._pulse2_1

    @pulse2_1.setter
    def pulse2_1(self, pulse2_1):
        self._pulse2_1 = self.set_p2time('pulse1', self._pulse1, pulse2_1)[1]

    @property
    def pulse2_2(self):
        return self._pulse2_2

    @pulse2_2.setter
    def pulse2_2(self, pulse2_2):
        self._pulse2_2 = self.set_p2time('pulse2', self._pulse2, pulse2_2)[1]
    
    @property
    def cpmg(self):
        return self._cpmg

    @cpmg.setter
    def cpmg(self, cpmg):
        out = bytearray([self.control_byte['cpmg']])
        cpmg_byte = self.intToByte(cpmg, 1)[0]
        [out.insert(0, b) for b in [0, 0, 0, cpmg_byte]]
        self.readcheck(out)
        self._cpmg = cpmg
    
    @property
    def nutation_width(self):
        return self._nutation_width
    
    @nutation_width.setter
    def nutation_width(self, nut_wid):
        out = self.set_p2time('nutation', nut_wid, self._nutation_delay)
        self._nutation_width, self._nutation_delay = out
    
    @property
    def nutation_delay(self):
        return self._nutation_delay
    
    @nutation_delay.setter
    def nutation_delay(self, nut_del):
        out = self.set_p2time('nutation', self._nutation_width, nut_del)
        self._nutation_width, self._nutation_delay = out


    def freq_sweep(self, length):
        self.cpmg = 0
        self.block = 1
        self.pulse1 = 200
        self.pulse2 = 200
        self.delay = 5000
        self.period = 1.2*length*1e6 # Longer to allow for inaccurate scope framing 


    def pulse_freq_sweep(self, p):
        self.cpmg = 1
        self.block = 1
        self.pulse_block = p['pulse_block']
        if p['port']==1:
            self.set_times(p['pulse1'], p['pulse2'], p['delay'], p['period'])
        elif p['port']==2:
            self.set_times2(p['pulse1'], p['pulse2'], p['delay'], p['period'])
        elif p['port']==0:
            self.set_times(p['pulse1'], p['pulse2'], p['delay'], p['period'])
            self.set_times2(p['pulse1'], p['pulse2'], p['delay'], p['period'])
            
        
    def spin_echo(self, p):
        self.cpmg = p['cpmg']
        self.block = 1
        self.pulse_block = p['pulse_block']
        self.nutation_delay = p['nutation_delay']
        self.nutation_width = p['nutation_width']
        self.period = p['period']
        if p['port'] == 1:
            self.pulse1 = p['pulse1']
            self.pulse2 = p['pulse2']
            self.delay = p['delay']
            self.pulse2_1 = 0
            self.pulse2_2 = 0
            self.delay2 = p['delay']
        else:
            self.pulse1 = 0
            self.pulse2 = 0
            self.delay = p['delay']
            self.pulse2_1 = p['pulse1']
            self.pulse2_2 = p['pulse2']
            self.delay2 = p['delay']
        self.se_port = p['port']
