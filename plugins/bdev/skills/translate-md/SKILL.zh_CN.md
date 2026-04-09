---
name: translate-md
description: |
  当用户要求 "translate this document"、"translate README"、"创建中文翻译"、"翻译文档"、"翻译这个md文件"、"翻译所有文档"、"add Chinese translation"、"generate zh_CN"、"translate all markdown files"，或想要为一个或多个英文 markdown 文件创建简体中文 (zh_CN) 翻译时，应使用此 skill。
---

将英文 markdown 文件翻译为简体中文 (zh_CN)。

## 工作流程

1. **识别源文件。** 从用户的请求或当前上下文中确定目标 `.md` 文件。确认文件存在并阅读其完整内容。

2. **检查现有翻译。** 在源文件旁边查找对应的 `.zh_CN.md` 文件（例如 `README.md` → `README.zh_CN.md`）。如果已经存在，通知用户并询问是覆盖还是更新。

3. **进行翻译。** 将整个文档翻译为简体中文，遵循以下规则：

   - 完全保留原始 markdown 结构（标题、列表、表格、链接、代码块等）。
   - **不**翻译代码块、URL、文件路径或行内代码中的内容。
   - **不**翻译专有名词、项目名称、命令名称或品牌名称。
   - 保持 REUSE / SPDX 头不变。
   - 匹配原文的语调：技术文档保持技术性，休闲文档保持休闲性。

4. **添加语言切换链接。** 在翻译文件的顶部（在任何 REUSE/SPDX 头之后）添加一行语言导航：

   ```
   [en](<basename>.md) | zh_CN
   ```

   如果源文件还没有类似的链接，也向源文件添加一个：

   ```
   en | [zh_CN](<basename>.zh_CN.md)
   ```

   将 `<basename>` 替换为实际的文件名主干（例如 `README`、`CHANGELOG`、`CONTRIBUTING`）。

5. **写入翻译文件。** 在与源文件相同的目录中保存为 `<basename>.zh_CN.md`。使用 Write 工具创建文件。

## 批量翻译

当用户要求翻译多个文件或整个项目时，扫描项目中所有缺少对应 `.zh_CN.md` 的 `.md` 文件（排除已经是翻译的文件）。按照上述工作流程处理每个文件。

## 注意事项

- 如果源文件已经是中文，通知用户 — 无需翻译。
- 如果源文件包含混合语言，只翻译英文部分。
