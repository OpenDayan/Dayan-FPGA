# NPU AXVU13P Vivado 工程

基于 AXVU13P 板卡的 SoC 原型验证工程，以 Block Design（`soc`）为核心，将大衍等 chisel 生成的 NPU SoC（DUT）通过 AXI 接入 PCIe 与 DDR4，用于上板验证。

## 环境与器件

- 器件：`xcvu13p-fhgb2104-2-i`
- Vivado 版本：2024.2

## Block Design 结构

工程顶层为 `soc_wrapper`，内部 Block Design（`soc`）由以下模块构成：

| 模块 | 说明 |
| --- | --- |
| `qdma` | Xilinx QDMA IP，PCIe Gen3 x16 主机接口，作为上位机访问 SoC 寄存器和 DDR 的入口 |
| `ddr4` | DDR4 存储控制器（16G，偏移 `0x0000000000`），存放数据 |
| `smartconnect_0` | 面向 DDR4 的 AXI 互连，汇聚 DUT 主口（`S01_AXI`…）与 qdma 的访问 |
| `smartconnect_1` | 面向 DUT 寄存器接口的 AXI 互连，qdma 主口经其接入 DUT 的 `s_axi` |
| `clk_wiz_0` | 时钟模块，为 DUT 提供输入时钟（默认 50MHz，可脚本修改） |
| `proc_sys_reset` | 复位控制器，为 DUT 及互连提供复位 |

数据通路如下：

- 上位机经 PCIe（`qdma`）→ `smartconnect_1` → DUT 寄存器接口（`s_axi`），用于配置/控制 DUT。
- DUT 主口（`m_axi`）→ `smartconnect_0` → `ddr4`，用于读写数据。
- 上位机也可经 `qdma → smartconnect_1 → smartconnect_0 → ddr4` 直接访问 DDR。

### DUT slave 口地址映射

`add_dut.tcl` 会将 DUT 的寄存器 slave 口 `s_axi/reg0` 与 DDR4 空间映射到上位机（qdma PCIe）地址空间，主机侧偏移/范围由配置项 `dut_addr_*` 与 `ddr_addr_*` 决定：

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

## 输出目录

- `rpt/`：`impl.tcl` 生成的时序报告 `timing_summary.rpt` 与资源报告 `utilization.rpt`
- `out/syn`、`out/impl`：`make syn` / `make impl` 同步出来的运行结果（runs 目录）
- `npu-axvu13p/`：Vivado 工程目录（已加入 `.gitignore`）
