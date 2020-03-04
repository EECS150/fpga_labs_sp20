
## proj={z1top_uart_rx, z1top_uart_tx, z1top_uart_echo, z1top_draw_triangle}

##### Examples

## make build-project proj=z1top_uart_tx
## make sim proj=z1top_uart_tx tb=uart_transmitter_tb
## make impl proj=z1top_uart_tx
## make write-bitstream proj=z1top_uart_tx
## make program-fpga bs=bitstream_files/z1top_uart_tx.bit

#####

VERILOG_SRCS = src/*.v
vivado_proj_file = $(proj)_proj/$(proj)_proj.xpr

.PHONY: build-project
$(vivado_proj_file) build-project: $(VERILOG_SRCS)
		vivado -mode batch -source scripts/build_project.tcl -tclargs $(proj)

.PHONY: sim
sim: $(vivado_proj_file)
		vivado -mode batch -source scripts/sim.tcl -tclargs $(proj) $(tb)

.PHONY: impl
impl: $(vivado_proj_file)
		vivado -mode batch -source scripts/impl.tcl -tclargs $(proj)

.PHONY: write-bitstream
write-bitstream: $(vivado_proj_file)
		vivado -mode batch -source scripts/write_bitstream.tcl -tclargs $(proj)

.PHONY: program-fpga
program-fpga:
		vivado -mode batch -source scripts/program_fpga.tcl -tclargs $(bs)

.PHONY: clean
# "make clean" won't remove your project folders
clean:
		rm -rf *.log *.jou *.str
