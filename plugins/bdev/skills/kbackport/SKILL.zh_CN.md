---
name: kbackport
description: |
  当用户要求 "backport commit"、"backport到release分支"、"移植内核补丁"、"cherry-pick依赖分析"、"backport kernel patches"，或讨论在 Linux 内核分支之间 backport 更改时，应使用此 skill。

  提供全面的指导，用于分析 commit 依赖、解决冲突，以及创建正确的 backport commit。
version: 0.2.0
---

# Linux 内核 Backport 指南

在 Linux 内核分支之间 backport commit 的指南，包含仔细的依赖分析、冲突解决和正确的 commit message 格式化。

**架构说明**：此 skill 直接协调所有子 agent。主会话调用专门的 agent（commit-symbol-analyzer、symbol-availability-checker、symbol-origin-finder、backport-executor）。在可能的情况下，独立的 agent 会并行启动。子 agent 不会调用其他子 agent。

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

#### 步骤 1.2：分析每个 commit 的符号（并行）

对于**每个**目标 commit，并行调用 `commit-symbol-analyzer`：

```
# 在一条消息中通过多个 Task 调用启动所有 agent
Task(
  subagent_type="commit-symbol-analyzer",
  prompt="Analyze commit <commit_hash_1> in worktree <reference_worktree_path>. List all symbols used in the code changes."
)
Task(
  subagent_type="commit-symbol-analyzer",
  prompt="Analyze commit <commit_hash_2> in worktree <reference_worktree_path>. List all symbols used in the code changes."
)
# ... 每个 commit 一个
```

**注意**：每个 agent 分析一个独立的 commit，因此可以同时启动所有 agent。从结果中收集所有符号。

#### 步骤 1.3：识别分支点以优化搜索

**目的**：确定一个参考分支点，以缩小 `git log -S` 搜索范围来查找符号引入位置。这可以显著提高 Linux 内核等大型仓库的性能。

**流程**：

1. **识别目标分支的内核版本基础**：
   ```bash
   cd <target_worktree>
   # 检查 Makefile 获取内核版本
   head -5 Makefile
   # 或检查内核发布标签
   git describe --tags --abbrev=0 2>/dev/null || git log --oneline -1
   ```

2. **在参考分支上找到分支点**：
   ```bash
   cd <reference_worktree>

   # 方法 1：如果目标基于已知的上游版本（例如 v6.6）
   # 找到参考分支和该上游标签之间的合并基准
   git merge-base HEAD v6.6

   # 方法 2：如果目标分支有特定的基础 commit/标签
   git merge-base HEAD <target_base_tag_or_commit>
   ```

3. **记录分支点供后续使用**：
   - 分支点 commit hash
   - 对应的上游版本（如适用）

**示例输出**：
```
Target branch kernel version: 6.6.x (based on v6.6)
Fork point on reference branch: a1b2c3d4e5f6...
```

**注意**：如果目标分支是自定义的下游内核，尽量识别其最接近的上游祖先。此分支点将传递给 `symbol-origin-finder`，以将 `git log -S` 搜索范围限制在 `<fork_point>..HEAD`，避免全历史搜索。

#### 步骤 1.4：符号去重

分析所有 commit 后，创建唯一的符号列表：

```
Unique Symbols:
  - function_a (function)      # Used by: abc123, def456
  - struct_b (struct)          # Used by: abc123, def456
  - MACRO_C (macro)            # Used by: abc123
  - struct_b.field_d (struct_member)  # Used by: abc123
```

#### 步骤 1.5：检查符号可用性

将完整的去重符号列表在一次调用中传递给 `symbol-availability-checker`：

```
Task(
  subagent_type="symbol-availability-checker",
  prompt="Check the following symbols in worktree <target_worktree_path>. For each symbol, report AVAILABLE or MISSING.

  Symbols:
  - symbol_a (function)
  - struct_b (struct)
  - MACRO_C (macro)
  - struct_b.field_d (struct_member)"
)
```

