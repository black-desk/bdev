---
name: sync-md-bilingual
description: |
  This skill should be used when the user asks to "sync translations", "同步双语文档", "对比翻译", "update bilingual docs", "sync md files", "比较中英文文档", "compare translations", "双向同步", "check if translations are up to date", or wants to compare and synchronize content between paired English and Chinese markdown files.
---

Compare paired bilingual markdown files (`.md` and `.zh_CN.md`) and synchronize
content from the newer version to the older one.

## Workflow

1. **Discover bilingual pairs.** Recursively scan the project (skipping
   `.git/`, `node_modules/`, and other non-content directories) for files
   matching the pattern `<name>.md` + `<name>.zh_CN.md`. Present the list to
   the user, or process the specific files the user pointed out.

2. **Determine which side is newer.** For each pair, determine which file
   has been updated more recently. If unable to determine the direction, ask
   the user.

3. **Synchronize.** Update the older file to match the newer one. Follow the
   same translation rules as the `translate-md` skill:

   - Preserve markdown structure exactly.
   - Do not translate code blocks, URLs, file paths, or inline code.
   - Do not translate proper nouns, project names, or command names.
   - Keep REUSE / SPDX headers unchanged.
   - Match the tone of the original.

   After synchronizing, ensure the language-switch navigation links
   (`[en](...) | zh_CN` lines) at the top of both files are correct and
   point to each other.

4. **Report results.** After processing each pair, report:

   - Which direction was used.
   - Which sections were added, updated, or removed.
   - Any ambiguous cases that were skipped.
