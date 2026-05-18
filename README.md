# counterpart-toolbox

> **yourcounterpart** — Counterpart's agent-agnostic AI context installer.

Distributes company-standard AI context — rules, skills, and agents — to every Counterpart developer's AI coding tool. Works with Claude Code, Cursor, Copilot, OpenCode, Gemini, Pi, and more. You keep using your agent. It already has the right context.

---

## What It Does

`yourcounterpart setup` runs once and configures your environment:

| # | What happens | How |
|---|-------------|-----|
| 1 | Asks for your Counterpart workspace folder | Prompts once, remembers forever |
| 2 | Creates `{workspace}/.counterpart/` with agents, rules, skills | Copied from toolbox defaults |
| 3 | Sets `COUNTERPART_WORKSPACE` in your shell rc | Available in every session |
| 4 | Detects which AI agents you have installed | Checks for `claude`, `cursor`, `opencode`, etc. |
| 5 | Persists detected providers to `config.json` | Used by sync and update |
| 6 | Checks required CLI tools and MCP servers | `jq`, `ripgrep`, `ast-grep`, Linear, Sentry, Context7 |
| 7 | Syncs rules, skills, and agents to every provider | Native formats per agent |

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

```bash
git clone git@github.com:counterpart-inc/counterpart-toolbox.git
cd counterpart-toolbox
bash install.sh
```

### What the installer does

1. Clones the repo to `~/.local/share/counterpart-toolbox/` via SSH
2. Symlinks `yourcounterpart` → `~/.local/bin/yourcounterpart`
3. Adds `~/.local/bin` to `PATH` in your shell rc file
4. Registers tab completions for bash/zsh
5. Runs `yourcounterpart setup`

### Prerequisites

- `git`, `curl`
- SSH key added to your GitHub account
- At least one AI coding agent installed (Claude Code, Cursor, Copilot, OpenCode, etc.)

---

## Usage

```bash
yourcounterpart setup            # one-time: create .counterpart/, detect agents, sync
yourcounterpart sync             # push .counterpart/ content to all providers
yourcounterpart update           # pull latest toolbox, update .counterpart/, re-sync
yourcounterpart status           # health check: tools, MCP servers, sync state
yourcounterpart context sync     # generate/update context.lock for current repo
yourcounterpart context validate # check if context.lock is current
yourcounterpart reset            # clear configuration and start fresh
yourcounterpart uninstall        # remove yourcounterpart from this machine
```

---

## Repository Structure

```
counterpart-toolbox/
├── yourcounterpart            ← main CLI
├── install.sh                 ← curl-installable bootstrap
├── agents/                    ← default agent definitions (copied to .counterpart on setup)
├── rules/                     ← default rules (copied to .counterpart on setup)
├── skills/                    ← default skills (copied to .counterpart on setup)
├── lib/
│   ├── sync.sh                ← sync engine: .counterpart/ → agent native formats
│   ├── context-lock.sh        ← context.lock generate + validate
│   ├── check_tools.sh         ← required CLI tools check
│   └── check_mcp.sh           ← MCP server health check
├── ci/
│   └── check-context-lock.sh  ← CI enforcement script repos can adopt
├── completions/
│   ├── yourcounterpart.zsh
│   └── yourcounterpart.bash
├── docs/
│   └── onboarding-ai-context.md
└── context/                   ← this repo's own knowledge layer
    ├── index.md
    └── project-summaries/
```

---

## How It Works

### Workspace structure

Setup creates a `.counterpart/` directory inside your Counterpart workspace:

```
{workspace}/.counterpart/
├── config.json          ← providers, tools, MCPs, last_sync
├── agents/              ← agent definitions
├── rules/               ← company-wide rules (always applied)
├── skills/              ← company skills (on-demand)
└── toolbox.lock         ← written after every sync
```

`COUNTERPART_WORKSPACE` is exported to your shell so every command knows where to find it.

### Commands

**`setup`** — run once. Creates `.counterpart/`, copies defaults from the toolbox, detects providers, syncs.

**`sync`** — reads `.counterpart/` and writes to every detected provider's native config format. Run this after manually editing agents, rules, or skills.

**`update`** — pulls the latest toolbox from GitHub, copies updated agents/rules/skills into `.counterpart/`, then runs sync.

### Sync targets

| Agent | Rules / agents written to | Skills written to |
|-------|--------------------------|-------------------|
| Claude Code | `~/.claude/CLAUDE.md`, `~/.claude/agents/` | `~/.claude/skills/` |
| OpenCode | `~/.config/opencode/AGENTS.md`, `~/.config/opencode/agents/` | `~/.config/opencode/skills/` |
| Cursor | `~/.cursor/rules/` | — |
| Copilot | `~/.copilot/copilot-instructions.md` | — |
| Gemini | `~/.gemini/GEMINI.md` | — |
| Pi | `~/.pi/AGENTS.md` | — |

Rules are injected as **managed blocks** between `<!-- counterpart:managed:start -->` and `<!-- counterpart:managed:end -->` markers. Content outside the markers is preserved.

### context.lock

Each repo can have a `context/` directory with project knowledge (index, summaries, stories). `context.lock` is a SHA256 hash of all files in `context/`, committed with the code.

```bash
yourcounterpart context sync      # generate/update context.lock
yourcounterpart context validate  # check if it's current
```

See `ci/check-context-lock.sh` for the CI enforcement script.

---

## Updating

```bash
yourcounterpart update
```

Pulls the latest toolbox, copies updated agents/rules/skills into `.counterpart/`, then re-syncs to all providers.

---

## Contributing

**Agents, rules, skills** → edit files in `agents/`, `rules/`, `skills/` at the repo root. Developers get them on next `yourcounterpart update`.

**Sync engine, install flow, context-lock, CLI commands** → edit `yourcounterpart`, `lib/`, or `install.sh`.

When adding a new lib script: source it in `yourcounterpart` and add a shellcheck comment.

---

## Troubleshooting

**`yourcounterpart: command not found`**
Reload your shell: `source ~/.zshrc` (or `~/.bashrc`), then try again.

**`curl: (56) The requested URL returned error: 404`**
The install token is missing or expired. Grab it from Notion under **Engineering Onboarding → counterpart-toolbox install token**. Or use the [clone fallback](#fallback--clone-and-run).

**MCP servers showing unreachable**
Warning only — you can work offline. Run `yourcounterpart status` for details.

**Company rules not showing up in my agent**
Run `yourcounterpart sync`. If your agent isn't listed in providers, run `yourcounterpart setup` again to re-detect.

**context.lock is stale**
Run `yourcounterpart context sync` in the repo, then `git add context.lock`.

**Start completely fresh**
```bash
yourcounterpart reset
yourcounterpart setup
```
