#!./vivado_wrapper.sh

set tcl_dir [file dirname [info script]]
source ${tcl_dir}/common.tcl

set rtl_files   [glob "${root_dir}/src/rtl/*.v" glob "${root_dir}/src/rtl/*.sv"]
set xdc_files   [list "${root_dir}/src/xdc"]
# set ip_files    [glob "${root_dir}/src/ip/**/*.xci"]

# project
create_project -force $project_name $project_dir -part xcvu13p-fhgb2104-2-i

# RTL
add_files -fileset sources_1 -norecurse {*}$rtl_files
update_compile_order -fileset sources_1


# IP
# add_files -fileset sources_1 -norecurse {*}${ip_files}
# update_compile_order -fileset sources_1

# BD
source ${soc_bd_tcl}
source ${tcl_dir}/add_dut.tcl

# wrapper 
make_wrapper -files [get_files $soc_bd_file] -top
add_files -norecurse $soc_bd_wrapper_file
open_bd_design $soc_bd_file
validate_bd_design -force
close_bd_design [current_bd_design]
generate_target all [get_files $soc_bd_file]
update_compile_order -fileset sources_1

# XDC
add_files -fileset constrs_1 -norecurse {*}$xdc_files
# update_compile_order -fileset constrs_1

# Disable files
# foreach file $disable_files {
#     set_property is_enabled false [get_files $file]
# }

set_property top $top_module [current_fileset]
set_property target_language Verilog [current_project]
