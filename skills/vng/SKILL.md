name: vng
description: |
  This skill should be used when the user asks to "build kernel", "compile kernel", "test kernel change", "verify kernel functionality", "run kselftest", "boot kernel in QEMU", "vng build", "vng test", "test kernel module", "run kernel in VM", "verify kernel patch", or discusses building, testing, or verifying Linux kernel changes using virtme-ng (vng). Covers both CLI and MCP server integration for AI-agent-driven kernel build-test cycles.
version: 0.1.0
---

# Kernel Build and Test with virtme-ng (vng)

Guide for building Linux kernels and running tests in QEMU using virtme-ng (`vng`). This enables self-contained kernel build-test cycles without separate VM setup.

## Overview

virtme-ng (`vng`) builds and runs kernels inside a virtualized snapshot of the live system. It provides both a CLI and an MCP server interface for AI agent integration.

**Critical behavior**: Each `vng -e` / `run_kernel_cmd` invocation spawns a **new independent VM**. State does NOT persist between invocations. Commands requiring shared state must be combined with `&&` or `;` in a single invocation.

## Prerequisites

- `vng` installed and available in `$PATH` (check with `which vng`)
- Working kernel source tree with `.config`
- Sufficient disk space for build artifacts

## Workflow

### Phase 1: Kernel Configuration

Ensure the kernel source tree has a valid `.config` with relevant options enabled.

Generate a minimal bootable config (fastest):

```bash
vng --kconfig
```

Or use an existing config as base and enable specific options:

```bash
cp /boot/config-$(uname -r) .config
make olddefconfig
# Enable specific options
./scripts/config --enable CONFIG_FOO
make olddefconfig
```

For details on config management, consult **`references/vng-usage.md`**.

### Phase 2: Build Kernel

Build the kernel in the current source tree:

```bash
vng -v --build
```

Key build options:
- `--build` — build kernel and modules
- `-S` — skip module installation for faster builds (suitable when only testing core kernel changes)
- `-v` — verbose output
- `-j N` — override number of build jobs (defaults to nproc)

Typical build times: 10-60+ minutes depending on config and hardware.

**Important**: Do not use MCP `run_kernel_cmd` for builds. Use the CLI directly or the `build_kernel` MCP tool.

### Phase 3: Run Tests

After a successful build, run test commands in a QEMU VM using the just-compiled kernel.

#### Run a Single Command

```bash
vng -e "uname -r"
```

#### Run Multiple Dependent Commands (State in Single VM)

Since each `vng -e` invocation is a fresh VM, combine dependent commands:

```bash
vng -e "modprobe mymodule && dmesg | tail -20"
```

#### Run Kselftest

```bash
vng -e "cd /path/to/kselftest && ./test_suite"
```

Or use the dedicated kselftest flag:

```bash
vng --kselftest TEST_NAME
```

#### Run with a Specific Kernel

If testing a previously built kernel:

```bash
vng -r /path/to/vmlinuz -e "command"
```

### Phase 4: Iterative Development

After modifying source code:

1. Rebuild: `vng -v --build`
2. Re-test: `vng -e "test command"`
3. Repeat until tests pass

For common patterns (verifying module loads, checking kernel features at runtime, running multi-step scripts), consult **`references/vng-usage.md`**.

## MCP Server Integration

When the virtme-ng MCP server is configured, tools such as `build_kernel`, `run_kernel_cmd`, `run_kselftest_cmd`, and `get_kernel_info` are available. For detailed MCP tool parameters and configuration, consult **`references/vng-usage.md`**.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Build fails with missing config | Run `vng --kconfig` or `make olddefconfig` |
| Module not found at runtime | Do not use `-S` flag; rebuild with full modules |
| Command fails in VM | Ensure all dependencies are combined in single `vng -e` call |
| Timeout during build | Build times of 10-60 min are normal; increase timeout |

## Additional Resources

### Reference Files

For detailed usage patterns and advanced configuration, consult:

- **`references/vng-usage.md`** — Complete vng CLI and MCP server usage reference
