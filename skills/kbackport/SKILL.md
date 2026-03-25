---
name: kbackport
description: This skill should be used when the user asks to "backport commit", "backport到release分支", "移植内核补丁", "cherry-pick依赖分析", "backport kernel patches", or discusses backporting changes between Linux kernel branches. Provides comprehensive guidance for analyzing commit dependencies, resolving conflicts, and creating proper backport commits.
version: 0.1.0
---

# Linux Kernel Backport Guide

Guide for backporting commits between Linux kernel branches with careful dependency analysis, conflict resolution, and proper commit message formatting.

## Core Principles

1. **Plan First, Execute Later**: Always generate a backport plan for user review before executing any cherry-pick operations
2. **Commit-by-Commit Execution**: Process commits one at a time, ensuring each compiles before moving to the next
3. **Proper Commit Messages**: Follow kernel backport conventions for every commit

## Workflow

### Phase 1: Planning (Required)

**Before any execution**, generate a backport plan using the template in `examples/backport-plan-template.md`:

1. **Identify commits**: Gather source branch, target branch, and commit list
2. **Analyze dependencies**: Use the `backport-dependency-analyzer` agent to identify prerequisite commits
3. **Generate plan document** containing:
   - Complete commit chain (including dependencies)
   - Backport order
   - Potential conflicts
   - Execution commands
4. **Present plan to user for approval**
5. **Only proceed after explicit user confirmation**

### Phase 2: Execution (After Approval)

Execute commits **one at a time** in the planned order:

For **each commit**:
1. **Cherry-pick** the commit:
   ```bash
   git cherry-pick -x <commit-hash>
   ```

2. **Resolve conflicts and verify build** (if any):
   Use the `backport-conflict-resolver` agent to:
   - Resolve merge conflicts from cherry-pick
   - Fix build errors after conflict resolution
   - Detect and report missing dependency commits
   - Iterate until the code compiles successfully

   The agent will report success when build passes, or failure with missing dependency details if it cannot resolve.

   **Do NOT proceed if the agent reports failure**. Handle missing dependencies first.

3. **Verify build BEFORE committing** (if no conflicts occurred):
   ```bash
   make -j$(nproc) M=<modified-path>
   # Or full build if needed
   make -j$(nproc)
   ```

   **Do NOT proceed if build fails**. Fix issues first:
   - Adjust the code to resolve build errors
   - Re-verify build
   - Only proceed when build succeeds

4. **Review/Edit commit message** following the backport format:

   ```
   <Original commit title>

   <Original commit body>

   (cherry picked from commit <original-commit-hash>)

   Signed-off-by: Original Author <original@email>
   [Other original tags: Acked-by:, Reviewed-by:, Link:, etc. - preserved in place]

   [User name: Include any additional notes about adaptations made for backport]

   Signed-off-by: <your-name> <your-email>
   ```

   **Your task**:
   - Add adaptation notes if needed (before your Signed-off-by)
   - Add your own `Signed-off-by` at the very END

5. **Complete the cherry-pick**:
   ```bash
   git cherry-pick --continue
   ```

6. **Proceed to next commit** (build already verified in step 3)

**If unable to resolve**:
- Consider aborting: `git cherry-pick --abort`
- Report the issue to user for guidance

### Phase 3: Final Verification

After all commits are backported:
- Full kernel build
- Run relevant tests
- Verify original functionality preserved

## Dependency Analysis

Commits often depend on other commits. Missing dependencies cause:
- Build failures
- Runtime bugs
- Subtle behavioral changes

**Analysis checklist**:
- Check for "Fixes:" tags in commit messages
- Identify API/function changes that may have prerequisites
- Use `git log -p --all -S 'symbol'` to find when symbols were introduced
- Leverage the `backport-dependency-analyzer` agent for complex cases

## Conflict Resolution

When conflicts occur:

1. **Understand the conflict**:
   ```bash
   git diff --name-only --diff-filter=U  # List conflicted files
   git show <original-commit>:<file>     # View original version
   ```

2. **Resolution principles**:
   - Preserve original commit intent
   - Adapt to target branch's codebase
   - Maintain API compatibility
   - Do not introduce new features

3. **Common patterns**:
   - **Function signature changes**: Adapt call sites to target API
   - **Missing structures**: May need additional backports
   - **Renamed symbols**: Update to target naming
   - **Context differences**: Apply to equivalent locations

## Quality Checklist

Before finalizing:
- [ ] Plan was reviewed and approved by user
- [ ] All commits processed one-by-one
- [ ] Each commit compiles before proceeding
- [ ] Commit messages follow conventions
- [ ] Final kernel builds successfully
- [ ] Relevant tests pass

## Available Agents

- **`backport-dependency-analyzer`**: Analyze commit dependencies before backport. Use when planning to identify prerequisite commits.
- **`backport-conflict-resolver`**: Resolve conflicts and fix build errors during backport. Use when cherry-pick results in conflicts or build failures.

## Additional Resources

### Kernel Documentation

Refer to the Linux kernel source tree:
- `Documentation/process/submitting-patches.rst` - Patch submission guidelines
- `Documentation/process/stable-kernel-rules.rst` - Stable kernel backport rules

### Examples

- `examples/backport-plan-template.md` - Template for backport plans (use this for planning phase)

## Quick Reference

```bash
# Cherry-pick single commit
git cherry-pick -x <commit-hash>

# View conflicted files
git diff --name-only --diff-filter=U

# Continue after resolution
git cherry-pick --continue

# Abort if needed
git cherry-pick --abort

# Build specific path
make -j$(nproc) M=drivers/net

# Find symbol introduction
git log -p --all -S 'function_name' -- <path>
```
