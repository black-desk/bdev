#!/bin/bash
set -euo pipefail

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if echo "$command" | grep -qE 'git\s+(push|pull|fetch)\b'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "permissionDecision": "deny"
  },
  "systemMessage": "Blocked: git push/pull/fetch is not allowed in this plugin. This is a read-only analysis workflow — all git operations should be local only."
}
EOF
  exit 0
fi

cat <<'EOF'
{
  "hookSpecificOutput": {
    "permissionDecision": "allow"
  }
}
EOF