**注意**：检查器接受符号列表并在一次操作中检查所有符号。

#### 步骤 1.6：查找缺失符号的引入 commit（并行）

对于**每个**缺失符号（仅缺失的），并行调用 `symbol-origin-finder`：

```
# 在一条消息中通过多个 Task 调用启动所有 agent
Task(
  subagent_type="symbol-origin-finder",
  prompt="Find the commit that introduced symbol '<symbol_name_1>' (type: <symbol_type>) in worktree <reference_worktree_path>.

  IMPORTANT: Use fork point <fork_point_commit> as the search starting point. Run git log -S with range <fork_point_commit>..HEAD to avoid full history search. If not found in this range, then try broader search.

  Return the commit hashes that introduced or modified this symbol."
)
Task(
  subagent_type="symbol-origin-finder",
  prompt="Find the commit that introduced symbol '<symbol_name_2>' (type: <symbol_type>) in worktree <reference_worktree_path>.
  ..."
)
# ... 每个缺失符号一个
```

**注意**：每个 agent 搜索一个独立的符号，因此可以同时启动所有 agent。收集所有引入 commit。**将步骤 1.3 中的分支点**传递给每个 agent 以优化搜索性能。

#### 步骤 1.7：生成最终 backport 顺序

合并目标 commit 和前置 commit，然后按拓扑顺序排序：

```bash
cd <reference_worktree>

# 将所有 commit 放入文件
echo -e "abc123\ndef456\nxyz789\nuvw456" > /tmp/commits.txt

# 找到合并基准并按拓扑排序
BASE=$(git merge-base --octopus $(cat /tmp/commits.txt))
git rev-list --topo-order --reverse "$BASE"..HEAD | grep -F -f /tmp/commits.txt
```

#### 步骤 1.8：呈现依赖分析报告

向用户呈现完整的依赖分析报告以供审查，确认依赖关系正确，没有遗漏或误报。遵循 **`references/dependency-report-template.md`** 中的模板。

#### 步骤 1.9：获取用户批准

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

该 agent 将：
1. 执行 `git cherry-pick -x`
2. 解决冲突（如有）
3. 验证构建通过
4. 更新 commit message
5. 完成 cherry-pick

**如果 agent 因缺少基础设施而报告失败**，按以下方式处理：

阶段 1 中基于符号的初始依赖分析可能无法捕获所有前置 commit。当 `backport-executor` 遇到因目标分支中缺少所需代码基础设施（函数、结构体、宏等）而无法解决的冲突时，它将报告**缺失符号**列表。

当发生这种情况时，执行**依赖重新分析循环**：

1. 从 agent 的失败报告中**收集缺失符号**
2. **重新运行步骤 1.5** — 检查报告的符号中哪些在目标 worktree 中实际缺失
3. **重新运行步骤 1.6** — 使用相同的分支点优化搜索来查找新发现缺失符号的引入 commit
4. **重新运行步骤 1.7** — 将新发现的前置 commit 添加到现有集合中，并按拓扑顺序重新排序完整的 commit 列表
5. **向用户呈现更新后的 backport 顺序**以供批准，突出显示新增的 commit
6. **从更新后顺序中第一个未处理的 commit 恢复执行** — 不要重新处理已经成功的 commit

在当前失败解决之前，不要继续处理队列中的下一个 commit。

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
- [ ] 如果 backport-executor 报告了缺失符号，已执行依赖重新分析，并添加和重新排序了新的前置 commit
- [ ] 每个 commit：提交前完整内核构建通过
- [ ] Commit message 遵循规范
- [ ] 最终内核构建成功
- [ ] 相关测试通过

---

## 其他资源

### 参考文件

详细的模板和格式，请参阅：

- **`references/dependency-report-template.md`** - 阶段 1.8 的依赖分析报告格式

### 示例文件

`examples/` 中的工作示例：

- **`examples/backport-plan-template.md`** - 包含执行步骤、冲突说明和验证检查清单的完整 backport 计划模板
