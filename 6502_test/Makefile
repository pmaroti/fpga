BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: 6502_test.fs

# Synthesis
6502_test.json: 6502_test.v
	yosys -p "read_verilog 6502_test.v gowin_rpll.v; synth_gowin -top 6502_test -json 6502_test.json"

# Place and Route
#nextpnr-gowin --json 6502_test.json --freq 27 --write 6502_test_pnr.json --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst
6502_test_pnr.json: 6502_test.json
	nextpnr-himbaechel --json 6502_test.json \
		--write 6502_test_pnr.json \
		--device ${DEVICE} \
		--vopt family=${FAMILY} \
		--vopt cst=${BOARD}.cst

# Generate Bitstream
6502_test.fs: 6502_test_pnr.json
	gowin_pack -d ${FAMILY} -o 6502_test.fs 6502_test_pnr.json

# Program Board
load: 6502_test.fs
	openFPGALoader -b ${BOARD} 6502_test.fs -f

# Program Board
loadram: 6502_test.fs
	openFPGALoader -b tangnano9k 6502_test.fs -m	

# Generate Simulation
6502_test.o: 6502_test_tb.v cpu.v ALU.v
	iverilog -o 6502_test.o -s test 6502_test_tb.v cpu.v ALU.v

# Run Simulation
test: 6502_test.o
	vvp 6502_test.o

.PHONY: load
.INTERMEDIATE: 6502_test_pnr.json 6502_test.json