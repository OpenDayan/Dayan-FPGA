#!./vivado_wrapper.sh

set tcl_dir [file dirname [info script]]
source ${tcl_dir}/common.tcl

puts "Using $jobs parallel jobs for synthesis and implementation."
puts "Max threads: [get_param general.maxThreads]"

# project
safe_open_project ${project_dir}/${project_name}.xpr

set run_obj [get_runs synth_1]
set status [get_property STATUS $run_obj]
set needs_refresh [get_property NEEDS_REFRESH $run_obj]

if { $needs_refresh || ![string match "*Complete*" $status] } {
    puts "synth_1 is not complete or needs refresh"
} else {
    reset_run impl_1

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
}

# Close project
safe_close_project
