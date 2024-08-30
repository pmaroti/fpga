BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: system.fs

# Synthesis
system.json: system.v
	yosys -p "read_verilog system.v cpu6502.v; synth_gowin -top system -json system.json"

# Place and Route
system_pnr.json: system.json
	nextpnr-himbaechel --json system.json \
		--write system_pnr.json \
		--device ${DEVICE} \
		--vopt family=${FAMILY} \
		--vopt cst=${BOARD}.cst

# Generate Bitstream
system.fs: system_pnr.json
	gowin_pack -d ${FAMILY} -o system.fs system_pnr.json

# Program Board
load: system.fs
	openFPGALoader -b ${BOARD} system.fs -f

# Program Board to RAM
loadram: system.fs
	openFPGALoader -b tangnano9k system.fs -m	

# Generate Simulation
test: 
	iverilog -o system_test.o system_tb.v
	./system_test.o

compile: program.s
	ca65 -vvv --cpu 6502 -l listing.txt -o rom.o program.s
	ld65 -o rom.bin -C rom.cfg rom.o
	hexdump -e '16/1 "%02x " "\n"' -v rom.bin > rom.hex

gtkw:
	gtkwave systemtest.gtkw

.PHONY: load
.INTERMEDIATE: test_6502_pnr.json test_6502.json


