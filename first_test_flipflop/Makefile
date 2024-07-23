BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

# Generate Simulation
ff3.o: ff3.v ff3_tb.v
	iverilog -o ff3.o -s test ff3_tb.v ff3.v 

# Run Simulation
test: ff3.o
	vvp ff3.o


