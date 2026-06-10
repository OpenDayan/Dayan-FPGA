
set tcl_dir [file dirname [info script]]

set root_dir "${tcl_dir}/.."

set project_name "npu-axvu13p"
set project_dir "${root_dir}/${project_name}"

set rpt_dir "${root_dir}/rpt"

set soc_bd_tcl "${root_dir}/src/bd/soc_bd.tcl"
set soc_bd_file "${project_dir}/npu-axvu13p.srcs/sources_1/bd/soc/soc.bd"
set soc_bd_wrapper_file "${project_dir}/npu-axvu13p.srcs/sources_1/bd/soc/hdl/soc_wrapper.v"

set clk_wiz_path "/clk_wiz_0"

source $tcl_dir/config.tcl

set top_module "soc_wrapper"

set sockets [exec lscpu | grep "Socket(s)" | awk "{print \$2}"]
set cores_per_socket [exec lscpu | grep "Core(s) per socket" | awk "{print \$4}"]
set jobs [expr {$sockets * $cores_per_socket}]
if {$jobs <= 0} {
    set jobs 4
}

set_param general.maxThreads 8

if {![info exists safe_project_opened_by_script]} {
    set safe_project_opened_by_script 0
}
if {![info exists safe_bd_opened_by_script]} {
    set safe_bd_opened_by_script 0
}

proc safe_current_project_file {} {
    set cur_project [current_project -quiet]
    if {$cur_project eq ""} {
        return ""
    }

    set project_file ""
    catch {set project_file [get_property FILE $cur_project]}
    if {$project_file ne ""} {
        return [file normalize $project_file]
    }

    set project_dir ""
    set project_name ""
    catch {set project_dir [get_property DIRECTORY $cur_project]}
    catch {set project_name [get_property NAME $cur_project]}
    if {$project_dir eq "" || $project_name eq ""} {
        return ""
    }

    return [file normalize "${project_dir}/${project_name}.xpr"]
}

proc safe_open_project {project_file} {
    global safe_project_opened_by_script

    set requested_project_file [file normalize $project_file]
    set cur_project_file [safe_current_project_file]

    if {$cur_project_file ne ""} {
        if {$cur_project_file eq $requested_project_file} {
            puts "Project already open: $requested_project_file"
            return
        }

        error "Another project is already open: $cur_project_file"
    }

    open_project $requested_project_file
    set safe_project_opened_by_script 1
}

proc safe_close_project {} {
    global safe_project_opened_by_script

    if {$safe_project_opened_by_script} {
        close_project
        set safe_project_opened_by_script 0
    } else {
        puts "Project was not opened by this script; skip close_project."
    }
}

proc safe_current_bd_file {} {
    set cur_bd [current_bd_design -quiet]
    if {$cur_bd eq ""} {
        return ""
    }

    set bd_file ""
    catch {set bd_file [get_property FILE $cur_bd]}
    if {$bd_file ne ""} {
        return [file normalize $bd_file]
    }

    set bd_name ""
    catch {set bd_name [get_property NAME $cur_bd]}
    if {$bd_name eq ""} {
        set bd_name $cur_bd
    }

    set bd_files [get_files -quiet "${bd_name}.bd"]
    if {[llength $bd_files] > 0} {
        set bd_file ""
        catch {set bd_file [get_property FILE [lindex $bd_files 0]]}
        if {$bd_file eq ""} {
            catch {set bd_file [get_property NAME [lindex $bd_files 0]]}
        }
        if {$bd_file ne ""} {
            return [file normalize $bd_file]
        }
    }

    return ""
}

proc safe_current_bd_name {} {
    set cur_bd [current_bd_design -quiet]
    if {$cur_bd eq ""} {
        return ""
    }

    set bd_name ""
    catch {set bd_name [get_property NAME $cur_bd]}
    if {$bd_name ne ""} {
        return $bd_name
    }

    return $cur_bd
}

proc safe_open_bd_design {bd_file} {
    global safe_bd_opened_by_script

    set requested_bd_file [file normalize $bd_file]
    set requested_bd_name [file rootname [file tail $requested_bd_file]]
    set cur_bd_file [safe_current_bd_file]
    set cur_bd_name [safe_current_bd_name]

    if {$cur_bd_file ne ""} {
        if {$cur_bd_file eq $requested_bd_file} {
            puts "Block design already open: $requested_bd_file"
            return
        }

        error "Another block design is already open: $cur_bd_file"
    }

    if {$cur_bd_name ne ""} {
        if {$cur_bd_name eq $requested_bd_name} {
            puts "Block design already open: $requested_bd_name"
            return
        }

        error "Another block design is already open: $cur_bd_name"
    }

    open_bd_design $requested_bd_file
    set safe_bd_opened_by_script 1
}

proc safe_close_bd_design {} {
    global safe_bd_opened_by_script

    if {$safe_bd_opened_by_script} {
        close_bd_design [current_bd_design]
        set safe_bd_opened_by_script 0
    } else {
        puts "Block design was not opened by this script; skip close_bd_design."
    }
}
