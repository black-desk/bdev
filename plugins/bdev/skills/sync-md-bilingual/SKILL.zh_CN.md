---
name: sync-md-bilingual
description: |
  当用户要求 "sync translations"、"同步双语文档"、"对比翻译"、"update bilingual docs"、"sync md files"、"比较中英文文档"、"compare translations"、"双向同步"、"check if translations are up to date"，或想要比较和同步成对的英文和中文 markdown 文件之间的内容时，应使用此 skill。
---

比较成对的双语 markdown 文件（`.md` 和 `.zh_CN.md`），并从较新版本同步内容到较旧版本。

## 工作流程

1. **发现双语文件对。** 递归扫描项目（跳过 `.git/`、`node_modules/` 和其他非内容目录），查找匹配 `<name>.md` + `<name>.zh_CN.md` 模式的文件。将列表呈现给用户，或处理用户指定的文件。

2. **确定哪一侧较新。** 对于每对文件，确定哪个文件最近被更新过。如果无法确定方向，询问用户。

3. **同步。** 更新旧文件以匹配新文件。遵循与 `translate-md` skill 相同的翻译规则：

   - 完全保留 markdown 结构。
   - 不翻译代码块、URL、文件路径或行内代码。
   - 不翻译专有名词、项目名称或命令名称。
   - 保持 REUSE / SPDX 头不变。
   - 匹配原文的语调。

   同步后，确保两个文件顶部的语言切换导航链接（`[en](...) | zh_CN` 行）正确并相互指向。

4. **报告结果。** 处理每对文件后，报告：

   - 使用了哪个方向。
   - 添加、更新或删除了哪些部分。
   - 跳过的任何有歧义的情况。
