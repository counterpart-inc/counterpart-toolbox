# counterpart-toolbox

> **yourclaude** — your Claude, set up the right way.

A CLI wrapper for [Claude Code](https://claude.ai/code) that enforces a shared baseline across the Counterpart engineering team: consistent plugin setup, MCP server configuration, and injected company guidelines.

---

## What It Does

Before every Claude session `yourclaude` runs five health checks:

| # | Check | Auto-fix |
|---|-------|----------|
| 1 | `claude` CLI is installed | Shows install URL |
| 2 | Counterpart plugin marketplace is registered | Prompts to register |
| 3 | Required plugins are installed (e.g. `cmpd`) | Prompts to install |
| 4 | MCP servers are reachable | Warns, lets you continue |
| 5 | `CLAUDE.md` in CWD has company guidelines | Prompts to create/prepend |

If everything is green, it hands off to `claude` transparently.

---

## Installation

A shared read-only GitHub PAT (stored in Notion under **Engineering Onboarding**) is embedded in the install command:

```bash
curl -fsSL https://<SHARED_READONLY_PAT>@raw.githubusercontent.com/counterpart-inc/counterpart-toolbox/main/install.sh | bash
```

This single command:
1. Clones the repo to `~/.local/share/counterpart-toolbox/`
2. Initializes the `plugins/` submodule (`counterpart-plugins`)
3. Symlinks `yourclaude` → `~/.local/bin/yourclaude`
4. Adds `~/.local/bin` to `PATH` in your shell rc file
5. Runs `yourclaude setup` (first-time wizard)

> **Token hygiene:** The PAT has `Contents: Read-only` scope on this repo only. Rotate it if it leaks.

### Prerequisites

- `git`
- `curl`
- `jq` (`brew install jq` / `sudo apt install jq`)
- [`claude` CLI](https://claude.ai/code)

---

## Usage

```bash
yourclaude               # health check → launch claude interactive
yourclaude "write tests" # health check → pass args to claude
yourclaude setup         # re-run setup wizard
yourclaude status        # show health check without launching claude
yourclaude update        # self-update toolbox + pull latest plugins + re-install plugins
```

---

## Repository Structure

```
counterpart-toolbox/
├── .gitmodules              ← points plugins/ → counterpart-plugins
├── plugins/                 ← git submodule: counterpart-plugins
├── install.sh               ← curl-installable bootstrap
├── yourclaude               ← main wrapper script (bash)
├── lib/
│   ├── check_claude.sh      ← verify claude CLI is installed
│   ├── check_plugins.sh     ← marketplace registration + plugin installs
│   ├── check_mcp.sh         ← ping MCP server endpoints
│   └── check_guidelines.sh  ← validate/inject CLAUDE.md content
└── templates/
    └── guidelines.md        ← canonical company CLAUDE.md template
```

---

## Workspace Structure (created at setup)

```
{WORKSPACE}/                     ← e.g. ~/projects/work/counterpart/
└── .counterpart/
    ├── config.json              ← required plugins, MCP URLs, guidelines header
    ├── guidelines.md            ← company guidelines (local copy, editable)
    └── state.json               ← last check timestamps, installed versions
```

**Global pointer** (set during setup):
```
~/.config/counterpart/config.json
  → { "workspace": "~/projects/work/counterpart" }
```

---

## Configuration

### `.counterpart/config.json`

```json
{
  "version": "1.0.0",
  "marketplace": "git@github.com:counterpart-inc/counterpart-plugins.git",
  "required_plugins": ["cmpd"],
  "mcp_servers": {
    "linear": "https://mcp.linear.app/sse",
    "sentry": "https://mcp.sentry.dev/mcp",
    "context7": "https://mcp.context7.com/mcp"
  },
  "guidelines_header": "# Counterpart Guidelines"
}
```

- **`required_plugins`** — plugins that must be installed before every session
- **`mcp_servers`** — pinged with a 3-second timeout; unreachable servers warn but don't block
- **`guidelines_header`** — the unique string used to detect whether company guidelines are already present in `CLAUDE.md`

Edit this file to add plugins or MCP servers for your team.

### `guidelines.md`

Located at `{WORKSPACE}/.counterpart/guidelines.md`. This is your local, editable copy of the company Claude guidelines. It is prepended to any `CLAUDE.md` that is missing the guidelines header.

To update the canonical template: edit `templates/guidelines.md` in this repo and open a PR.

---

## Updating

```bash
yourclaude update
```

This:
1. `git pull` on the toolbox repo
2. `git submodule update --remote --merge` on `plugins/`
3. Re-installs all required plugins via `claude plugin install`

---

## Contributing

The `plugins/` directory is a submodule pointing to `counterpart-plugins`. Changes to plugins live in that repo. Changes to the wrapper, install flow, or health checks live here.

---

## Troubleshooting

**`yourclaude: command not found`**
Reload your shell: `source ~/.zshrc` (or `~/.bashrc`), then try again.

**`jq: command not found`**
Install jq: `brew install jq` (macOS) or `sudo apt install jq` (Linux).

**`claude CLI not found`**
Install Claude Code: https://claude.ai/code

**MCP server unreachable**
This is a warning, not a hard failure. You can continue in offline mode. Check your network and try again later.

**Re-run setup**
```bash
yourclaude setup
```
