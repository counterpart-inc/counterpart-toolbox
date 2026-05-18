# counterpart-toolbox

> **yourcounterpart** — Counterpart's agent-agnostic AI context installer.

An installer and syncer that distributes company-standard AI context — rules, skills, and MCP servers — to every Counterpart developer's AI coding tool. Works with Claude Code, Cursor, Copilot, OpenCode, and more. You keep using your agent. It already has the right context.

---

## What It Does

`yourcounterpart setup` runs once and configures your AI agents:

| # | What happens | How |
|---|-------------|-----|
| 1 | Detects which AI agents you have installed | Checks for `claude`, `cursor`, `code`, `opencode` |
| 2 | Installs company rules into each agent | Managed blocks in CLAUDE.md, .cursor/rules/, AGENTS.md, etc. |
| 3 | Installs company skills into each agent | capture, doc-check, pr-create, and more |
| 4 | Configures MCP servers | Linear, Sentry, Context7 |
| 5 | Checks required CLI tools | `jq`, `ripgrep`, `ast-grep` |

After setup, **open your agent directly** — no wrapper, no interception. Company context is already there.

---

## Installation

### Primary — curl installer

> **Prerequisite:** your SSH key must be added to your GitHub account before running.

This repo is private. A shared read-only GitHub PAT is stored in Notion under **Engineering Onboarding → counterpart-toolbox install token**.

```bash
curl -fsSL https://<TOKEN>@raw.githubusercontent.com/counterpart-inc/counterpart-toolbox/main/install.sh | bash
```

Replace `<TOKEN>` with the value from Notion. The token is only used to fetch `install.sh` — cloning the repo itself uses your SSH key.

### Fallback — clone and run

If the curl approach fails (token issues, network restrictions, etc.), clone the repo manually and run the installer directly:

```bash
git clone git@github.com:counterpart-inc/counterpart-toolbox.git
cd counterpart-toolbox
bash install.sh
```

Both paths produce the same result.

### What the installer does

1. Clones the repo to `~/.local/share/counterpart-toolbox/` via SSH
2. Initializes the `plugins/` submodule (`counterpart-plugins`)
3. Symlinks `yourcounterpart` → `~/.local/bin/yourcounterpart`
4. Adds `~/.local/bin` to `PATH` in your shell rc file
5. Registers tab completions for bash/zsh
6. Checks required CLI tools (`jq`, `ripgrep`, `ast-grep`) and offers to install missing ones
7. Runs `yourcounterpart setup` (detects your agents and syncs company context)

### Prerequisites

- `git`, `curl`
- SSH key added to your GitHub account
- At least one AI coding agent installed (Claude Code, Cursor, Copilot, OpenCode, etc.)

---

## Usage

```bash
yourcounterpart setup            # one-time: detect agents, install company context
yourcounterpart update           # pull latest plugins and re-sync to all agents
yourcounterpart status           # health check (tools, MCP servers)
yourcounterpart context sync     # generate/update context.lock for current repo
yourcounterpart context validate # check if context.lock is current
yourcounterpart reset            # clear configuration and start fresh
yourcounterpart uninstall        # remove yourcounterpart from this machine
```

---

## Repository Structure

```
counterpart-toolbox/
├── yourcounterpart            ← main CLI (setup, update, context, status)
├── install.sh                 ← curl-installable bootstrap
├── lib/
│   ├── sync.sh                ← sync engine: .agents/ → agent native formats
│   ├── context-lock.sh        ← context.lock generate + validate
│   ├── check_tools.sh         ← required CLI tools check
│   ├── check_mcp.sh           ← MCP server health check
│   └── check_guidelines.sh    ← guidelines injection check
├── ci/
│   └── check-context-lock.sh  ← CI enforcement script (repos adopt this)
├── plugins/                   ← git submodule: counterpart-plugins
│   ├── .agents/               ← company agents, rules, skills, MCP config
│   └── hooks/                 ← pre-commit hooks repos can adopt
├── completions/
│   ├── yourcounterpart.zsh
│   └── yourcounterpart.bash
├── templates/
│   ├── context/               ← knowledge hierarchy layer templates
│   ├── agents-structure.md    ← .agents/ directory spec
│   └── plugin-manifest.json   ← plugin schema
└── context/                   ← this repo's own knowledge layer
    ├── index.md               ← entry point for AI agents
    └── project-summaries/
```

