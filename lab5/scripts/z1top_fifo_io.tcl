create_project -force z1top_fifo_io_proj z1top_fifo_io_proj -part xc7z020clg400-1

set_property board_part www.digilentinc.com:pynq-z1:part0:1.0 [current_project]

# Add source files
add_files -norecurse src/z1top_fifo_io.v
add_files -norecurse src/button_parser.v
add_files -norecurse src/debouncer.v
add_files -norecurse src/synchronizer.v
add_files -norecurse src/edge_detector.v
add_files -norecurse src/fifo.v

add_files -norecurse ../lib/EECS151.v

# Add constraint file
add_files -fileset constrs_1 -norecurse constrs/pynq-z1.xdc

update_compile_order -fileset sources_1

check_syntax

update_compile_order -fileset sources_1
set_property top z1top_fifo_io [current_fileset]
update_compile_order -fileset sources_1

### Run Synthesis, Implementation, and Generate Bitstream
launch_runs synth_1
wait_on_run synth_1 -verbose

if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {   
  error "ERROR: synth_1 failed"   
} 

launch_runs -verbose impl_1 -to_step write_bitstream
wait_on_run impl_1 -verbose
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {   
  error "ERROR: impl_1 failed"   
} 

exec cp z1top_fifo_io_proj/z1top_fifo_io_proj.runs/impl_1/z1top_fifo_io.bit z1top_fifo_io.bit

