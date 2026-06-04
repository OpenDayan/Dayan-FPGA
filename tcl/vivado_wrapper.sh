#!/bin/bash
# 这个wrapper可以处理传给脚本的参数
SCRIPT="$1"
shift  # 移除脚本名，剩下的都是要传递给Tcl脚本的参数

# 将参数传递给vivado，同时保留给Tcl脚本使用
exec vivado -mode batch -script "$SCRIPT" -tclargs "$@"
