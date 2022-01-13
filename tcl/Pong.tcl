#file based of template from INF3500 class given by Pierre Langlois					   

# read all files
read_ip  ../ip/xadc_wiz_1.xci 
synth_ip [get_files ../ip/xadc_wiz_1.xci ]  
read_vhdl -vhdl2008 ../src/Pong_utils.vhd	
read_vhdl -vhdl2008 ../src/clock_gen.vhd
read_vhdl -vhdl2008 ../src/vga_ctrl.vhd
read_vhdl -vhdl2008 ../src/Pong_GameLoop.vhd
read_vhdl -vhdl2008 ../src/top_Pong_8x8Matrix.vhd

read_xdc ../xdc/basys_3_top.xdc

synth_design -top top_Pong_8x8Matrix -part xc7a35tcpg236-1 -assert

# Implementation
place_design
route_design   

#generate bitstream
write_bitstream -force Pong_8x8.bit

# program FPGA
open_hw_manager
connect_hw_server
get_hw_targets
open_hw_target

current_hw_device [get_hw_devices xc7a35t_0]
set_property PROGRAM.FILE {Pong_8x8.bit} [get_hw_devices xc7a35t_0]
program_hw_devices [get_hw_devices xc7a35t_0]