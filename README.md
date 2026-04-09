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

en | [zh_CN](README.zh_CN.md)

> [!WARNING]
>
> This English README is translated from the Chinese version using LLM and may
> contain errors.

Personal development toolkit for [Claude Code](https://code.claude.com).

## Install

In Claude Code, run:

```
/plugin
```

1. Add marketplace black-desk/bdev;
2. Install bdev plugin.

And then restart claude code.

That's it. The plugin's skills and agents are now available in your Claude Code
session.

## Verify installation

Run `/plugin` and check the **Installed** tab. You should see `bdev@bdev`
listed.

## Update

To get the latest version:

```
/plugin marketplace update bdev
/plugin install bdev@bdev
/reload-plugins
```

## Uninstall

```
/plugin uninstall bdev@bdev
```

## License

Unless otherwise specified, all files in this project are open source under the
MIT License.

This project complies with the [REUSE specification].

You can use [reuse-tool](https://github.com/fsfe/reuse-tool) to generate the
SPDX list for this project:

```bash
reuse spdx
```

[REUSE specification]: https://reuse.software/spec-3.3/
