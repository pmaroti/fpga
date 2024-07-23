BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: test_6502.fs

# Synthesis
test_6502.json: test_6502.v
	yosys -p "read_verilog test_6502.v memory.v reset_vector.v led_perif.v uart_perif.v cpu.v ALU6502.v posedge_check.v ; synth_gowin -top test_6502 -json test_6502.json"

# Place and Route
#nextpnr-gowin --json test_6502.json --freq 27 --write test_6502_pnr.json --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst
test_6502_pnr.json: test_6502.json
	nextpnr-himbaechel --json test_6502.json \
		--write test_6502_pnr.json \
		--device ${DEVICE} \
		--vopt family=${FAMILY} \
		--vopt cst=${BOARD}.cst

# Generate Bitstream
test_6502.fs: test_6502_pnr.json
	gowin_pack -d ${FAMILY} -o test_6502.fs test_6502_pnr.json

# Program Board
load: test_6502.fs
	openFPGALoader -b ${BOARD} test_6502.fs -f

# Program Board
loadram: test_6502.fs
	openFPGALoader -b tangnano9k test_6502.fs -m	

# Generate Simulation
test_6502.o: test_6502_tb.v cpu.v ALU6502.v test_6502.v memory.v reset_vector.v led_perif.v uart_perif.v posedge_check.v
	iverilog -o test_6502.o -s test test_6502_tb.v cpu.v ALU6502.v test_6502.v memory.v reset_vector.v led_perif.v uart_perif.v posedge_check.v

# Run Simulation
test: test_6502.o
	vvp test_6502.o

.PHONY: load
.INTERMEDIATE: test_6502_pnr.json test_6502.json


