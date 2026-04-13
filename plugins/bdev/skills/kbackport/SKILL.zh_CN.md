---
name: kbackport
description: |
  当用户要求 "backport commit"、"backport到release分支"、"移植内核补丁"、"cherry-pick依赖分析"、"backport kernel patches"，或讨论在 Linux 内核分支之间 backport 更改时，应使用此 skill。

  提供全面的指导，用于分析 commit 依赖、解决冲突，以及创建正确的 backport commit。
version: 0.2.0
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "../scripts/block-git-remote.sh"
---

# Linux 内核 Backport 指南

在 Linux 内核分支之间 backport commit 的指南，包含仔细的依赖分析、冲突解决和正确的 commit message 格式化。

## 工作流程

### 阶段 1：规划（必需）

**在任何执行之前**，使用以下流程生成 backport 计划：

#### 步骤 1.1：识别 commit

从用户处收集源分支、目标分支和 commit 列表。用户可以提供 commit 范围（例如 `A..B`）。在这种情况下，将 `git log <range>` 的输出视为目标 commit 的确定列表 — 完全按照返回的顺序处理，不添加或删除任何 commit。

在参考 worktree 中，按顺序获取 commit：
```bash
cd <reference_worktree>
git log --reverse --oneline <commit_range>
```

#### 步骤 1.2：分析依赖

- 对于目标 `<commit_range>`，调用 `commit-symbol-analyzer`，获取所有目标 commit 使用的外部符号列表。
- 对返回的符号列表，调用 `symbol-availability-checker` 检查符号在目标分支中的可用性，获得在目标分支不可用或签名发生变化的符号列表。
- 对于每个不可用或签名发生变化的符号，调用 `dependency-analyzer`，通过对比参考分支和目标分支的代码，分析这些变动对于 `<commit_range>` 是否是必须的依赖。获得一个依赖符号列表。

#### 步骤 1.3：查找依赖引入点

在等待 1.2 完成时，并行地，确定参考分支和目标分支的分叉点，以缩小后续分析依赖时 `git log -S` 的搜索范围。这可以显著提高 Linux 内核等大型仓库的性能。
你可以使用 `git merge-base` 或其他合理手段（例如版本号）来确定这个分叉点。

对于 1.2 中得出的依赖符号列表，调用 `symbol-origin-finder`，获取这些符号的变动历史。

#### 步骤 1.4：生成依赖列表

合并目标 commit 和前置 commit，然后按拓扑顺序排序：

```bash
cd <reference_worktree>

# 将所有 commit 放入文件
echo -e "abc123\ndef456\nxyz789\nuvw456" > /tmp/commits.txt

# 找到合并基准并按拓扑排序
BASE=$(git merge-base --octopus $(cat /tmp/commits.txt))
git rev-list --topo-order --reverse "$BASE"..HEAD | grep -F -f /tmp/commits.txt
```

#### 步骤 1.5：呈现依赖分析报告

向用户呈现完整的依赖分析报告以供审查，确认依赖关系正确，没有遗漏或误报。遵循 **`references/dependency-report-template.md`** 中的模板。

#### 步骤 1.6：获取用户批准

**只有在用户明确确认后才继续**。

---

### 阶段 2：环境准备（计划批准后）

**在审查要 backport 的 commit 后**，配置并验证两个 worktree 都能成功编译：

> **注意**：用户应提供两个独立的 worktree — 一个用于目标分支，一个用于参考分支。不需要 `git checkout` 操作。

1. **配置并验证目标 worktree**：
   ```bash
   # 在目标 worktree 目录中
   make olddefconfig  # 或其他适当的配置方法
   make -j$(nproc)
   ```

2. **配置并验证参考 worktree**：
   ```bash
   # 在参考 worktree 目录中
   make olddefconfig  # 或其他适当的配置方法
   make -j$(nproc)
   ```

3. **确保相关配置已启用**：在编译之前，验证与 backport 内容相关的 Kconfig 选项已启用。

   ```bash
   grep CONFIG_FOO .config
   ./scripts/config --enable CONFIG_FOO
   ```

---

### 阶段 3：执行（环境就绪后）

按计划顺序**逐个**执行 commit。

对于**每个** commit，调用 `backport-executor`：

```
Task(
  subagent_type="backport-executor",
  prompt="Backport commit <commit_hash> to worktree <target_worktree_path>. The original commit is available in reference worktree <reference_worktree_path>."
)
```

**如果 agent 因缺少基础设施而报告失败**，按以下方式处理：

阶段 1 中基于符号的初始依赖分析可能无法捕获所有前置 commit。当 `backport-executor` 遇到因目标分支中缺少所需代码基础设施（函数、结构体、宏等）而无法解决的冲突时，它将报告**缺失符号**列表。

当发生这种情况时，创建一个 `backup-*` 分支保存当前目标工作区状态。返回到步骤 1.2，分析新发现的依赖对应的 commits，完成后从阶段 3 开头重新执行。

---

### 阶段 4：最终验证

所有 commit backport 完成后：
- 完整内核构建
- 运行相关测试
- 验证原始功能是否保留

---

## 质量检查清单

完成之前：
- [ ] 计划已由用户审查和批准（阶段 1）
- [ ] 已识别并启用与 backport 内容相关的 Kconfig 选项（阶段 2）
- [ ] 目标和参考 worktree 均已配置并成功编译（阶段 2）
- [ ] 所有 commit 已逐一处理
- [ ] 如果 backport-executor 报告了缺失符号，已创建备份分支并从步骤 1.2 重新执行依赖分析
- [ ] 每个 commit：提交前完整内核构建通过
- [ ] Commit message 遵循规范
- [ ] 最终内核构建成功
- [ ] 相关测试通过

---

## 其他资源

### 参考文件

详细的模板和格式，请参阅：

- **`references/dependency-report-template.md`** - 阶段 1.5 的依赖分析报告格式

### 示例文件

`examples/` 中的工作示例：

- **`examples/backport-plan-template.md`** - 包含执行步骤、冲突说明和验证检查清单的完整 backport 计划模板
