# Backport 依赖分析报告模板

在继续执行之前，将此报告呈现给用户审查。

```markdown
## Backport 依赖分析报告

### Worktree 信息
- **参考 Worktree**：`<path>`
- **目标 Worktree**：`<path>`

### 分支点（搜索优化）
- **目标分支基础**：v6.6（或自定义版本）
- **参考分支上的分支点**：`<commit_hash>` - `<commit_title>`
- **注意**：符号引入搜索将使用范围 `<fork_point>..HEAD` 以提高性能

### 目标 Commit（用户请求）
| Commit | 标题 |
|--------|------|
| `abc123` | 简要描述 |
| `def456` | 简要描述 |

### 符号使用分析

#### 发现的所有符号（已去重）
| 符号 | 类型 | 使用该符号的 Commit | 在目标分支中 |
|------|------|---------------------|-------------|
| `function_a()` | Function | abc123, def456 | 是 |
| `struct_b` | Struct | abc123, def456 | 是 |
| `MACRO_C` | Macro | abc123 | 否 |
| `struct_b.field_d` | Struct Member | abc123 | 否 |

### 缺失符号及其引入 commit
| 符号 | 类型 | 引入 commit |
|------|------|------------|
| `MACRO_C` | Macro | `xyz789` |
| `struct_b.field_d` | Struct Member | `uvw456` |

### 前置 commit（必须先 backport）
| Commit | 标题 | 引入的符号 |
|--------|------|-----------|
| `xyz789` | 定义 MACRO_C | MACRO_C |
| `uvw456` | 向 struct_b 添加 field_d | struct_b.field_d |

### 最终 backport 顺序
1. `xyz789` - 定义 MACRO_C [前置条件]
2. `uvw456` - 向 struct_b 添加 field_d [前置条件]
3. `abc123` - 简要描述 [目标]
4. `def456` - 简要描述 [目标]

### 摘要
- 目标 commit：2
- 前置 commit：2
- backport 总数：4
```
