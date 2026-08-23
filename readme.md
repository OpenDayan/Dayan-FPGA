# NPU AXVU13P Vivado 工程

## 版本需求

Vivado 版本：2024.2

## 同步 RTL 代码

以大衍 SoC 为例，顶层为 `RvtsocWrapper`

```bash
./scripts/update_chiptop.sh $SRC_PATH RvtsocWrapper
```

`SRC_PATH` 为 chisel 生成代码的路径，可为本地路径或远程路径，如

- 本地路径 `/workspace/Dayan/generated/RvtsocWrapper/`
- 远程路径 `vef:/workspace/Dayan/generated/RvtsocWrapper/`

## 配置工程

```bash
make config
```

## 生成工程

```bash
make gen-prj
```

## 脚本修改 DUT 输入时钟频率

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
