#!./vivado_wrapper.sh

set script_dir [file dirname [info script]]
source ${script_dir}/common.tcl

safe_open_project ${project_dir}/${project_name}.xpr
safe_open_bd_design $soc_bd_file

write_bd_tcl -force $soc_bd_tcl -bd_name "soc"

safe_close_bd_design
safe_close_project
