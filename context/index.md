# counterpart-toolbox

Agent-agnostic installer and syncer that sets up company-standard AI context, skills, and rules for every Counterpart developer's AI coding tool — regardless of which agent they use.

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/counterpart-inc/counterpart-toolbox/main/install.sh | bash
yourcounterpart setup
```

After setup, open any AI agent (Claude Code, Cursor, Copilot, etc.) — company context is already configured.

## Architecture Overview

```
counterpart-toolbox/
├── yourcounterpart       # Main CLI (setup, update, context, status)
├── lib/
│   ├── sync.sh           # Sync engine: .agents/ → agent native formats
│   ├── context-lock.sh   # context.lock generation and validation
│   ├── check_tools.sh    # Required CLI tools check
│   ├── check_mcp.sh      # MCP server reachability check
│   └── check_guidelines.sh  # Guidelines injection check
├── ci/
│   └── check-context-lock.sh  # CI script for repos to adopt
├── plugins/              # counterpart-plugins submodule (.agents/ structure)
│   └── .agents/
│       ├── agents/       # Default company agent
│       ├── rules/        # Company-wide rules
│       ├── skills/       # Company skills (capture, doc-check, etc.)
│       └── mcp.json      # Company MCP servers
├── templates/
│   ├── context/          # Context hierarchy layer templates
│   ├── agents-structure.md  # .agents/ canonical format spec
│   └── plugin-manifest.json # Plugin manifest JSON schema
└── context/              # This knowledge layer
    ├── index.md          # You are here
    └── project-summaries/
```

## Key Conventions

- **Sync is idempotent**: running `yourcounterpart update` twice produces identical output
- **Managed blocks**: company rules are injected between `<!-- counterpart:managed:start/end -->` markers — hand-written content outside is preserved
- **Hierarchy**: `~/.agents/` (global, from plugins) + `{repo}/.agents/` (local extensions) — local extends global, never overrides
- **context.lock**: SHA256 hash of all `context/` files, committed with the code, enforced by CI

## Key Integrations

| Component | Purpose |
|-----------|---------|
| counterpart-plugins | Source of company agents, rules, skills (git submodule) |
| `~/.agents/` | Global canonical store (populated by setup/update) |
| Agent configs | Written by sync engine (CLAUDE.md, .cursor/rules/, AGENTS.md, etc.) |

## Commands

```bash
yourcounterpart setup            # One-time: detect agents, sync company context
yourcounterpart update           # Pull latest plugins, re-sync
yourcounterpart context sync     # Generate/update context.lock
yourcounterpart context validate # Check if context.lock is current
yourcounterpart status           # Health check
```
