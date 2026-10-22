#!./vivado_wrapper.sh

set tcl_dir [file dirname [info script]]
source ${tcl_dir}/common.tcl

safe_open_project ${project_dir}/${project_name}.xpr
safe_open_bd_design $soc_bd_file

write_bd_tcl -force -no_ip_version $soc_bd_tcl -bd_name "soc"

safe_close_bd_design
safe_close_project
