#!/bin/bash

# SPDX-FileCopyrightText: 2026 Chen Linxuan <me@black-desk.cn>
# SPDX-License-Identifier: MIT

# 从标准输入(stdin)中解析出即将执行的 bash 命令
COMMAND=$(jq -r '.tool_input.command')

# 使用正则匹配是否包含 pull, push, fetch
if echo "$COMMAND" | grep -qE '\bgit\s+(pull|push|fetch)\b'; then
	# 如果包含，则输出 JSON 返回 deny 决定，并附带拒绝理由反馈给 Claude
	jq -n '{
hookSpecificOutput: {
  hookEventName: "PreToolUse",
  permissionDecision: "deny",
  permissionDecisionReason: "Git 网络操作 (pull, push, fetch) 在当前 Skill 执行期间已被系统禁用。"
}
}'
	exit 1
fi
