add_files -norecurse src/z1top_uart_rx.v
add_files -norecurse src/button_parser.v
add_files -norecurse src/debouncer.v
add_files -norecurse src/synchronizer.v
add_files -norecurse src/edge_detector.v
add_files -norecurse src/display_controller.v
add_files -norecurse src/clk_wiz.v
add_files -norecurse src/pixel_stream.v
add_files -norecurse src/fifo.v
add_files -norecurse src/uart_receiver.v
# Add memory initialization file
add_files -norecurse src/ucb_wheeler_hall_bin.mif

# This project needs Block Design
source scripts/z1top_uart_rx_bd.tcl
