#!./vivado_wrapper.sh

set tcl_dir [file dirname [info script]]
source ${tcl_dir}/common.tcl

puts "Using $jobs parallel jobs for synthesis and implementation."
puts "Max threads: [get_param general.maxThreads]"

# project
safe_open_project ${project_dir}/${project_name}.xpr

reset_run synth_1

launch_runs synth_1 -jobs $jobs

# Wait for synthesis to complete
set last_runs []

while {1} {
    set last_runs_new [get_runs -filter {STATUS != "synth_design Complete!" && IS_SYNTHESIS}]
    if {[llength $last_runs_new] == 0} {
        break
    }
    if {$last_runs != $last_runs_new} {
        set last_runs $last_runs_new
        set runs_name [get_property NAME $last_runs]
        puts "Waiting: $runs_name"
    }
    after 1000
}

wait_on_run synth_1

# Close project
safe_close_project
