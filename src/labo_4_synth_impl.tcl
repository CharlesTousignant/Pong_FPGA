# -------------------------------------------------------------------------------
# labo_4_synth_impl.tcl
#
# Il faut d'abord ouvrir une fenêtre d'invite de commande (dans Windows : cmd).
# Ensuite naviguer dans le bon répertoire, par exemple user\docs\poly\inf3500\labo4\synthese-implementation
#
# On peut lancer Vivado avec la commande "C:\Xilinx\Vivado\2021.1\bin\vivado -mode tcl"
# (** doit correspondre à la version de Vivado que vous avez installée **)
#
# Ensuite, on peut copier-coller les commandes du présent fichier une à une ou en groupe,
# selon les besoins afin d'avancer dans le flot selon son rythme et les erreurs qui peuvent survenir.
#
# Il faut commenter et dé-commenter les lignes qui correspondent à votre carte.
#
# -------------------------------------------------------------------------------

# fermer tout design présentement actif
close_design

# lecture des fichiers
remove_files [get_files]							   
read_ip  ../../ip/xadc_wiz_0/xadc_wiz_0.xci 
synth_ip [get_files ../../ip/xadc_wiz_0/xadc_wiz_0.xci ]  
read_vhdl -vhdl2008 utilitaires_inf3500_pkg.vhd
read_vhdl -vhdl2008 Pong_utilitaires.vhd	
read_vhdl -vhdl2008 718293_001_fixed_generic_pkg_mod.vhdl
read_vhdl -vhdl2008 generateur_horloge_precis.vhd
read_vhdl -vhdl2008 MandelBrot.vhd
read_vhdl -vhdl2008 ../../new/MandelBrot_controller.vhd
read_vhdl -vhdl2008 vga_ctrl.vhd
read_vhdl -vhdl2008 Pong_8x8Matrix.vhd	  
read_vhdl -vhdl2008 Pong_GameLoop.vhd
read_vhdl -vhdl2008 top_Pong_8x8Matrix.vhd

# choisir la ligne qui correspond à votre carte
read_xdc ../../../constrs_1/imports/xdc/basys_3_top.xdc
#read_xdc ../xdc/nexys_a7_50t_top.xdc
#read_xdc ../xdc/nexys_a7_100t_top.xdc

#synthese - choisir la ligne qui correspond à votre carte
synth_design -top top_Pong_8x8Matrix -part xc7a35tcpg236-1 -assert
#synth_design -top top_labo_4 -part xC7a50TCSG324 -assert
#synth_design -top top_labo_4 -part xC7a100TCSG324 -assert

#implémentation (placement et routage)
place_design
route_design   


#génération du fichier de configuration
write_bitstream -force Pong_8x8.bit

# programmation du FPGA
open_hw_manager
connect_hw_server
get_hw_targets
open_hw_target

# chosir les trois lignes qui correpondent à votre carte
current_hw_device [get_hw_devices xc7a35t_0]
set_property PROGRAM.FILE {Pong_8x8.bit} [get_hw_devices xc7a35t_0]
program_hw_devices [get_hw_devices xc7a35t_0]

#current_hw_device [get_hw_devices xc7a50t_0]
#set_property PROGRAM.FILE {labo_4.bit} [get_hw_devices xc7a50t_0]
#program_hw_devices [get_hw_devices xc7a50t_0]

#current_hw_device [get_hw_devices xc7a100t_0]
#set_property PROGRAM.FILE {labo_4.bit} [get_hw_devices xc7a100t_0]
#program_hw_devices [get_hw_devices xc7a100t_0]
