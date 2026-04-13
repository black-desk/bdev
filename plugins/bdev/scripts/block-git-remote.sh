#!/bin/bash

# SPDX-FileCopyrightText: 2026 Chen Linxuan <me@black-desk.cn>
# SPDX-License-Identifier: MIT

set -euo pipefail

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if echo "$command" | grep -qE 'git\s+(push|pull|fetch)\b'; then
	exit 0
fi

echo "Blocked: git push/pull/fetch is not allowed in this plugin. This is a read-only analysis workflow — all git operations should be local only." >&2
exit 2
