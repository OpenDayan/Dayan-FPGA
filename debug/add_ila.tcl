# System ILA owns its generated timing constraints; no extra CDC exceptions.
proc npu_add_cluster_ila {dut schema_file depth resetn} {
    if {![file isfile $schema_file]} {
        error "Missing ILA schema: $schema_file. Regenerate ClusterWrapper RTL."
    }
    source $schema_file
    set count [llength $npu_ila_probes]
    if {$count == 0} {
        error "The ILA probe schema is empty"
    }

    set ila [create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.1 npu_ila]
    set properties [list \
        CONFIG.C_MON_TYPE MIX \
        CONFIG.C_NUM_MONITOR_SLOTS 1 \
        CONFIG.C_NUM_OF_PROBES $count \
        CONFIG.C_DATA_DEPTH $depth \
        CONFIG.C_EN_STRG_QUAL 1 \
        CONFIG.C_SLOT_0_AXI_PROTOCOL AXI4]
    set_property -dict $properties $ila
    foreach probe $npu_ila_probes {
        lassign $probe name width
        if {![regexp {^[a-zA-Z][a-zA-Z0-9_]*$} $name] || ![string is integer -strict $width] || $width < 1} {
            error "Invalid ILA probe: $probe"
        }
    }

    connect_bd_net [get_bd_pins $dut/clock] [get_bd_pins $ila/clk]
    connect_bd_net $resetn [get_bd_pins $ila/resetn]
    connect_bd_intf_net [get_bd_intf_pins $dut/s_axi] [get_bd_intf_pins $ila/SLOT_0_AXI]

    set index 0
    foreach probe $npu_ila_probes {
        lassign $probe name width
        set pin [get_bd_pins -quiet $dut/ila_$name]
        if {[llength $pin] != 1} {
            error "Missing native probe output $dut/ila_$name"
        }
        # Named BD nets are exported as native signal names in the .ltx file.
        connect_bd_net -net ila_$name $pin [get_bd_pins $ila/probe$index]
        incr index
    }
    puts "System ILA: $npu_ila_trace_cores RTS cores, $count native probes, front AXI4 monitor, depth $depth"
}

# System ILA derives native widths from the connected RTL pins during validation.
proc npu_check_cluster_ila {schema_file} {
    source $schema_file
    set ila [get_bd_cells npu_ila]
    if {[get_property CONFIG.C_MON_TYPE $ila] ne "MIX" ||
        [get_property CONFIG.C_NUM_MONITOR_SLOTS $ila] != 1 ||
        [get_property CONFIG.C_NUM_OF_PROBES $ila] != [llength $npu_ila_probes]} {
        error "System ILA is missing an AXI monitor or native probes"
    }
    if {[llength [get_bd_intf_nets -of_objects [get_bd_intf_pins $ila/SLOT_0_AXI]]] != 1} {
        error "System ILA AXI monitor is disconnected"
    }
    set index 0
    foreach probe $npu_ila_probes {
        lassign $probe name width
        set pin [get_bd_pins $ila/probe$index]
        set left [get_property LEFT $pin]
        set right [get_property RIGHT $pin]
        set actual_width 1
        if {$left ne "" && $right ne ""} {
            set actual_width [expr {abs($left - $right) + 1}]
        }
        if {$actual_width != $width} {
            error "Incorrect ILA width for $name: pin=$actual_width, expected=$width"
        }
        if {[llength [get_bd_pins -of_objects [get_bd_nets ila_$name]]] != 2} {
            error "Incomplete ILA connection for $name"
        }
        incr index
    }
}
