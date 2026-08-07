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
set error_runs []

while {1} {
    set error_runs [get_runs -quiet -filter {STATUS =~ "*ERROR*" && IS_SYNTHESIS}]
    if {[llength $error_runs] != 0} {
        break
    }

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

if {[llength $error_runs] != 0} {
    set error_runs_name [get_property NAME $error_runs]

    foreach error_run $error_runs {
        set error_run_name [get_property NAME $error_run]
        set error_run_status [get_property STATUS $error_run]
        set error_run_log [file join [get_property DIRECTORY $error_run] runme.log]

        puts stderr "ERROR: Synthesis run '$error_run_name' failed with status '$error_run_status'."
        puts stderr "ERROR: Synthesis log: $error_run_log"

        if {[file exists $error_run_log]} {
            set error_log_fd [open $error_run_log r]
            while {[gets $error_log_fd error_log_line] >= 0} {
                if {[string first "ERROR:" $error_log_line] >= 0} {
                    puts stderr $error_log_line
                }
            }
            close $error_log_fd
        } else {
            puts stderr "ERROR: Synthesis log file does not exist."
        }
    }

    error "Synthesis failed for run(s): $error_runs_name"
}

wait_on_run synth_1

# Close project
safe_close_project
