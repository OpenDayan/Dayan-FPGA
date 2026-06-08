#!./vivado_wrapper.sh

set tcl_dir [file dirname [info script]]
source ${tcl_dir}/common.tcl

if {$argc != 1} {
    puts "Usage: set_clk.tcl <clk_freq_mhz>"
} else {

    safe_open_project ${project_dir}/${project_name}.xpr

    safe_open_bd_design $soc_bd_file

    set clk_freq_mhz [lindex $argv 0]

    set_property CONFIG.CLKOUT1_REQUESTED_OUT_FREQ ${clk_freq_mhz} [get_bd_cells $clk_wiz_path]

    validate_bd_design -force
    save_bd_design [current_bd_design]
    safe_close_bd_design

    safe_close_project
}
