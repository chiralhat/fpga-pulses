module icepll(REFERENCECLK,
              PLLOUTCORE,
              PLLOUTGLOBAL,
              RESET,
              LOCK);

input REFERENCECLK;
input RESET;    /* To initialize the simulation properly, the RESET signal (Active Low) must be asserted at the beginning of the simulation */ 
output PLLOUTCORE;
output PLLOUTGLOBAL;
output LOCK;

SB_PLL40_CORE icepll_inst(.REFERENCECLK(REFERENCECLK),
                          .PLLOUTCORE(PLLOUTCORE),
                          .PLLOUTGLOBAL(PLLOUTGLOBAL),
                          .EXTFEEDBACK(),
                          .DYNAMICDELAY(),
                          .RESETB(RESET),
                          .BYPASS(1'b0),
                          .LATCHINPUTVALUE(),
                          .LOCK(LOCK),
                          .SDI(),
                          .SDO(),
                          .SCLK());

//\\ Fin=12, Fout=201;
defparam icepll_inst.DIVR = 4'b0000;
defparam icepll_inst.DIVF = 7'b1000010;
defparam icepll_inst.DIVQ = 3'b010;
defparam icepll_inst.FILTER_RANGE = 3'b001;
defparam icepll_inst.FEEDBACK_PATH = "SIMPLE";
defparam icepll_inst.DELAY_ADJUSTMENT_MODE_FEEDBACK = "FIXED";
defparam icepll_inst.FDA_FEEDBACK = 4'b0000;
defparam icepll_inst.DELAY_ADJUSTMENT_MODE_RELATIVE = "FIXED";
defparam icepll_inst.FDA_RELATIVE = 4'b0000;
defparam icepll_inst.SHIFTREG_DIV_MODE = 2'b00;
defparam icepll_inst.PLLOUT_SELECT = "GENCLK";
defparam icepll_inst.ENABLE_ICEGATE = 1'b0;

endmodule
