#!./vivado_wrapper.sh

set tcl_dir [file dirname [info script]]
source ${tcl_dir}/common.tcl

set rtl_dir      "${root_dir}/src/rtl"
set rtl_filelist "${rtl_dir}/filelist.f"
set rtl_files    {}

set filelist_fd [open $rtl_filelist r]
while {[gets $filelist_fd rtl_file] >= 0} {
    set rtl_file [string trim $rtl_file]
    if {$rtl_file eq ""} {
        continue
    }

    if {[file pathtype $rtl_file] eq "relative"} {
        set rtl_file [file join $rtl_dir $rtl_file]
    }
    lappend rtl_files [file normalize $rtl_file]
}
close $filelist_fd

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
