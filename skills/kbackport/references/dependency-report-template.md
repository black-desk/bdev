# Backport Dependency Analysis Report Template

Present this report to the user for review before proceeding with execution.

```markdown
## Backport Dependency Analysis Report

### Worktree Information
- **Reference Worktree**: `<path>`
- **Target Worktree**: `<path>`

### Fork Point (Search Optimization)
- **Target Branch Base**: v6.6 (or custom version)
- **Fork Point on Reference**: `<commit_hash>` - `<commit_title>`
- **Note**: Symbol origin search will use range `<fork_point>..HEAD` for performance

### Target Commits (User Requested)
| Commit | Title |
|--------|-------|
| `abc123` | Brief description |
| `def456` | Brief description |

### Symbol Usage Analysis

#### All Symbols Found (Deduplicated)
| Symbol | Type | Used By Commits | In Target Branch |
|--------|------|-----------------|------------------|
| `function_a()` | Function | abc123, def456 | Yes |
| `struct_b` | Struct | abc123, def456 | Yes |
| `MACRO_C` | Macro | abc123 | No |
| `struct_b.field_d` | Struct Member | abc123 | No |

### Missing Symbols and Their Origins
| Symbol | Type | Introduced By |
|--------|------|---------------|
| `MACRO_C` | Macro | `xyz789` |
| `struct_b.field_d` | Struct Member | `uvw456` |

### Prerequisite Commits (Must Backport First)
| Commit | Title | Introduces |
|--------|-------|------------|
| `xyz789` | Define MACRO_C | MACRO_C |
| `uvw456` | Add field_d to struct_b | struct_b.field_d |

### Final Backport Order
1. `xyz789` - Define MACRO_C [PREREQUISITE]
2. `uvw456` - Add field_d to struct_b [PREREQUISITE]
3. `abc123` - Brief description [TARGET]
4. `def456` - Brief description [TARGET]

### Summary
- Target commits: 2
- Prerequisite commits: 2
- Total to backport: 4
```
