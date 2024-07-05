BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: nco.fs

# Synthesis
nco.json: nco.v
	yosys -p "read_verilog nco.v sinlt.v; synth_gowin -top nco -json nco.json"

# Place and Route
nco_pnr.json: nco.json
	nextpnr-gowin --json nco.json --write nco_pnr.json --freq 27 --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst

# Generate Bitstream
nco.fs: nco_pnr.json
	gowin_pack -d ${FAMILY} -o nco.fs nco_pnr.json

# Program Board
load: nco.fs
	openFPGALoader -b ${BOARD} nco.fs -f


# Generate Simulation
nco_test.o: nco.v nco_tb.v
	iverilog -o nco_test.o -s test nco.v nco_tb.v sinlt.v

# Run Simulation
test: nco_test.o
	vvp nco_test.o

# Cleanup build artifacts
clean:
	rm nco.vcd nco.fs nco_test.o

.PHONY: load clean test
.INTERMEDIATE: nco_pnr.json nco.json nco_test.o