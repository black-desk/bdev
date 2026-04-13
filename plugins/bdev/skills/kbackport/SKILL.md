---
name: kbackport
description: |
  This skill should be used when the user asks to "backport commit", "backport到release分支", "移植内核补丁", "cherry-pick依赖分析", "backport kernel patches", or discusses backporting changes between Linux kernel branches.

  Provides comprehensive guidance for analyzing commit dependencies, resolving conflicts, and creating proper backport commits.
version: 0.2.0
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "../scripts/block-git-remote.sh"
---

# Linux Kernel Backport Guide

Guide for backporting commits between Linux kernel branches with careful dependency analysis, conflict resolution, and proper commit message formatting.

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

#### Step 1.2: Analyze Dependencies

- For the target `<commit_range>`, invoke `commit-symbol-analyzer` to get the list of external symbols used by all target commits.
- Pass the returned symbol list to `symbol-availability-checker` to check symbol availability in the target branch, obtaining a list of symbols that are unavailable or have signature changes in the target branch.
- For each unavailable or signature-changed symbol, invoke `dependency-analyzer` to analyze, by comparing code between the reference and target branches, whether these changes are required dependencies for `<commit_range>`. Obtain a dependency symbol list.

#### Step 1.3: Find Dependency Origins

While waiting for 1.2 to complete, in parallel, determine the fork point between the reference branch and the target branch to narrow down the `git log -S` search scope for subsequent dependency analysis. This significantly improves performance for large repositories like the Linux kernel.
You can use `git merge-base` or other reasonable means (e.g., version numbers) to determine this fork point.

For the dependency symbol list from 1.2, invoke `symbol-origin-finder` to get the change history of these symbols.

#### Step 1.4: Generate Dependency List

Combine target commits and prerequisite commits, then sort by topological order:

```bash
cd <reference_worktree>

# Put all commits into a file
echo -e "abc123\ndef456\nxyz789\nuvw456" > /tmp/commits.txt

# Find merge base and sort topologically
BASE=$(git merge-base --octopus $(cat /tmp/commits.txt))
git rev-list --topo-order --reverse "$BASE"..HEAD | grep -F -f /tmp/commits.txt
```

#### Step 1.5: Present Dependency Analysis Report

Present the full dependency analysis report to the user for review, confirming that dependencies are correct with no omissions or false positives. Follow the template in **`references/dependency-report-template.md`**.

#### Step 1.6: Get User Approval

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

**If the agent reports failure due to missing infrastructure**, handle as follows:

The initial symbol-based dependency analysis in Phase 1 may not catch all prerequisite commits. When `backport-executor` encounters a conflict it cannot resolve because required code infrastructure (functions, structs, macros, etc.) is absent in the target branch, it will report back with a list of **missing symbols**.

When this happens, create a `backup-*` branch to preserve the current target worktree state. Return to Step 1.2, analyze the newly discovered dependency commits, and resume execution from the beginning of Phase 3 once complete.

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
- [ ] If backport-executor reported missing symbols, a backup branch was created and dependency re-analysis was performed from Step 1.2
- [ ] Each commit: full kernel build passed before committing
- [ ] Commit messages follow conventions
- [ ] Final kernel builds successfully
- [ ] Relevant tests pass

---

## Additional Resources

### Reference Files

For detailed templates and formats, consult:

- **`references/dependency-report-template.md`** - Dependency analysis report format for Phase 1.5

### Example Files

Working examples in `examples/`:

- **`examples/backport-plan-template.md`** - Complete backport plan template with execution steps, conflict notes, and verification checklist
