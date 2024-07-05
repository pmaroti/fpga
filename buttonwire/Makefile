BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: buttonwire.fs

# Synthesis
buttonwire.json: buttonwire.v
	yosys -p "read_verilog buttonwire.v; synth_gowin -top buttonwire -json buttonwire.json"

# Place and Route
buttonwire_pnr.json: buttonwire.json
	nextpnr-gowin --json buttonwire.json --freq 27 --write buttonwire_pnr.json --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst

# Generate Bitstream
buttonwire.fs: buttonwire_pnr.json
	gowin_pack -d ${FAMILY} -o buttonwire.fs buttonwire_pnr.json

# Program Board
load: buttonwire.fs
	openFPGALoader -b ${BOARD} buttonwire.fs -f

# Program Board
loadram: buttonwire.fs
	openFPGALoader -b ${BOARD} buttonwire.fs -m	

.PHONY: load
.INTERMEDIATE: buttonwire_pnr.json buttonwire.json