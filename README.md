# bdev

Personal development toolkit for Linux kernel development and backport workflows.

## Features

- **kbackport Skill**: Guidance and best practices for backporting commits between kernel branches
- **Backport Dependency Analyzer**: Agent that automatically analyzes commit dependencies and suggests backport order
- **Backport Conflict Resolver**: Agent that resolves merge conflicts and build failures during backport

## Installation

```bash
# Clone directly to Claude plugins directory
mkdir -p ~/.claude/plugins
git clone https://github.com/black-desk/bdev ~/.claude/plugins
```

## Usage

### Skill: kbackport

The skill can be used in two ways:

**1. Direct invocation:**
```
/kbackport
```

**2. Automatic trigger** when you mention:
- "backport commit"
- "backport到release分支"
- "移植内核补丁"
- "cherry-pick依赖分析"

### Agent: Backport Dependency Analyzer

The agent automatically triggers when you discuss backporting multiple commits and will:
- Analyze commit dependency chains
- Identify commits that must be backported together
- Suggest the optimal backport order

### Agent: Backport Conflict Resolver

The agent automatically triggers when backport encounters conflicts or build failures and will:
- Resolve merge conflicts from cherry-pick operations
- Fix build errors after conflict resolution
- Detect and report missing dependency commits
- Iterate until the code compiles successfully

## Directory Structure

```
bdev/
├── .claude-plugin/
│   └── plugin.json
├── agents/
│   ├── backport-conflict-resolver.md
│   └── backport-dependency-analyzer.md
└── skills/
    └── kbackport/
        ├── SKILL.md
        └── examples/
            └── backport-plan-template.md
```

## License

MIT
