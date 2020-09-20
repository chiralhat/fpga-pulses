# ECP5 Project

The purpose of this project is twofold: 
1. Port the existing spectrometer code from the [iCE40-HX8K Breakout Board](http://www.latticesemi.com/Products/DevelopmentBoardsAndKits/iCE40HX8KBreakoutBoard.aspx) to the [ECP5 Evaluation Board](http://www.latticesemi.com/ecp5-evaluation), making any necessary changes to make it work on the new board at **200 MHz**.
2. Add functionality (CPMG, attenuator control, etc.) back to the code and verify that it still passes the timing tests.

## Porting
The iCE40 and ECP5 families share some open-source tools: [yosys](https://github.com/YosysHQ/yosys) for synthesis, and [nextpnr](https://github.com/YosysHQ/nextpnr) for place-and-route and timing analysis. The rest of the open-source tooling for the ECP5 is provided by [Project Trellis](https://github.com/YosysHQ/prjtrellis) (whereas the tooling for the iCE40 family is provided by [Project IceStorm](http://www.clifford.at/icestorm/)).

My suggestion for a path forward is to start by setting up [Windows Subsystem in Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10), if you haven't already. Then install both the Icestorm and Trellis tooling (you'll have to build nextpnr twice, once with -DARCH=ice40 and once with -DARCH=ecp5), and clone this repository. If everything installs correctly you should be able to run `make` in the HX8K folder and get no errors. Then take a look at the prjtrellis/examples/ecp5_evn example, particularly the Makefile, to see how to run the Project Trellis workflow (run `make` instead of `make prog`, because we don't yet have boards to program).

Finally, you'll be able to start trying to port the iCE40 code in here over to the ECP5. This is a big task, because it requires figuring out how to use the different set of clocks (including the built-in 200 MHz one for the main logic loop), how to communicate with the board from the computer (maybe try out the simpleuart.v in the soc_ecp5_evn example), and how to rewrite the icebox.pcf pinout file as a .lpf file, linking pins and transmission points correctly. The soc_ecp5_evn example might be a bit more helpful as a place to start with that, comparing its ecp5evn.lpf to the icebox.pcf.

It's a lot, and it's fairly nebulous, but hopefully by the time you get through setting everything up you'll have a better sense for how all this works!