#!/bin/bash

# SPDX-FileCopyrightText: 2026 Chen Linxuan <me@black-desk.cn>
# SPDX-License-Identifier: MIT

# 从标准输入(stdin)中解析出即将执行的 bash 命令
input=$(cat)
COMMAND=$(echo "$input" | jq -r '.tool_input.command // empty')

# 无有效输入则放行
if [ -z "$COMMAND" ]; then
	exit 0
fi

# 使用正则匹配是否包含 pull, push, fetch
if echo "$COMMAND" | grep -qE '\bgit\s+(pull|push|fetch)\b'; then
	jq -n '{
  hookSpecificOutput: {
    permissionDecision: "deny"
  },
  systemMessage: "Git 网络操作 (pull, push, fetch) 在当前 Skill 执行期间已被系统禁用。"
}'
	exit 0
fi
