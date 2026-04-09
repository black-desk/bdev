---
name: kbackport
description: |
  This skill should be used when the user asks to "backport commit", "backport到release分支", "移植内核补丁", "cherry-pick依赖分析", "backport kernel patches", or discusses backporting changes between Linux kernel branches.

  Provides comprehensive guidance for analyzing commit dependencies, resolving conflicts, and creating proper backport commits.
version: 0.2.0
---

# Linux Kernel Backport Guide

Guide for backporting commits between Linux kernel branches with careful dependency analysis, conflict resolution, and proper commit message formatting.

**Architecture Note**: This skill coordinates all subagents directly. The main session invokes specialized agents (commit-symbol-analyzer, symbol-availability-checker, symbol-origin-finder, backport-executor). Where possible, independent agents are launched in parallel. Subagents do NOT invoke other subagents.

## Workflow

### Phase 1: Planning (Required)

**Before any execution**, generate a backport plan using the following process:

#### Step 1.1: Identify Commits

Gather source branch, target branch, and commit list from user. The user may provide a commit range (e.g., `A..B`). In this case, treat the output of `git log <range>` as the definitive list of target commits — process them exactly as returned, without adding or removing any.

In the reference worktree, get commits in order:
```bash
cd <reference_worktree>
git log --reverse --oneline <commit_range>
```

#### Step 1.2: Analyze Each Commit's Symbols (Parallel)

For **each** target commit, invoke `commit-symbol-analyzer` in parallel:

```
# Launch all agents in a single message with multiple Task calls
Task(
  subagent_type="commit-symbol-analyzer",
  prompt="Analyze commit <commit_hash_1> in worktree <reference_worktree_path>. List all symbols used in the code changes."
)
Task(
  subagent_type="commit-symbol-analyzer",
  prompt="Analyze commit <commit_hash_2> in worktree <reference_worktree_path>. List all symbols used in the code changes."
)
# ... one per commit
```

**Note**: Each agent analyzes an independent commit, so they can all be launched at once. Collect all symbols from the results.

#### Step 1.3: Identify Fork Point for Search Optimization

**Purpose**: Determine a reference fork point to narrow down `git log -S` search scope when finding symbol origins. This significantly improves performance for large repositories like the Linux kernel.

**Process**:

1. **Identify target branch's kernel version base**:
   ```bash
   cd <target_worktree>
   # Check Makefile for kernel version
   head -5 Makefile
   # Or check kernel release tag
   git describe --tags --abbrev=0 2>/dev/null || git log --oneline -1
   ```

2. **Find the fork point on reference branch**:
   ```bash
   cd <reference_worktree>

   # Method 1: If target is based on a known upstream version (e.g., v6.6)
   # Find the merge base between reference and that upstream tag
   git merge-base HEAD v6.6

   # Method 2: If target branch has a specific base commit/tag
   git merge-base HEAD <target_base_tag_or_commit>
   ```

3. **Record the fork point for later use**:
   - Fork point commit hash
   - Corresponding upstream version (if applicable)

**Example output**:
```
Target branch kernel version: 6.6.x (based on v6.6)
Fork point on reference branch: a1b2c3d4e5f6...
```

**Note**: If the target branch is a custom downstream kernel, try to identify its closest upstream ancestor. This fork point will be passed to `symbol-origin-finder` to limit `git log -S` search range to `<fork_point>..HEAD`, avoiding full history search.

#### Step 1.4: Deduplicate Symbols

After analyzing all commits, create a unique symbol list:

```
Unique Symbols:
  - function_a (function)      # Used by: abc123, def456
  - struct_b (struct)          # Used by: abc123, def456
  - MACRO_C (macro)            # Used by: abc123
  - struct_b.field_d (struct_member)  # Used by: abc123
```

#### Step 1.5: Check Symbol Availability

Pass the full deduplicated symbol list to `symbol-availability-checker` in a single invocation:

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

**Note**: The checker accepts a list of symbols and checks them all in one pass.

#### Step 1.6: Find Origin of Missing Symbols (Parallel)

For **each** missing symbol (ONLY missing ones), invoke `symbol-origin-finder` in parallel:

```
# Launch all agents in a single message with multiple Task calls
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
# ... one per missing symbol
```

