---
name: translate-md
description: |
  This skill should be used when the user asks to "translate this document", "translate README", "创建中文翻译", "翻译文档", "翻译这个md文件", "翻译所有文档", "add Chinese translation", "generate zh_CN", "translate all markdown files", or wants to create a simplified Chinese (zh_CN) translation for one or more English markdown files.
---

Translate English markdown files into simplified Chinese (zh_CN).

## Workflow

1. **Identify the source file.** Determine the target `.md` file from the user's
   request or current context. Confirm the file exists and read its full content.

2. **Check for existing translation.** Look for a corresponding `.zh_CN.md` file
   alongside the source (e.g., `README.md` → `README.zh_CN.md`). If one already
   exists, inform the user and ask whether to overwrite or update it.

3. **Produce the translation.** Translate the entire document into simplified
   Chinese, following these rules:

   - Preserve the original markdown structure (headings, lists, tables, links,
     code blocks, etc.) exactly as-is.
   - Do **not** translate content inside code blocks, URLs, file paths, or
     inline code.
   - Do **not** translate proper nouns, project names, command names, or brand
     names.
   - Keep REUSE / SPDX headers unchanged.
   - Match the tone of the original: technical docs stay technical, casual docs
     stay casual.

4. **Add language-switch links.** At the top of the translated file (after any
   REUSE/SPDX headers), add a language navigation line:

   ```
   [en](<basename>.md) | zh_CN
   ```

   If the source file does not already have a similar link, also add one to the
   source file:

   ```
   en | [zh_CN](<basename>.zh_CN.md)
   ```

   Replace `<basename>` with the actual filename stem (e.g., `README`,
   `CHANGELOG`, `CONTRIBUTING`).

5. **Write the translated file.** Save as `<basename>.zh_CN.md` in the same
   directory as the source file. Use the Write tool to create the file.

## Batch Translation

When the user asks to translate multiple files or an entire project, scan the
project for all `.md` files that lack a corresponding `.zh_CN.md` counterpart
(excluding files that are already translations). Process each file following the
workflow above.

## Notes

- If the source file is already in Chinese, inform the user — no translation is
  needed.
- If the source file contains mixed languages, only translate the English
  portions.
