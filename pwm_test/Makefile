BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: pwm_test.fs

# Synthesis
pwm_test.json: pwm_test.v
	yosys -p "read_verilog pwm_test.v; synth_gowin -top pwm_test -json pwm_test.json"

# Place and Route
#nextpnr-gowin --json pwm_test.json --freq 27 --write pwm_test_pnr.json --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst
pwm_test_pnr.json: pwm_test.json
	nextpnr-himbaechel --json pwm_test.json \
		--write pwm_test_pnr.json \
		--device ${DEVICE} \
		--vopt family=${FAMILY} \
		--vopt cst=${BOARD}.cst

# Generate Bitstream
pwm_test.fs: pwm_test_pnr.json
	gowin_pack -d ${FAMILY} -o pwm_test.fs pwm_test_pnr.json

# Program Board
load: pwm_test.fs
	openFPGALoader -b ${BOARD} pwm_test.fs -f

# Program Board
loadram: pwm_test.fs
	openFPGALoader -b tangnano9k pwm_test.fs -m	

.PHONY: load
.INTERMEDIATE: pwm_test_pnr.json pwm_test.json