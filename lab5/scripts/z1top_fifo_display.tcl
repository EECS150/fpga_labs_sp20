create_project -force z1top_fifo_display_proj z1top_fifo_display_proj -part xc7z020clg400-1

set_property board_part www.digilentinc.com:pynq-z1:part0:1.0 [current_project]

# Add source files
add_files -norecurse src/z1top_fifo_display.v
add_files -norecurse src/button_parser.v
add_files -norecurse src/debouncer.v
add_files -norecurse src/synchronizer.v
add_files -norecurse src/edge_detector.v
add_files -norecurse src/display_controller.v
add_files -norecurse src/clk_wiz.v
add_files -norecurse src/pixel_stream.v
add_files -norecurse src/fifo.v

add_files -norecurse ../lib/EECS151.v

# Add memory initialization file
add_files -norecurse src/ucb_wheeler_hall_bin.mif

# Add constraint file
add_files -fileset constrs_1 -norecurse constrs/pynq-z1.xdc

update_compile_order -fileset sources_1

check_syntax

update_compile_order -fileset sources_1

set_property ip_repo_paths digilent_ips [current_project]
update_ip_catalog

create_bd_design "z1top_fifo_display_bd"

#create_bd_cell -type ip -vlnv digilentinc.com:ip:rgb2dvi:1.4 rgb2dvi_0
# Create instance: rgb2dvi_0, and set properties
set rgb2dvi_0 [ create_bd_cell -type ip -vlnv digilentinc.com:ip:rgb2dvi:1.4 rgb2dvi_0 ]
set_property -dict [ list CONFIG.kClkRange {3} ] $rgb2dvi_0

# Create instance: z1top_fifo_display_0, and set properties
set z1top_fifo_display_0 [create_bd_cell -type module -reference z1top_fifo_display z1top_fifo_display_0]

# Create interface ports
set TMDS_0 [ create_bd_intf_port -mode Master -vlnv digilentinc.com:interface:tmds_rtl:1.0 TMDS_0 ]

# Create ports
set BUTTONS [ create_bd_port -dir I -from 3 -to 0 BUTTONS ]
set CLK_125MHZ_FPGA [ create_bd_port -dir I CLK_125MHZ_FPGA ]
set LEDS [ create_bd_port -dir O -from 5 -to 0 LEDS ]
set SWITCHES [ create_bd_port -dir I -from 1 -to 0 SWITCHES ]

# Create interface connections
connect_bd_intf_net -intf_net rgb2dvi_0_TMDS [get_bd_intf_ports TMDS_0] [get_bd_intf_pins rgb2dvi_0/TMDS]

# Create port connections
connect_bd_net -net BUTTONS [get_bd_ports BUTTONS] [get_bd_pins z1top_fifo_display_0/BUTTONS]
connect_bd_net -net CLK_125MHZ_FPGA [get_bd_ports CLK_125MHZ_FPGA] [get_bd_pins z1top_fifo_display_0/CLK_125MHZ_FPGA]
connect_bd_net -net SWITCHES [get_bd_ports SWITCHES] [get_bd_pins z1top_fifo_display_0/SWITCHES]
connect_bd_net -net z1top_fifo_display_0_LEDS [get_bd_ports LEDS] [get_bd_pins z1top_fifo_display_0/LEDS]
connect_bd_net -net z1top_fifo_display_0_pixel_clk [get_bd_pins rgb2dvi_0/PixelClk] [get_bd_pins z1top_fifo_display_0/pixel_clk]
connect_bd_net -net z1top_fifo_display_0_video_out_pData [get_bd_pins rgb2dvi_0/vid_pData] [get_bd_pins z1top_fifo_display_0/video_out_pData]
connect_bd_net -net z1top_fifo_display_0_video_out_pHSync [get_bd_pins rgb2dvi_0/vid_pHSync] [get_bd_pins z1top_fifo_display_0/video_out_pHSync]
connect_bd_net -net z1top_fifo_display_0_video_out_pVDE [get_bd_pins rgb2dvi_0/vid_pVDE] [get_bd_pins z1top_fifo_display_0/video_out_pVDE]
connect_bd_net -net z1top_fifo_display_0_video_out_pVSync [get_bd_pins rgb2dvi_0/vid_pVSync] [get_bd_pins z1top_fifo_display_0/video_out_pVSync]

validate_bd_design
save_bd_design

make_wrapper -files [get_files z1top_fifo_display_proj/z1top_fifo_display_proj.srcs/sources_1/bd/z1top_fifo_display_bd/z1top_fifo_display_bd.bd] -top
add_files -norecurse           z1top_fifo_display_proj/z1top_fifo_display_proj.srcs/sources_1/bd/z1top_fifo_display_bd/hdl/z1top_fifo_display_bd_wrapper.v
update_compile_order -fileset sources_1
set_property top z1top_fifo_display_bd_wrapper [current_fileset]
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

exec cp z1top_fifo_display_proj/z1top_fifo_display_proj.runs/impl_1/z1top_fifo_display_bd_wrapper.bit z1top_fifo_display.bit

