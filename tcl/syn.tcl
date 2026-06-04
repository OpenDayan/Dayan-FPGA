#!./vivado_wrapper.sh

set script_dir [file dirname [info script]]
source ${script_dir}/common.tcl

set sockets [exec lscpu | grep "Socket(s)" | awk "{print \$2}"]
set cores_per_socket [exec lscpu | grep "Core(s) per socket" | awk "{print \$4}"]
set jobs [expr {$sockets * $cores_per_socket}]
if {$jobs <= 0} {
    set jobs 4
}
puts "Using $jobs parallel jobs for synthesis and implementation."

get_param general.maxThreads
set_param general.maxThreads 8
get_param general.maxThreads

# project
safe_open_project ${target_dir}/${project_name}.xpr

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

launch_runs impl_1 -jobs $jobs
wait_on_run impl_1

launch_runs impl_1 -to_step write_bitstream -jobs $jobs
wait_on_run impl_1


# Generate reports
open_run impl_1
report_timing_summary -file timing_summary.rpt
report_utilization -file utilization.rpt

# Generate reports
#report_timing_summary -file timing_summary.rpt
#report_utilization -file utilization.rpt

# Save synthesized design checkpoint
#write_checkpoint -force top_synth.dcp

# Close project
safe_close_project
