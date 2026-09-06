# NPU AXVU13P Vivado 工程

基于 AXVU13P 板卡的 SoC 原型验证工程，以 Block Design（`soc`）为核心，将大衍等 chisel 生成的 NPU SoC（DUT）通过 AXI 接入 PCIe 与 DDR4，用于上板验证。

## 环境与器件

- 器件：`xcvu13p-fhgb2104-2-i`
- Vivado 版本：2024.2

## Block Design 结构

工程顶层为 `soc_wrapper`，内部 Block Design（`soc`）由以下模块构成：

| 模块 | 说明 |
| --- | --- |
| `xdma` | Xilinx XDMA IP，PCIe Gen3 x16 主机接口，作为上位机访问 SoC 寄存器和 DDR 的入口 |
| `ddr4` | DDR4 存储控制器（16G，偏移 `0x0000000000`），存放数据 |
| `smartconnect_0` | 面向 DDR4 的 AXI 互连，汇聚 DUT 主口（`S01_AXI`…）与 xdma 的访问 |
| `smartconnect_1` | 面向 DUT 寄存器接口的 AXI 互连，xdma 主口经其接入 DUT 的 `s_axi` |
| `clk_wiz_0` | 时钟模块，为 DUT 提供输入时钟（默认 50MHz，可脚本修改） |
| `proc_sys_reset` | 复位控制器，为 DUT 及互连提供复位 |

数据通路如下：

- 上位机经 PCIe（`xdma`）→ `smartconnect_1` → DUT 寄存器接口（`s_axi`），用于配置/控制 DUT。
- DUT 主口（`m_axi`）→ `smartconnect_0` → `ddr4`，用于读写数据。
- 上位机也可经 `xdma → smartconnect_1 → smartconnect_0 → ddr4` 直接访问 DDR。

### DUT slave 口地址映射

`add_dut.tcl` 会将 DUT 的寄存器 slave 口 `s_axi/reg0` 与 DDR4 空间映射到上位机（xdma PCIe）地址空间，主机侧偏移/范围由配置项 `dut_addr_*` 与 `ddr_addr_*` 决定：

| 目标空间 | 主机侧偏移 | 主机侧范围 |
| --- | --- | --- |
| DUT 寄存器 `s_axi/reg0` | `dut_addr_offset`（rvtsoc：`0x4000000000`） | `dut_addr_range`（rvtsoc：2G） |
| DDR4 | `ddr_addr_offset`（`0x0000000000`） | `ddr_addr_range`（rvtsoc：16G） |

同时，DUT 主口（`m_axi`）的地址空间也会被映射到 DDR4，使 DUT 可直接访问 `ddr4` 的存储。

Block Design 通过 `src/bd/soc_bd.tcl` 描述，DUT 的挂接与地址分配由 `tcl/add_dut.tcl` 在生成工程时按配置自动完成。

## 同步 RTL 代码

DUT 的 RTL 由 chisel 生成。以 RvtsocWrapper 为例，顶层为 `RvtsocWrapper`：

```bash
./scripts/update_rtl.sh $SRC_PATH RvtsocWrapper
```

`SRC_PATH` 为 chisel 生成代码的路径，可为本地路径或远程路径，如

- 本地路径 `/workspace/Dayan/generated/RvtsocWrapper-RvtsocConfig/`
- 远程路径 `vef:/workspace/Dayan/generated/RvtsocWrapper-RvtsocConfig/`

脚本会将源目录同步到 `src/rtl/`，并将顶层 `RvtsocWrapper.sv` 重命名为 `RvtsocWrapper.v`（若存在）。`src/rtl/filelist.f` 为参与编译的 RTL 文件清单。

## 配置工程

不同 DUT 对应不同的配置，配置文件位于 `tcl/configs/`，通过 `make config` 选择并拷贝为 `tcl/config.tcl`：

```bash
make config CONFIG=rvtsoc
```

当前提供的配置：

- `rvtsoc`（默认）：DUT 为 `RvtsocWrapper`，单 `m_axi` 主口，地址范围 2G，偏移 `0x4000000000`；DDR 范围 16G，偏移 `0x0000000000`。
- `cluster`：DUT 为 `ClusterWrapper`，两个主口 `m_axi_0` / `m_axi_1`。

配置项位于 `tcl/configs/<name>.tcl`，包括：

- `dut_mod_name`：DUT 模块名
- `dut_axi_m_names`：DUT 的 AXI 主口列表
- `dut_addr_range` / `dut_addr_offset`：DUT 寄存器空间在主机的地址范围与偏移
- `ddr_addr_range` / `ddr_addr_offset`：DDR 空间在主机的地址范围与偏移
- `dut_int_name`：DUT 中断信号名

## 生成工程

```bash
make gen-prj
```

该步骤创建 Vivado 工程 `npu-axvu13p/`，导入 `filelist.f` 中的 RTL、构建 Block Design、按配置挂接 DUT 并分配地址、生成顶层 wrapper、添加约束（`src/xdc/`）。

