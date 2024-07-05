BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: pll_test.fs

# Synthesis
pll_test.json: pll_test.v
	yosys -p "read_verilog pll_test.v gowin_rpll.v; synth_gowin -top pll_test -json pll_test.json"

# Place and Route
#nextpnr-gowin --json pll_test.json --freq 27 --write pll_test_pnr.json --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst
pll_test_pnr.json: pll_test.json
	nextpnr-himbaechel --json pll_test.json \
		--write pll_test_pnr.json \
		--device ${DEVICE} \
		--vopt family=${FAMILY} \
		--vopt cst=${BOARD}.cst

# Generate Bitstream
pll_test.fs: pll_test_pnr.json
	gowin_pack -d ${FAMILY} -o pll_test.fs pll_test_pnr.json

# Program Board
load: pll_test.fs
	openFPGALoader -b ${BOARD} pll_test.fs -f

# Program Board
loadram: pll_test.fs
	openFPGALoader -b tangnano9k pll_test.fs -m	

.PHONY: load
.INTERMEDIATE: pll_test_pnr.json pll_test.json