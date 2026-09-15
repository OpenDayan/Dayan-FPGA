BASE_DIR=$(abspath ./)

CONFIG?=rvtsoc
FPGA_DMA ?= xdma
FPGA_ILA ?= 0
FPGA_ILA_DEPTH ?= 4096
export FPGA_DMA FPGA_ILA FPGA_ILA_DEPTH

ifneq ($(filter $(FPGA_DMA),xdma qdma),$(FPGA_DMA))
$(error FPGA_DMA must be xdma or qdma)
endif

ifneq ($(filter $(FPGA_ILA),0 1),$(FPGA_ILA))
$(error FPGA_ILA must be 0 or 1)
endif

CONFIG_TCL=tcl/config.tcl
CONFIGS_DIR=$(BASE_DIR)/tcl/configs
TARGET_CONFIG_TCL=$(CONFIGS_DIR)/$(CONFIG).tcl

TCL_DIR=$(BASE_DIR)/tcl
PROJECT_NAME=npu-axvu13p$(if $(filter 1,$(FPGA_ILA)),-ila)
PROJECT_DIR=$(BASE_DIR)/$(PROJECT_NAME)
SYN_DIR=$(PROJECT_DIR)/$(PROJECT_NAME).runs/synth_1

OUT_DIR=$(BASE_DIR)/out$(if $(filter 1,$(FPGA_ILA)),/ila)
OUT_SYN_DIR=$(OUT_DIR)/syn
OUT_IMPL_DIR=$(OUT_DIR)/impl

.PHONY: default gen-prj syn config

default: gen-prj

config:
	cp $(TARGET_CONFIG_TCL) $(CONFIG_TCL)

$(CONFIG_TCL):
	$(MAKE) config

gen-prj: | $(CONFIG_TCL)
	cd $(TCL_DIR) && ./gen_prj.tcl

$(PROJECT_DIR):
	$(MAKE) gen-prj

syn: | $(PROJECT_DIR)
	rm -rf $(OUT_SYN_DIR)
	cd $(TCL_DIR) && ./syn.tcl
	mkdir -p $(OUT_SYN_DIR)
	rsync -av $(PROJECT_DIR)/$(PROJECT_NAME).runs/ $(OUT_SYN_DIR)/

$(SYN_DIR):
	$(MAKE) syn

impl: | $(SYN_DIR)
	rm -rf $(OUT_IMPL_DIR)
	cd $(TCL_DIR) && ./impl.tcl
	mkdir -p $(OUT_IMPL_DIR)
	rsync -av $(PROJECT_DIR)/$(PROJECT_NAME).runs/impl_1/ $(OUT_IMPL_DIR)/
