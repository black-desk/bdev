<!--
SPDX-FileCopyrightText: 2026 Chen Linxuan <me@black-desk.cn>

SPDX-License-Identifier: MIT
-->

# bdev

[![checks][badge-shields-io-checks]][actions]
[![commit activity][badge-shields-io-commit-activity]][commits]
[![contributors][badge-shields-io-contributors]][contributors]
[![release date][badge-shields-io-release-date]][releases]
![commits since release][badge-shields-io-commits-since-release]

[badge-shields-io-checks]:
  https://img.shields.io/github/check-runs/black-desk/bdev/master
[actions]: https://github.com/black-desk/bdev/actions
[badge-shields-io-commit-activity]:
  https://img.shields.io/github/commit-activity/w/black-desk/bdev/master
[commits]: https://github.com/black-desk/bdev/commits/master
[badge-shields-io-contributors]:
  https://img.shields.io/github/contributors/black-desk/bdev
[contributors]: https://github.com/black-desk/bdev/graphs/contributors
[badge-shields-io-release-date]:
  https://img.shields.io/github/release-date/black-desk/bdev
[releases]: https://github.com/black-desk/bdev/releases
[badge-shields-io-commits-since-release]:
  https://img.shields.io/github/commits-since/black-desk/bdev/latest

[en](README.md) | zh_CN

[Claude Code](https://code.claude.com) 个人开发工具包。

## 安装

在 Claude Code 中运行：

```
/plugin
```

1. 添加 marketplace black-desk/bdev；
2. 安装 bdev 插件。

然后重启 Claude Code。

完成。插件的 skills 和 agents 现在已可在你的 Claude Code 会话中使用。

## 验证安装

运行 `/plugin` 并检查 **Installed** 标签页。你应该能看到 `bdev` 已列出。

## 贡献注意事项

本项目中的 markdown 文件为了方便用中文维护，都统一提供了中英两个语言的版本。

其中除了 README 有指向另一语言版本的链接以外其他 skill 和 agent 文件都没有这种链接。

因为本质上那些文档是给 claude code 读的。

## 许可证

如无特殊说明，该项目的所有文件均以 MIT 许可证开源。

该项目遵守[REUSE规范]。

你可以使用[reuse-tool](https://github.com/fsfe/reuse-tool)生成这个项目的SPDX列表：

```bash
reuse spdx
```

[REUSE规范]: https://reuse.software/spec-3.3/