## 脚本修改 DUT 输入时钟频率

生成工程默认为 50MHz，可使用以下命令修改

```bash
cd tcl
./set_clk.tcl 100.000
```

## 脚本编译生成 bitstream

```bash
cd tcl
./syn.tcl
./impl.tcl
```

也可直接使用 make 目标：

```bash
make syn   # 综合
make impl  # 实现 + 写 bitstream，并生成时序/资源报告
```

综合日志（`syn.tcl`）会实时检测 run 状态，出错时打印 `runme.log` 中的 ERROR 并终止。

## 可选 System ILA

在 npu-cluster 根目录选择是否启用调试：

```bash
make verilog-fpga-rts-4c
make syn-fpga-rts-4c FPGA_ILA=1 FPGA_ILA_DEPTH=4096
make impl-fpga FPGA_ILA=1
```

`FPGA_ILA` 本地默认是 `0`，CI 的 `syn-fpga-rts-4c` 和 `impl-fpga-rts-4c` 默认设为 `1`。单核可使用 `syn-fpga-rts`。综合和实现必须使用相同的 `FPGA_ILA` 值；修改采样深度后需要重新生成工程并综合。

| 内容 | `FPGA_ILA=0` | `FPGA_ILA=1` |
| --- | --- | --- |
| 工程 | `npu-axvu13p/` | `npu-axvu13p-ila/` |
| 综合输出 | `out/syn/` | `out/ila/syn/` |
| 实现输出 | `out/impl/` | `out/ila/impl/` |
| 报告 | `rpt/` | `rpt/ila/` |

调试脚本独立放在 `debug/`。System ILA 的 IP 和自带时序约束只在带 ILA 的工程中生成，普通 `src/xdc/` 不包含调试约束，也不添加额外跨时钟例外。关闭 ILA 时，Block Design 不连接观察输出，由综合裁剪这些无负载路径。

一个混合模式 System ILA 同时采集以下内容，使用 `ClusterWrapper.clock`，与四个 RTS 核及 uncore 同频同相：

| 观察对象 | 信号与含义 |
| --- | --- |
| `SLOT_0_AXI` | 直接连接 DUT 的 `s_axi`，即 frontxbar 外部入口。使用 AXI4 interface monitor，包含 AW/AR 地址、ID、len、burst 等属性，以及 W/R 数据和全部五通道握手，可在 Hardware Manager 中按 AXI 总线查看。 |
| `ila_coreN_retire_S` | `valid && iretire`，N 为核心编号，S 为 0/1 退休槽。 |
| `ila_coreN_valid_S`、`ila_coreN_iretire_S` | RTS trace 的原始 valid、iretire。 |
| `ila_coreN_retire_pc_S`、`ila_coreN_instr_S` | 原始 39 位 `iaddr` 和 48 位 `instr`。仅在对应 retire 有效时解释为退休指令。 |
| `ila_memoryN_*` | 每个对外内存 AXI 口的 AW/AR 全部非零宽度属性；R/W/B 握手、R/B ID、last 和 response。不采 WDATA、RDATA、WSTRB。AXI4 的 W 通道没有独立 ID，通过 AW/B 的 ID 及突发顺序关联。 |
| `ila_memoryN_*_fire` | 对应通道的 `valid && ready`。 |
| `ila_global_cycles` | 64 位全局周期计数器，wrapper 复位时清零，其后每个时钟周期加一，空闲周期也计数。与所有观察信号在同一个 ILA 中采样，可用于计算时间差和吞吐率。 |
| `ila_global_reset` | wrapper 复位状态。 |

Chisel 从实际接口生成 `generated/<配置>/debug/ila_probes.tcl`，维护原生 probe 顺序、名称和位宽。`debug/add_ila.tcl` 按清单连接同名 RTL 输出，System ILA 自动推导位宽；BD 验证后还会检查连接和位宽，避免带着缺失信号进入综合。实现阶段显式导出 `soc_wrapper.ltx`，与 `soc_wrapper.bit` 一起交给 Hardware Manager。

快速检查不运行综合或实现。在 npu-cluster 根目录执行：

```bash
source /eda-tools/env/vivado-2024-2
vivado -mode batch -source fpga/axvu13p/debug/quick_check.tcl -tclargs \
  generated/ClusterWrapper-FpgaQualRtsClusterConfig/debug/ila_probes.tcl \
  build/fpga-ila-quick-check
```

该检查使用生成的 probe 清单创建一个小型 DUT 接口模型，调用正式接线脚本，并在 Vivado 中验证混合模式、AXI 接口和全部命名 probe。通过时输出 `ILA_QUICK_CHECK_PASS`。它不替代完整工程的时序、资源和上板验证。

## 输出目录

- `rpt/`：`impl.tcl` 生成的时序报告 `timing_summary.rpt` 与资源报告 `utilization.rpt`
- `out/syn`、`out/impl`：`make syn` / `make impl` 同步出来的运行结果（runs 目录）
- `npu-axvu13p/`：Vivado 工程目录（已加入 `.gitignore`）
