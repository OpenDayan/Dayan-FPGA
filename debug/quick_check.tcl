# Validate the production ILA connection script on a small BD without synthesis.
if {$argc != 2} {
    error "Usage: quick_check.tcl <generated/debug/ila_probes.tcl> <output-directory>"
}
set script_dir [file dirname [file normalize [info script]]]
set schema_file [file normalize [lindex $argv 0]]
set output_dir [file normalize [lindex $argv 1]]
file mkdir $output_dir
source $schema_file

set axi_fields {
    {awvalid input 1} {awready output 1} {awaddr input 32} {awid input 4}
    {awlen input 8} {awsize input 3} {awburst input 2} {awlock input 1}
    {awcache input 4} {awprot input 3} {awqos input 4} {awregion input 4}
    {arvalid input 1} {arready output 1} {araddr input 32} {arid input 4}
    {arlen input 8} {arsize input 3} {arburst input 2} {arlock input 1}
    {arcache input 4} {arprot input 3} {arqos input 4} {arregion input 4}
    {wvalid input 1} {wready output 1} {wdata input 64} {wstrb input 8} {wlast input 1}
    {rvalid output 1} {rready input 1} {rdata output 64} {rid output 4} {rlast output 1} {rresp output 2}
    {bvalid output 1} {bready input 1} {bid output 4} {bresp output 2}
}
set ports [list {input wire clock}]
set assignments {}
foreach field $axi_fields {
    lassign $field name direction width
    lappend ports [format {(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi %s" *) %s wire [%d:0] s_axi_%s} \
        [string toupper $name] $direction [expr {$width - 1}] $name]
    if {$direction eq "output"} {
        lappend assignments "assign s_axi_$name = 0;"
    }
}
foreach probe $npu_ila_probes {
    lassign $probe name width
    lappend ports [format {output wire [%d:0] ila_%s} [expr {$width - 1}] $name]
    lappend assignments "assign ila_$name = 0;"
}
set fixture_file [file join $output_dir IlaCheckDut.v]
set fd [open $fixture_file w]
puts $fd "module IlaCheckDut (\n[join $ports ,\n]\n);\n[join $assignments \n]\nendmodule"
close $fd

create_project -force ila_check [file join $output_dir project] -part xcvu13p-fhgb2104-2-i
add_files $fixture_file
create_bd_design check
create_bd_cell -type module -reference IlaCheckDut dut
set clock_port [create_bd_port -dir I -type clk clock]
set_property CONFIG.FREQ_HZ 50000000 $clock_port
set resetn_port [create_bd_port -dir I -type rst resetn]
set_property CONFIG.POLARITY ACTIVE_LOW $resetn_port
set_property CONFIG.ASSOCIATED_RESET resetn $clock_port
set_property CONFIG.ASSOCIATED_BUSIF front $clock_port
connect_bd_net $clock_port [get_bd_pins dut/clock]
set front [create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 front]
set_property -dict [list CONFIG.PROTOCOL AXI4 CONFIG.ADDR_WIDTH 32 CONFIG.DATA_WIDTH 64 CONFIG.ID_WIDTH 4 CONFIG.FREQ_HZ 50000000] $front
connect_bd_intf_net $front [get_bd_intf_pins dut/s_axi]

source [file join $script_dir add_ila.tcl]
npu_add_cluster_ila dut $schema_file 4096 $resetn_port
assign_bd_address
validate_bd_design -force
save_bd_design

npu_check_cluster_ila $schema_file
puts "ILA_QUICK_CHECK_PASS: [llength $npu_ila_probes] named probes and AXI4 interface monitor"
close_project
