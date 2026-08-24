#!./vivado_wrapper.sh

set tcl_dir [file dirname [info script]]
source ${tcl_dir}/common.tcl

safe_open_project ${project_dir}/${project_name}.xpr
safe_open_bd_design $soc_bd_file

set_property CONFIG.NUM_SI [expr {${dut_axi_m_num} + 1}] [get_bd_cells smartconnect_0]

create_bd_cell -type module -reference ${dut_mod_name} ${dut_mod_name}_0

connect_bd_intf_net [get_bd_intf_pins ${dut_mod_name}_0/s_axi] [get_bd_intf_pins smartconnect_1/M01_AXI]

# Connect each DUT master AXI interface to a slave port of smartconnect_0.
# S00_AXI is already occupied by smartconnect_1, so DUT masters use S01_AXI, S02_AXI, ...
set dut_axi_s_start 1
foreach m_name ${dut_axi_m_names} {
    set s_idx [format "%02d" $dut_axi_s_start]
    connect_bd_intf_net [get_bd_intf_pins ${dut_mod_name}_0/${m_name}] [get_bd_intf_pins smartconnect_0/S${s_idx}_AXI]
    incr dut_axi_s_start
}
connect_bd_net [get_bd_pins ${dut_mod_name}_0/clock] [get_bd_pins clk_wiz_0/clk_out1]
connect_bd_net [get_bd_pins ${dut_mod_name}_0/reset] [get_bd_pins proc_sys_reset_0/bus_struct_reset]
if {[info exists dut_int_name]} {
    connect_bd_net [get_bd_pins ${dut_mod_name}_0/$dut_int_name] [get_bd_pins qdma/usr_irq_req]
}

regenerate_bd_layout

foreach m_name ${dut_axi_m_names} {
    assign_bd_address -target_address_space /${dut_mod_name}_0/${m_name} [get_bd_addr_segs ddr4/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
}
assign_bd_address -target_address_space /qdma/qdma_0/M_AXI [get_bd_addr_segs ${dut_mod_name}_0/s_axi/reg0] -force


assign_bd_address -offset ${dut_addr_offset} -range ${dut_addr_range} [get_bd_addr_segs qdma/qdma_0/M_AXI/SEG_${dut_mod_name}_0_reg0]

assign_bd_address -offset ${ddr_addr_offset} -range ${ddr_addr_range} [get_bd_addr_segs {qdma/qdma_0/M_AXI/SEG_ddr4_0_C0_DDR4_ADDRESS_BLOCK}]
assign_bd_address -offset ${ddr_addr_offset} -range ${ddr_addr_range} [get_bd_addr_segs ddr4/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK]

validate_bd_design -force
save_bd_design [current_bd_design]

safe_close_bd_design
safe_close_project
