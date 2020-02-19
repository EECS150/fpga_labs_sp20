
z1top_fifo_io:
		vivado -mode batch -source scripts/z1top_fifo_io.tcl

z1top_fifo_display:
		vivado -mode batch -source scripts/z1top_fifo_display.tcl

program-fpga: $(bs)
		vivado -mode batch -source scripts/program_fpga.tcl -tclargs $(bs)

# "Make clean" won't remove your project folders
clean:
		rm -rf *.log *.jou
