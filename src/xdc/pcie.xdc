create_clock -period 10.000 -name sys_clk [get_ports PCIe_clk_p]

set_false_path -from [get_ports PCIe_rst_n]
set_property PULLUP true [get_ports PCIe_rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports PCIe_rst_n]

set_property PACKAGE_PIN AR26 [get_ports PCIe_rst_n]

set_property PACKAGE_PIN AH10 [get_ports PCIe_clk_n]
set_property PACKAGE_PIN AH11 [get_ports PCIe_clk_p]


set_property PACKAGE_PIN BC2 [get_ports {pci_exp_rxp[15]}]
set_property PACKAGE_PIN BA2 [get_ports {pci_exp_rxp[14]}]
set_property PACKAGE_PIN AW4 [get_ports {pci_exp_rxp[13]}]
set_property PACKAGE_PIN AV2 [get_ports {pci_exp_rxp[12]}]
set_property PACKAGE_PIN AU4 [get_ports {pci_exp_rxp[11]}]
set_property PACKAGE_PIN AT2 [get_ports {pci_exp_rxp[10]}]
set_property PACKAGE_PIN AR4 [get_ports {pci_exp_rxp[9]}]
set_property PACKAGE_PIN AP2 [get_ports {pci_exp_rxp[8]}]
set_property PACKAGE_PIN AN4 [get_ports {pci_exp_rxp[7]}]
set_property PACKAGE_PIN AM2 [get_ports {pci_exp_rxp[6]}]
set_property PACKAGE_PIN AL4 [get_ports {pci_exp_rxp[5]}]
set_property PACKAGE_PIN AK2 [get_ports {pci_exp_rxp[4]}]
set_property PACKAGE_PIN AJ4 [get_ports {pci_exp_rxp[3]}]
set_property PACKAGE_PIN AH2 [get_ports {pci_exp_rxp[2]}]
set_property PACKAGE_PIN AG4 [get_ports {pci_exp_rxp[1]}]
set_property PACKAGE_PIN AF2  [get_ports {pci_exp_rxp[0]}]


set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets */*/util_ds_buf_0/U0/IBUF_OUT[0]] 

