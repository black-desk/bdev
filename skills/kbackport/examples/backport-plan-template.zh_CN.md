# Backport 计划：[功能/修复名称]

**生成时间**：[日期]
**源分支**：[source-branch-name]
**目标分支**：[target-branch-name]
**请求的 commit**：[commit-hash-1], [commit-hash-2], ...

---

## 摘要

[简要描述要 backport 的内容和原因]

- **要 backport 的 commit 总数**：X
- **依赖深度**：Y 层
- **估计复杂度**：[低/中/高]

---

## Commit 链

### 第 1 层：前置条件（必须先 backport）

| 顺序 | Commit | 标题 | 原因 |
|------|--------|------|------|
| 1 | `abc12345` | [commit title] | 引入后续 commit 使用的 `struct foo` |
| 2 | `def67890` | [commit title] | 添加辅助函数 `bar()` |

### 第 2 层：请求的 commit

| 顺序 | Commit | 标题 | 依赖 |
|------|--------|------|------|
| 3 | `target001` | [commit title] | `abc12345`, `def67890` |
| 4 | `target002` | [commit title] | `target001` |

---

## 详细 Commit 信息

### Commit `abc12345`（前置条件）

```
Author: [author name]
Date:   [date]

    [commit title]

    [此 commit 所做工作的简要描述]

    [为什么 backport 需要它]
```

**修改的文件**：
- `path/to/file1.c`
- `include/linux/header.h`

**预期冲突**：[是/否]
- [如有预期的冲突，描述冲突]

---

### Commit `target001`（请求的）

```
Author: [author name]
Date:   [date]

    [commit title]

    [commit message body]
```

**修改的文件**：
- `path/to/file.c`

**依赖**：
- 需要 `abc12345` 中的 `struct foo`
- 使用 `def67890` 中的 `bar()`

**预期冲突**：[是/否]
- [如适用，描述]

---

## 执行计划

### 阶段 2：环境准备（计划批准后，执行前）

> **注意**：用户提供两个独立的 worktree — 目标 worktree 和参考 worktree。不需要 `git checkout`。

```bash
# 1. 在目标 worktree 中：配置并验证编译
# 配置内核构建（选择适当的方法）：
#   - cp /boot/config-$(uname -r) .config  # 复制现有配置
#   - make defconfig                        # 默认配置
#   - make menuconfig                       # 交互式配置
make olddefconfig  # 更新/应用配置
make -j$(nproc)    # 必须编译成功

# 2. 在参考 worktree 中：配置并验证编译
# 配置内核构建（与上述选项相同）
make olddefconfig  # 更新/应用配置
make -j$(nproc)    # 必须编译成功
```

**重要**：在编译之前确保与 backport 内容相关的 Kconfig 选项已启用。这保证了 backport 的代码会被构建并可以正确验证。

```bash
# 检查特定配置选项是否启用
grep CONFIG_[RELATED_OPTION] .config

# 如需启用
./scripts/config --enable CONFIG_[RELATED_OPTION]
make olddefconfig  # 更改后重新生成
```

### 阶段 3：Cherry-pick 执行

```bash
# 在目标 worktree 中，按顺序 cherry-pick（使用 -x 记录来源）
git cherry-pick -x abc12345
git cherry-pick -x def67890
git cherry-pick -x target001
git cherry-pick -x target002

# 每次 cherry-pick 后，提交之前：
# 完整内核构建（必须 — 不允许部分编译）
make -j$(nproc)

# 运行相关测试
# [如适用，特定测试命令]
```

---

## 冲突解决说明

### Commit `abc12345`

**预期冲突文件**：`path/to/file.c`

**解决策略**：
- [如何解决冲突]
- [保留什么，适应什么]

---

## 验证检查清单

计划批准后，开始执行之前：
- [ ] 已识别与 backport 内容相关的 Kconfig 选项
- [ ] 目标 worktree：相关配置已启用
- [ ] 目标 worktree：内核构建已配置（例如 `make olddefconfig`）
- [ ] 目标 worktree：编译成功（`make -j$(nproc)`）
- [ ] 参考 worktree：相关配置已启用
- [ ] 参考 worktree：内核构建已配置（例如 `make olddefconfig`）
- [ ] 参考 worktree：编译成功（`make -j$(nproc)`）

完成 backport 后：

- [ ] 所有 commit 已成功应用
- [ ] 每个 commit：提交前完整内核构建通过（`make -j$(nproc)`）
- [ ] 未引入新的编译器警告
- [ ] 相关测试通过
- [ ] 原始功能保留
- [ ] Commit message 遵循规范
- [ ] 已添加 `Signed-off-by` 行

---

## 回滚计划

如果出现问题：

```bash
# 中止当前 cherry-pick
git cherry-pick --abort

# 重置到目标分支
git checkout [target-branch]
git branch -D backport/[feature-name]-[date]

# 使用调整后的计划重新开始
```

---

## 备注

[任何额外的说明、关注事项或特殊考虑]

---

*此计划由 bdev backport 工作流生成。执行前请仔细审查。*
