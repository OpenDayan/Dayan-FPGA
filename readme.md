# NPU AXVU13P Vivado 工程

## 版本需求

Vivado 版本：2024.2

## 同步 RTL 代码

```bash
./scripts/update_chiptop.sh $SRC_PATH $TOP_NAME
```

`SRC_PATH` 为 Chipyard 生成代码的路径，可为本地路径或远程路径，如

- 本地路径 `/home/test/npu-work/workspace/npu-cluster/generated/ClusterWrapper/`
- 远程路径 `vef:npu-work/workspace/npu-cluster/generated/ClusterWrapper/`

## 配置工程

```bash
make config CONFIG=cluster
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