**Note**: Each agent searches for an independent symbol, so they can all be launched at once. Collect all origin commits. **Pass the fork point from Step 1.3** to each agent to optimize search performance.

#### Step 1.7: Generate Final Backport Order

Combine target commits and prerequisite commits, then sort by topological order:

```bash
cd <reference_worktree>

# Put all commits into a file
echo -e "abc123\ndef456\nxyz789\nuvw456" > /tmp/commits.txt

# Find merge base and sort topologically
BASE=$(git merge-base --octopus $(cat /tmp/commits.txt))
git rev-list --topo-order --reverse "$BASE"..HEAD | grep -F -f /tmp/commits.txt
```

#### Step 1.8: Present Dependency Analysis Report

Present the full dependency analysis report to the user for review, confirming that dependencies are correct with no omissions or false positives. Follow the template in **`references/dependency-report-template.md`**.

#### Step 1.9: Get User Approval

**Only proceed after explicit user confirmation**.

---

### Phase 2: Environment Preparation (After Plan Approval)

**After reviewing the commits to be backported**, configure and verify both worktrees can compile successfully:

> **Note**: User should provide two separate worktrees - one for the target branch and one for the reference branch. No `git checkout` operations are needed.

1. **Configure and verify target worktree**:
   ```bash
   # In target worktree directory
   make olddefconfig  # or appropriate configuration method
   make -j$(nproc)
   ```

2. **Configure and verify reference worktree**:
   ```bash
   # In reference worktree directory
   make olddefconfig  # or appropriate configuration method
   make -j$(nproc)
   ```

3. **Ensure relevant configs are enabled**: Before compilation, verify that Kconfig options related to the backport content are enabled.

   ```bash
   grep CONFIG_FOO .config
   ./scripts/config --enable CONFIG_FOO
   ```

---

### Phase 3: Execution (After Environment Ready)

Execute commits **one at a time** in the planned order.

For **each commit**, invoke `backport-executor`:

```
Task(
  subagent_type="backport-executor",
  prompt="Backport commit <commit_hash> to worktree <target_worktree_path>. The original commit is available in reference worktree <reference_worktree_path>."
)
```

The agent will:
1. Execute `git cherry-pick -x`
2. Resolve conflicts (if any)
3. Verify build passes
4. Update commit message
5. Complete the cherry-pick

**If the agent reports failure due to missing infrastructure**, handle as follows:

The initial symbol-based dependency analysis in Phase 1 may not catch all prerequisite commits. When `backport-executor` encounters a conflict it cannot resolve because required code infrastructure (functions, structs, macros, etc.) is absent in the target branch, it will report back with a list of **missing symbols**.

When this happens, perform a **dependency re-analysis loop**:

1. **Collect missing symbols** from the agent's failure report
2. **Re-run Phase 1.5** — check which of the reported symbols are actually missing in the target worktree
3. **Re-run Phase 1.6** — find origin commits for the newly discovered missing symbols, using the same fork point for search optimization
4. **Re-run Phase 1.7** — add the newly found prerequisite commits to the existing set, and re-sort the full commit list in topological order
5. **Present the updated backport order** to the user for approval, highlighting the newly added commits
6. **Resume execution** from the first unprocessed commit in the updated order — do NOT re-process commits that already succeeded

Do NOT proceed to the next commit in the queue until the current failure is resolved.

---

### Phase 4: Final Verification

After all commits are backported:
- Full kernel build
- Run relevant tests
- Verify original functionality preserved

---

## Quality Checklist

Before finalizing:
- [ ] Plan was reviewed and approved by user (Phase 1)
- [ ] Kconfig options related to backport content identified and enabled (Phase 2)
- [ ] Both target and reference worktrees configured and compile successfully (Phase 2)
- [ ] All commits processed one-by-one
- [ ] If backport-executor reported missing symbols, dependency re-analysis was performed and new prerequisite commits were added and re-sorted
- [ ] Each commit: full kernel build passed before committing
- [ ] Commit messages follow conventions
- [ ] Final kernel builds successfully
- [ ] Relevant tests pass

---

## Additional Resources

### Reference Files

For detailed templates and formats, consult:

- **`references/dependency-report-template.md`** - Dependency analysis report format for Phase 1.8

### Example Files

Working examples in `examples/`:

- **`examples/backport-plan-template.md`** - Complete backport plan template with execution steps, conflict notes, and verification checklist
