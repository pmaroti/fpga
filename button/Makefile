BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: button.fs

# Synthesis
button.json: button.v
	yosys -p "read_verilog button.v; synth_gowin -top button -json button.json"

# Place and Route
button_pnr.json: button.json
	nextpnr-gowin --json button.json --freq 27 --write button_pnr.json --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst

# Generate Bitstream
button.fs: button_pnr.json
	gowin_pack -d ${FAMILY} -o button.fs button_pnr.json

# Program Board
load: button.fs
	openFPGALoader -b ${BOARD} button.fs -f

.PHONY: load
.INTERMEDIATE: button_pnr.json button.json