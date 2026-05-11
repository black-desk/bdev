---
name: vng
description: |
  当用户要求 "build kernel"、"编译内核"、"test kernel change"、"验证内核功能"、"run kselftest"、"boot kernel in QEMU"、"vng build"、"vng test"、"test kernel module"、"run kernel in VM"、"verify kernel patch"，或讨论使用 virtme-ng (vng) 构建、测试或验证 Linux 内核更改时，应使用此 skill。涵盖 CLI 和 MCP 服务器集成，支持 AI agent 驱动的内核构建-测试循环。
version: 0.1.0
---

# 使用 virtme-ng (vng) 构建和测试内核

使用 virtme-ng (`vng`) 在 QEMU 中构建 Linux 内核并运行测试的指南。可以在不需要单独配置虚拟机的情况下，实现自包含的内核构建-测试循环。

## 概述

virtme-ng (`vng`) 在当前系统的虚拟化快照中构建并运行内核。它同时提供 CLI 和 MCP 服务器接口，支持 AI agent 集成。

**关键行为**：每次 `vng -e` / `run_kernel_cmd` 调用都会启动一个**全新的独立虚拟机**。调用之间**不会**保留状态。需要共享状态的命令必须使用 `&&` 或 `;` 在单次调用中组合执行。

## 前提条件

- `vng` 已安装并可在 `$PATH` 中找到（使用 `which vng` 检查）
- 可工作的内核源码树，包含 `.config`
- 足够的磁盘空间用于构建产物

## 工作流程

### 阶段 1：内核配置

确保内核源码树包含有效的 `.config`，并启用了相关选项。

生成最小可启动配置（最快）：

```bash
vng --kconfig
```

或以现有配置为基础并启用特定选项：

```bash
cp /boot/config-$(uname -r) .config
make olddefconfig
# 启用特定选项
./scripts/config --enable CONFIG_FOO
make olddefconfig
```

有关配置管理的详细信息，请参阅 **`references/vng-usage.md`**。

### 阶段 2：构建内核

在当前源码树中构建内核：

```bash
vng -v --build
```

主要构建选项：
- `--build` — 构建内核和模块
- `-S` — 跳过模块安装以加速构建（适用于仅测试内核核心变更）
- `-v` — 详细输出
- `-j N` — 覆盖构建任务数（默认为 nproc）

典型构建时间：根据配置和硬件，需要 10-60+ 分钟。

**重要**：不要使用 MCP `run_kernel_cmd` 进行构建。请直接使用 CLI 或 `build_kernel` MCP 工具。

### 阶段 3：运行测试

构建成功后，使用刚编译的内核在 QEMU 虚拟机中运行测试命令。

#### 运行单个命令

```bash
vng -e "uname -r"
```

#### 运行多个依赖命令（单次虚拟机内共享状态）

由于每次 `vng -e` 调用都是全新的虚拟机，请组合依赖命令：

```bash
vng -e "modprobe mymodule && dmesg | tail -20"
```

#### 运行 Kselftest

```bash
vng -e "cd /path/to/kselftest && ./test_suite"
```

或使用专用的 kselftest 标志：

```bash
vng --kselftest TEST_NAME
```

#### 使用特定内核运行

如果测试之前构建的内核：

```bash
vng -r /path/to/vmlinuz -e "command"
```

### 阶段 4：迭代开发

修改源码后：

1. 重新构建：`vng -v --build`
2. 重新测试：`vng -e "test command"`
3. 重复直到测试通过

常见模式（验证模块加载、运行时检查内核特性、运行多步骤脚本），请参阅 **`references/vng-usage.md`**。

## MCP 服务器集成

当 virtme-ng MCP 服务器配置完成后，可以使用 `build_kernel`、`run_kernel_cmd`、`run_kselftest_cmd` 和 `get_kernel_info` 等工具。详细的 MCP 工具参数和配置，请参阅 **`references/vng-usage.md`**。

## 故障排除

| 问题 | 解决方案 |
|------|----------|
| 构建失败，提示缺少配置 | 运行 `vng --kconfig` 或 `make olddefconfig` |
| 运行时找不到模块 | 不要使用 `-S` 标志；使用完整模块重新构建 |
| 命令在虚拟机中失败 | 确保所有依赖项组合在单次 `vng -e` 调用中 |
| 构建超时 | 10-60 分钟的构建时间是正常的；增加超时时间 |

## 其他资源

### 参考文件

详细的使用模式和高级配置，请参阅：

- **`references/vng-usage.md`** — 完整的 vng CLI 和 MCP 服务器使用参考
