
## This file is a general .xdc for the Nexys4 rev B board
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

set_property PACKAGE_PIN E3 [get_ports clk]							
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name clk -period 10.00 -waveform {0 5} [get_ports clk]

##7 ALU INPUT
#Bank = 34, Pin name = IO_L21P_T3_DQS_34,						Sch name = SW0
set_property PACKAGE_PIN U9 [get_ports {start_ext}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {start_ext}]


###7 segment display
##Bank = 34, Pin name = IO_L2N_T0_34,						Sch name = CA
#set_property PACKAGE_PIN L3 [get_ports {seven_seg[0]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {seven_seg[0]}]
##Bank = 34, Pin name = IO_L3N_T0_DQS_34,					Sch name = CB
#set_property PACKAGE_PIN N1 [get_ports {seven_seg[1]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {seven_seg[1]}]
##Bank = 34, Pin name = IO_L6N_T0_VREF_34,					Sch name = CC
#set_property PACKAGE_PIN L5 [get_ports {seven_seg[2]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {seven_seg[2]}]
##Bank = 34, Pin name = IO_L5N_T0_34,						Sch name = CD
#set_property PACKAGE_PIN L4 [get_ports {seven_seg[3]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {seven_seg[3]}]
##Bank = 34, Pin name = IO_L2P_T0_34,						Sch name = CE
#set_property PACKAGE_PIN K3 [get_ports {seven_seg[4]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {seven_seg[4]}]
##Bank = 34, Pin name = IO_L4N_T0_34,						Sch name = CF
#set_property PACKAGE_PIN M2 [get_ports {seven_seg[5]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {seven_seg[5]}]
##Bank = 34, Pin name = IO_L6P_T0_34,						Sch name = CG
#set_property PACKAGE_PIN L6 [get_ports {seven_seg[6]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {seven_seg[6]}]


##Bank = 34, Pin name = IO_L18N_T2_34,						Sch name = AN0
#set_property PACKAGE_PIN N6 [get_ports {anode}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {anode}]


#Bank = 15, Pin name = IO_L3P_T0_DQS_AD1P_15,                                  Sch name = CPU_RESET
set_property PACKAGE_PIN C12 [get_ports {rst}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {rst}]



