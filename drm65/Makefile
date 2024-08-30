#----------------------------------------
#-- Establecer nombre del componente
#----------------------------------------
DEPSIM = cpu6502.v system.v uart_simple.v video.v
DEPSINT= cpu6502.v system.v uart_simple.v video.v pll.v 

#-------------------------------------------------------
#-- Objetivo por defecto: hacer simulacion y sintesis
#-------------------------------------------------------
all: sim
	
#----------------------------------------------
#-- make sim
#----------------------------------------------
#-- Objetivo para hacer la simulacion del
#-- banco de pruebas
#----------------------------------------------
sim: tb.vcd 
	#-- Ver visualmente la simulacion con gtkwave
	gtkwave tb.vcd tb.gtkw &
	
#-----------------------------------------------
#-  make sint
#-----------------------------------------------
#-  Objetivo para realizar la sintetis completa
#- y dejar el diseno listo para su grabacion en
#- la FPGA
#-----------------------------------------------

sint: main.bin
	#../iceRAM/iceram $<
	../../lpc11loader/iceload -e 2 -c $<

burn: main.bin
	../../lpc11loader/iceload -p $<

term:
	../../lpc11loader/iceload -e 2 -t

cream:	maincream.bin
	../../lpc11loader/iceload -e 2 -f 16 -c $<
out.hex:	rom/nrom.bin Makefile
	make -C rom
#-------------------------------
#-- Compilacion y simulacion
#-------------------------------
tb.vcd: tb.v $(DEPSIM) out.hex
	
	#-- Compilar
	iverilog tb.v -o tb.out -DSIMULATION -DSIM 
	
	#-- Simular
	./tb.out
	

#------------------------------
#-- Sintesis completa
#------------------------------
main.bin: pines.pcf main.v $(DEPSINT) out.hex Makefile
	#-- Sintesis 
	yosys -p "synth_ice40 -relut" -o main.json main.v >sint.log
	#-- Place & route
	nextpnr-ice40 --hx4k --pcf pines.pcf --json main.json --asc main.txt --package tq144 2>pnr.log
	#-- Generar binario final, listo para descargar en fgpa
	icepack main.txt main.bin

maincream.bin: pines_icecream.pcf main.v $(DEPSINT) out.hex Makefile
	#-- Sintesis 
	yosys -p "synth_ice40 -relut" -o main.json main.v >sint.log
	#-- Place & route
	nextpnr-ice40 --hx4k --pcf pines_icecream.pcf  --json main.json --asc main.txt --package tq144 2>pnr.log
	#-- Generar binario final, listo para descargar en fgpa
	icepack main.txt maincream.bin

#----------------------------------------------------------
#-- Sintesis de sólo el core para ver cuantas celdas ocupa
#----------------------------------------------------------
mainCPU.bin:	pinesCPU.pcf mainCPU.v cpu6502.v 
	yosys -p "synth_ice40 -relut" -o mainCPU.json mainCPU.v >sintCPU.log
	nextpnr-ice40 --hx1k --pcf pinesCPU.pcf --json mainCPU.json --asc mainCPU.txt --package tq144 2>pnrCPU.log
	icepack mainCPU.txt mainCPU.bin

#-- Limpiar todo
clean:
	rm -f *.bin *.txt *.blif *.out *.vcd *.json *.log *.o65 *~

.PHONY: all clean

pack:	Makefile
	tar czvf ~/raspcloud/public_html/drm65/drm65.tgz -C ../ drm65/apps drm65/basic drm65/rom drm65/cpu6502.v \
	drm65/main.v drm65/pll.v drm65/system.v drm65/tb.v drm65/uart_simple.v drm65/video.v \
	drm65/Makefile drm65/pines.pcf drm65/tb.gtkw
	
