BASE_DIR=$(abspath ./)

CONFIG?=rvtsoc

CONFIG_TCL=tcl/config.tcl
CONFIGS_DIR=$(BASE_DIR)/tcl/configs
TARGET_CONFIG_TCL=$(CONFIGS_DIR)/$(CONFIG).tcl

TCL_DIR=$(BASE_DIR)/tcl
PROJECT_DIR=$(BASE_DIR)/npu-axvu13p
SYN_DIR=$(PROJECT_DIR)/npu-axvu13p.runs/synth_1

OUT_SYN_DIR=$(BASE_DIR)/out/syn
OUT_IMPL_DIR=$(BASE_DIR)/out/impl

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
	cd $(TCL_DIR) && ./syn.tcl
	mkdir -p $(OUT_SYN_DIR)
	rsync -av $(PROJECT_DIR)/npu-axvu13p.runs/ $(OUT_SYN_DIR)/

$(SYN_DIR):
	$(MAKE) syn

impl: | $(SYN_DIR)
	cd $(TCL_DIR) && ./impl.tcl
	mkdir -p $(OUT_IMPL_DIR)
	rsync -av $(PROJECT_DIR)/npu-axvu13p.runs/impl_1/ $(OUT_IMPL_DIR)/
