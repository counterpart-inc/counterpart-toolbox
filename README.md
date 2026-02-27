# counterpart-toolbox

> **yourclaude** — Counterpart's standard Claude setup system.

A CLI wrapper for [Claude Code](https://claude.ai/code) that enforces a shared baseline across the Counterpart engineering team: consistent plugin setup, required CLI tools, MCP server configuration, and injected company guidelines — so every engineer's Claude session starts from the same foundation.

---

## What It Does

Before every Claude session `yourclaude` runs six health checks:

| # | Check | Auto-fix |
|---|-------|----------|
| 1 | `claude` CLI is installed | Shows install URL |
| 2 | Required CLI tools present (`jq`, `ripgrep`, `ast-grep`) | Prompts to install via brew |
| 3 | Counterpart plugin marketplaces are registered | Prompts to register |
| 4 | Required plugins are installed (`cmpd`, `hire`, `plugin-dev`, `pyright-lsp`) | Prompts to install |
| 5 | MCP servers are reachable | Warns, lets you continue; hints to run `/mcp` for auth |
| 6 | `CLAUDE.md` in CWD has Counterpart guidelines | Injects into Claude context for the session |

If everything is green, it hands off to `claude` transparently.

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
3. Symlinks `yourclaude` → `~/.local/bin/yourclaude`
4. Adds `~/.local/bin` to `PATH` in your shell rc file
5. Registers tab completions for bash/zsh
6. Checks required CLI tools (`jq`, `ripgrep`, `ast-grep`) and offers to install missing ones
7. Runs `yourclaude setup` (first-time wizard)

### Prerequisites

- `git`
- `curl`
- [`claude` CLI](https://claude.ai/code)
- SSH key added to your GitHub account

---

## Usage

```bash
yourclaude               # health check → launch claude interactive
yourclaude "write tests" # health check → pass args to claude
yourclaude setup         # re-run setup wizard
yourclaude status        # show health check results without launching claude
yourclaude update        # self-update toolbox + pull latest plugins + re-install plugins
yourclaude reset         # clear configuration and start fresh
yourclaude uninstall     # remove yourclaude, plugins, and marketplaces from this machine
```

---

## Repository Structure

```
counterpart-toolbox/
├── .gitmodules                ← points plugins/ → counterpart-plugins
├── plugins/                   ← git submodule: counterpart-plugins
├── install.sh                 ← curl-installable (or clone-and-run) bootstrap
├── yourclaude                 ← main wrapper script (bash)
├── lib/
│   ├── check_claude.sh        ← verify claude CLI is installed
│   ├── check_tools.sh         ← required CLI tools check (reads from config)
│   ├── check_plugins.sh       ← marketplace registration + plugin installs
│   ├── check_mcp.sh           ← ping MCP server endpoints
│   └── check_guidelines.sh    ← validate/inject CLAUDE.md content
├── completions/
│   ├── yourclaude.zsh         ← zsh tab completion
│   └── yourclaude.bash        ← bash tab completion
└── templates/
    ├── config.json            ← default workspace config (plugins, tools, MCPs)
    └── guidelines.md          ← canonical company CLAUDE.md / system prompt template
```

---

## Choosing Your Workspace Path

During setup you will be asked:

```
Where is your Counterpart workspace folder? [/your/current/path]
```

This should be the **parent directory where all your Counterpart repos are cloned** — not a specific repo. For example, if your repos live like this:

```
~/projects/work/counterpart/
├── uas/
├── uas_frontend/
├── insurance-platform-cms/
├── counterpart-toolbox/
└── counterpart-plugins/
```

Then your workspace is `~/projects/work/counterpart/`. That is where `yourclaude` creates its `.counterpart/` config folder and where it looks for `CLAUDE.md` guidelines.

---

## Workspace Structure (created at setup)

```
{WORKSPACE}/                       ← parent folder of all Counterpart repos
├── uas/
├── uas_frontend/
├── ...
└── .counterpart/                  ← created by yourclaude setup
    ├── config.json                ← required plugins, tools, MCP URLs, guidelines header
    ├── guidelines.md              ← company guidelines (local copy, editable)
    └── state.json                 ← last check timestamp
```

**Global pointer** (set during setup):
```
~/.config/counterpart/config.json  →  { "workspace": "/path/to/your/workspace" }
```

---

## Configuration

### `.counterpart/config.json`

```json
{
  "version": "1.0.0",
  "marketplaces": [
    "git@github.com:counterpart-inc/counterpart-plugins.git",
    "anthropics/claude-plugins-official"
  ],
  "required_plugins": ["cmpd", "hire", "plugin-dev", "pyright-lsp"],
  "required_tools": [
    {"cmd": "jq",       "brew": "jq"},
    {"cmd": "rg",       "brew": "ripgrep"},
    {"cmd": "ast-grep", "brew": "ast-grep"}
  ],
  "mcp_servers": {
    "linear":   "https://mcp.linear.app/sse",
    "sentry":   "https://mcp.sentry.dev/mcp",
    "context7": "https://mcp.context7.com/mcp"
  },
  "guidelines_header": "# Counterpart Guidelines"
}
```

- **`marketplaces`** — plugin marketplaces to register with Claude Code
- **`required_plugins`** — plugins that must be installed before every session
- **`required_tools`** — CLI tools checked (and optionally brew-installed) on each run
- **`mcp_servers`** — pinged with a short timeout; 401 means auth needed (`/mcp`), unreachable warns but doesn't block
- **`guidelines_header`** — unique string used to detect whether company guidelines are already in `CLAUDE.md`

To add a tool, plugin, or MCP server: edit this file and open a PR. All engineers pull the change via `yourclaude update`.

### `guidelines.md`

Located at `{WORKSPACE}/.counterpart/guidelines.md`. This is the local, editable copy of the company Claude guidelines. It is either prepended to `CLAUDE.md` or injected into Claude's context via `--append-system-prompt` when no `CLAUDE.md` is present.

To update the canonical template: edit `templates/guidelines.md` in this repo and open a PR.

---

## Updating

```bash
yourclaude update
```

This pulls the latest toolbox, updates the `plugins/` submodule, and re-installs all required plugins.

---

## Uninstalling

```bash
yourclaude uninstall
```

Removes the symlink, toolbox repo, global config, shell completions, Claude plugins, and registered marketplaces.

---

## Contributing

The `plugins/` directory is a submodule pointing to `counterpart-plugins`. Plugin changes live in that repo. Wrapper, install flow, health check, or template changes live here.

---

## Troubleshooting

**`curl: (56) The requested URL returned error: 404`**
The install token is missing, wrong, or expired. Grab the current token from Notion under **Engineering Onboarding → counterpart-toolbox install token**. Alternatively, use the [clone fallback](#fallback--clone-and-run).

**`yourclaude: command not found`**
Reload your shell: `source ~/.zshrc` (or `~/.bashrc`), then try again.

**`claude CLI not found`**
Install Claude Code: https://claude.ai/code

**MCP servers showing 401**
Authentication is needed. Launch `yourclaude` and run `/mcp` inside the Claude session to authenticate each server.

**MCP server unreachable**
This is a warning, not a hard failure. You can continue in offline mode. Check your network and try again later.

**Re-run setup**
```bash
yourclaude setup
```

**Start completely fresh**
```bash
yourclaude reset
```
