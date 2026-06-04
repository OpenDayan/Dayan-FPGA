#!./vivado_wrapper.sh

set script_dir [file dirname [info script]]
source ${script_dir}/common.tcl

safe_open_project ${project_dir}/${project_name}.xpr
safe_open_bd_design $soc_bd_file

create_bd_cell -type module -reference ${dut_mod_name} ${dut_mod_name}_0

connect_bd_intf_net [get_bd_intf_pins ${dut_mod_name}_0/s_axi] [get_bd_intf_pins smartconnect_1/M00_AXI]
connect_bd_intf_net [get_bd_intf_pins ${dut_mod_name}_0/m_axi] [get_bd_intf_pins smartconnect_0/S00_AXI]
connect_bd_net [get_bd_pins ${dut_mod_name}_0/clock] [get_bd_pins clk_wiz_0/clk_out1]
connect_bd_net [get_bd_pins ${dut_mod_name}_0/reset] [get_bd_pins proc_sys_reset_0/bus_struct_reset]
connect_bd_net [get_bd_pins ${dut_mod_name}_0/int_usr_irq_ack] [get_bd_pins xdma/usr_irq_ack]
connect_bd_net [get_bd_pins ${dut_mod_name}_0/int_usr_irq_req] [get_bd_pins xdma/usr_irq_req]

regenerate_bd_layout

assign_bd_address -target_address_space /${dut_mod_name}_0/m_axi [get_bd_addr_segs ddr4/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
assign_bd_address -target_address_space /xdma/xdma_0/M_AXI [get_bd_addr_segs ${dut_mod_name}_0/s_axi/reg0] -force
set_property range ${dut_addr_range} [get_bd_addr_segs xdma/xdma_0/M_AXI/SEG_${dut_mod_name}_0_reg0]
set_property offset ${dut_addr_offset} [get_bd_addr_segs xdma/xdma_0/M_AXI/SEG_${dut_mod_name}_0_reg0]

validate_bd_design -force
save_bd_design [current_bd_design]

safe_close_bd_design
safe_close_project