---

## How It Works

### The `.agents/` hierarchy

Company context is organized in a two-level hierarchy:

```
~/.agents/                     ← global (installed by yourcounterpart setup)
  rules/                       ← company-wide rules (always applied)
  skills/                      ← company skills (on-demand)
  agents/                      ← default agent definition
  mcp.json                     ← company MCP servers

{repo}/.agents/                ← local (repo-specific extensions)
  rules/                       ← rules that only apply in this repo
  skills/                      ← repo-specific skills
```

On `yourcounterpart setup`, the global layer is populated from `counterpart-plugins` and synced to every detected agent. On `yourcounterpart update`, the same sync runs again with the latest plugins.

### Sync targets

The sync engine writes to each agent's native config format:

| Agent | Global output | Per-repo output |
|-------|--------------|----------------|
| Claude Code | `~/.claude/CLAUDE.md` | `AGENTS.md` |
| Cursor | `~/.cursor/rules/` | `.cursor/rules/` |
| OpenCode | `~/.config/opencode/AGENTS.md` | `AGENTS.md` |
| Copilot | `~/.copilot/copilot-instructions.md` | `.github/copilot-instructions.md` |

Rules are injected as **managed blocks** — content between `<!-- counterpart:managed:start -->` / `<!-- counterpart:managed:end -->` markers. Hand-written content outside the markers is preserved.

### context.lock

Each repo can have a `context/` directory with project knowledge (index, summaries, stories). The `context.lock` file is a SHA256 hash of all files in `context/`, committed with the code. CI can check that it's current before merge.

```bash
yourcounterpart context sync      # generate/update context.lock
yourcounterpart context validate  # check if it's current
```

See `ci/check-context-lock.sh` for the CI enforcement script.

### Global config

```
~/.config/counterpart/config.json  →  { "workspace": "...", "providers": ["claude", "cursor"] }
```

---

## Updating

```bash
yourcounterpart update
```

Pulls the latest toolbox and plugins submodule, then re-syncs company context to all detected agents. Also runs local sync if the current directory has a `.agents/` folder.

---

## Uninstalling

```bash
yourcounterpart uninstall
```

Removes the symlink, toolbox repo, global config, and shell completions.

---

## Contributing

**Skills, rules, agents, MCP config** → changes go in the `counterpart-plugins` submodule repo.

**Sync engine, install flow, context-lock, CLI commands** → changes go here in `counterpart-toolbox`.

**Templates** (`templates/context/`, `templates/agents-structure.md`) → also here.

When adding a new lib script: source it in `yourcounterpart` and add a shellcheck comment.

---

## Troubleshooting

**`yourcounterpart: command not found`**
Reload your shell: `source ~/.zshrc` (or `~/.bashrc`), then try again.

**`curl: (56) The requested URL returned error: 404`**
The install token is missing or expired. Grab it from Notion under **Engineering Onboarding → counterpart-toolbox install token**. Or use the [clone fallback](#fallback--clone-and-run).

**MCP servers showing unreachable**
Warning only — you can work offline. Check your network or run `yourcounterpart status` for details.

**Company rules not showing up in my agent**
Run `yourcounterpart setup` to re-sync. If your agent isn't listed, check if it was detected (`~/.config/counterpart/config.json` → `providers`).

**context.lock is stale**
Run `yourcounterpart context sync` in the repo, then `git add context.lock`.

**Re-run setup**
```bash
yourcounterpart setup
```

**Start completely fresh**
```bash
yourcounterpart reset
```
