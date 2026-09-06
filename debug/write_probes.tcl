if {[llength [get_debug_cores -quiet]] == 0} {
    error "ILA build contains no debug cores"
}
set ila_probes_file [file join $project_dir ${project_name}.runs impl_1 ${top_module}.ltx]
write_debug_probes -force $ila_probes_file
if {![file isfile $ila_probes_file]} {
    error "Debug probes were not written: $ila_probes_file"
}
