# virtme-ng (vng) Detailed Usage Reference

Comprehensive reference for virtme-ng CLI commands and MCP server integration.

## CLI Commands

### Build Commands

#### Build Kernel and Modules

```bash
vng -v --build
```

Builds the kernel in the current source tree. Uses `.config` from the source tree.

Options:
- `-v` — Verbose output, show build progress
- `-S` — Skip module installation (faster, but modules unavailable at runtime)
- `-j N` — Override number of parallel build jobs
- `--arch ARCH` — Cross-compile for a different architecture (e.g., `arm64`)

#### Generate Kernel Config

```bash
vng --kconfig
```

Generates a minimal bootable kernel config. Useful as a starting point for fast iteration.

To customize further:

```bash
vng --kconfig
./scripts/config --enable CONFIG_MY_FEATURE
make olddefconfig
```

### Run Commands

#### Run Command and Exit

```bash
vng -e "command"
```

Spawns a new QEMU VM with the compiled kernel, runs the command, captures output, and exits.

**Critical**: Each `vng -e` invocation is an independent VM. No state carries over between calls.

#### Run Interactive Session

```bash
vng
```

Drops into an interactive shell in the QEMU VM. Useful for manual exploration.

#### Run with Specific Kernel

```bash
vng -r /path/to/vmlinuz -e "command"
```

Use a specific kernel image instead of the one in the current build tree.

### Test Commands

#### Run Kselftest

```bash
vng --kselftest TEST_NAME
```

Or run kselftest manually:

```bash
vng -e "cd /home/virtme/kselftest && ./TEST_NAME"
```

#### Run Custom Test Script

```bash
vng -e "cd /path && ./test.sh && echo PASS || echo FAIL"
```

### Architecture Options

```bash
vng --arch arm64 --build
vng --arch arm64 -e "uname -m"
```

Supported architectures depend on QEMU availability. Common: `x86_64` (default), `arm64`, `riscv64`.

## MCP Server

### Configuration

Add to Claude Code MCP config (`~/.config/claude/config.json`):

```json
{
  "mcpServers": {
    "virtme-ng": {
      "command": "vng",
      "args": ["--mcp"]
    }
  }
}
```

### MCP Tools

#### `build_kernel`

Build the kernel in the source tree.

Parameters:
- `source_dir` (optional) — Path to kernel source tree
- `arch` (optional) — Target architecture
- `jobs` (optional) — Number of parallel jobs
- `cross_compile` (optional) — Cross-compiler prefix

**Warning**: Build may take 10-60+ minutes. Use appropriate timeouts.

**Do NOT use `run_kernel_cmd` for builds.**

#### `configure_kernel`

Generate or update kernel configuration.

Parameters:
- `source_dir` (optional) — Path to kernel source tree
- `config_target` (optional) — Make config target (default: `defconfig`)

#### `run_kernel_cmd`

Run a command in a QEMU VM with the compiled kernel.

Parameters:
- `command` (string, required) — Command to execute
- `arch` (optional) — Architecture
- `timeout` (optional) — Timeout in seconds
- `kernel` (optional) — Path to specific kernel image

**Critical notes**:
- Each invocation spawns a **fresh VM** — no state persists between calls
- Do NOT use for builds — use `build_kernel` instead
- Combine dependent commands with `&&` or `;` in a single call

#### `run_kselftest_cmd`

Run kernel self-tests.

Parameters:
- `test_name` (string, required) — Name of kselftest to run
- `arch` (optional) — Architecture
- `timeout` (optional) — Timeout in seconds

#### `get_kernel_info`

Get information about the current kernel build.

Returns kernel version, build path, and other metadata.

#### `apply_patch`

Apply a patch to the kernel source tree.

Parameters:
- `patch` (string, required) — Patch content (unified diff format)
- `source_dir` (optional) — Path to kernel source tree

## Common Workflows

### Fast Iteration Loop

For quick testing of core kernel changes (no modules needed):

```bash
# 1. Generate minimal config
vng --kconfig

# 2. Build (skip modules for speed)
vng -v -S --build

# 3. Test
vng -e "dmesg | grep my_feature"

# 4. Edit source, goto step 2
```

### Module Development

For testing loadable modules:

```bash
# 1. Enable module-related configs
./scripts/config --enable CONFIG_MY_MODULE
./scripts/config --module CONFIG_MY_MODULE
make olddefconfig

# 2. Build with modules (no -S flag)
vng -v --build

# 3. Load and test module
vng -e "modprobe my_module && dmesg | tail -30"
```

### Regression Testing

```bash
# Build
vng -v --build

# Run a battery of tests in a single VM invocation
vng -e "
  echo '=== Test 1: Boot ===' &&
  uname -r &&
  echo '=== Test 2: Module load ===' &&
  modprobe my_module &&
  echo '=== Test 3: Functionality ===' &&
  cat /proc/my_feature &&
  echo '=== All tests passed ==='
"
```

## Tips

1. **Minimize config for faster builds**: `vng --kconfig` generates the smallest bootable config. Only enable options needed for testing.

2. **Use `-S` when testing core kernel**: Skipping module installation significantly reduces build time when only kernel core changes are being tested.

3. **Combine commands**: Since each VM is fresh, use `&&` to chain dependent operations in a single `vng -e` call.

4. **Check build before testing**: Always verify build success before running tests. A failed build produces stale kernel images.

5. **Timeout awareness**: Build operations can take 10-60+ minutes. Test commands typically complete in seconds to minutes.

6. **Debug with dmesg**: After running commands, check `dmesg` output for kernel-level errors or debug information.

7. **Arch-specific testing**: Use `--arch` to test cross-compiled kernels on different architectures.
