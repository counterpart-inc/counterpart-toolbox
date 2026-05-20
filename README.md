# counterpart-toolbox

AI context distribution tool for Counterpart engineers. Syncs company skills, agents, commands, hooks, and MCP servers from [`counterpart-plugins`](https://github.com/counterpart-inc/counterpart-plugins) to your local AI providers.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/counterpart-inc/counterpart-toolbox/main/install.sh | bash
source ~/.zshrc
```

Then run:

```bash
counterpart sync
```

## How it works

```
counterpart-plugins (main)
        ↓ CI on push
counterpart-plugins (generated branch)
        ↓ counterpart sync
~/.claude/   ~/.config/opencode/   ~/.pi/agent/   ~/.cursor/
```

1. `counterpart-plugins` is a monorepo of AI plugins (skills, agents, commands, hooks, MCP servers).
2. A CI pipeline generates a `generated` branch with provider-specific output from those plugins.
3. `counterpart sync` pulls the `generated` branch and distributes files to your local AI providers.

Updates are detected by comparing SHA256 aggregate hashes (`counterpart-ai.lock`). A background check runs on terminal open (once every 7 days) and prompts if updates are available.

## Providers

| Provider | Skills | Agents | Commands | Hooks | Output styles | MCP |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| Claude Code | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| OpenCode | ✓ | ✓ | ✓ | — | — | ✓ |
| Pi | ✓ | — | — | — | — | — |
| Cursor | ✓ | — | — | — | — | — |

Provider detection is automatic. You choose which providers and assets to sync during first-run setup.

## Commands

```bash
counterpart sync                  # Sync to all configured providers
counterpart sync --source <dir>   # Sync from a local generated/ directory (dev/test)
counterpart configure             # Re-run provider/asset setup
counterpart status                # Show current sync state
counterpart update                # Pull latest toolbox + re-sync
```

## File placement

Files land in dedicated company-owned locations. User files are never overwritten.

| Asset | Claude | OpenCode | Pi | Cursor |
|---|---|---|---|---|
| Skills | `~/.claude/skills/` | `~/.config/opencode/skills/` | `~/.pi/agent/skills/` | `~/.cursor/rules/` |
| Agents | `~/.claude/agents/` | `~/.config/opencode/agents/` | — | — |
| Commands | `~/.claude/commands/` | `~/.config/opencode/commands/` | — | — |
| Hooks | `.claude/settings.json` ¹ | — | — | — |
| Output styles | `~/.claude/output-styles/` | — | — | — |
| MCP | `.mcp.json` ¹ | `~/.config/opencode/opencode.json` ² | — | — |

¹ Project-level — written to the current working directory.  
² Merged under `counterpart-*` namespaced keys. User's own keys are untouched.

## State

Everything lives under `~/.config/counterpart/`:

```
~/.config/counterpart/
├── sync.json            # Provider/asset preferences
├── counterpart-ai.lock  # Hash of last synced content
├── .last-check          # Timestamp of last update check
└── cache/               # Local clone of counterpart-plugins@generated
```

## Development

```bash
# Clone and install locally (symlinks this repo, no remote clone)
make install

# Sync from local generated/ output
make sync

# Re-run interactive configure
make configure

# Remove hook and symlink
make uninstall
```

To test the full pipeline locally:

```bash
# In counterpart-plugins
make generate-clean

# In counterpart-toolbox
counterpart sync --source ../counterpart-plugins/generated
```
