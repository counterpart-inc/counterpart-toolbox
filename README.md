# counterpart-toolbox

> **yourcounterpart** — Counterpart's agent-agnostic AI context installer.
-- test --
Distributes company-standard AI context — rules, skills, and agents — to every Counterpart developer's AI coding tool. Works with Claude Code, OpenCode, and Pi. You keep using your agent. It already has the right context.

---

## What It Does

`yourcounterpart setup` runs once and configures your environment:

| # | What happens | How |
|---|-------------|-----|
| 1 | Asks for your Counterpart workspace folder | Prompts once, remembers forever |
| 2 | Creates `{workspace}/.counterpart/` with company agents, rules, skills | Copied from toolbox defaults |
| 3 | Creates `{workspace}/.counterpart/personal/` for your own additions | Never overwritten by updates |
| 4 | Sets `COUNTERPART_WORKSPACE` in your shell rc | Available in every session |
| 5 | Detects which AI agents you have installed | Checks for `claude`, `opencode`, `pi` |
| 6 | Persists detected providers to `config.json` | Used by sync and update |
| 7 | Checks required CLI tools and MCP servers | `jq`, `ripgrep`, `ast-grep`, Linear, Sentry, Context7 |
| 8 | Syncs rules, skills, and agents to every provider | Company + personal, native formats per agent |

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
- At least one supported AI coding agent installed (Claude Code, OpenCode, or Pi)

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
├── Makefile                   ← context-generate, context-validate, context-check
├── install.sh                 ← curl-installable bootstrap
├── VERSION                    ← current toolbox version
├── context.lock               ← SHA256 hash of context/ (auto-generated)
├── agents/                    ← default agent definitions (copied to .counterpart on setup)
├── rules/                     ← default rules (copied to .counterpart on setup)
├── skills/                    ← default skills (copied to .counterpart on setup)
├── scripts/
│   └── context-lock.sh        ← self-contained context.lock tool (copy into any repo)
├── lib/
│   ├── sync.sh                ← sync orchestrator: reads providers, delegates to lib/sync/
│   ├── sync/
│   │   ├── _common.sh         ← shared helpers (managed blocks, copy primitives)
│   │   ├── claude.sh          ← sync provider: Claude Code
│   │   ├── opencode.sh        ← sync provider: OpenCode
│   │   └── pi.sh              ← sync provider: Pi
│   ├── context-lock.sh        ← thin wrapper over scripts/context-lock.sh
│   ├── check_tools.sh         ← required CLI tools check
│   └── check_mcp.sh           ← MCP server health check
├── .github/
│   └── workflows/
│       └── context-lock.yml   ← CI: checks lock is current + not behind main
├── ci/
│   └── check-context-lock.sh  ← delegates to scripts/context-lock.sh ci-check
├── completions/
│   ├── yourcounterpart.zsh
│   └── yourcounterpart.bash
├── docs/
│   └── onboarding-ai-context.md
└── context/                   ← this repo's own knowledge layer
    ├── index.md
    └── stories/
```

---

## How It Works

### Workspace structure

Setup creates a `.counterpart/` directory inside your Counterpart workspace:

```
{workspace}/.counterpart/
├── config.json          ← providers, tools, MCPs, last_sync
├── agents/              ← company agent definitions (managed, overwritten on update)
├── rules/               ← company-wide rules (managed, overwritten on update)
├── skills/              ← company skills (managed, overwritten on update)
├── personal/            ← your personal additions (never touched by update)
│   ├── agents/          ← personal agents (synced to all providers)
│   ├── rules/           ← personal rules (appended after company rules)
│   └── skills/          ← personal skills (synced to all providers)
└── toolbox.lock         ← written after every sync
```

`COUNTERPART_WORKSPACE` is exported to your shell so every command knows where to find it.

### Commands

**`setup`** — run once. Creates `.counterpart/`, copies defaults from the toolbox, detects providers, syncs.

**`sync`** — reads `.counterpart/` (company + personal) and writes everything to every detected provider's native config format. Run this after editing anything in `.counterpart/`.

**`update`** — pulls the latest toolbox from GitHub, copies updated company agents/rules/skills into `.counterpart/`, then runs sync. Your `personal/` directory is never touched.

### Sync targets

| Agent | Rules written to | Agents written to | Skills written to |
|-------|-----------------|-------------------|-------------------|
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/agents/` | `~/.claude/skills/` |
| OpenCode | `~/.config/opencode/AGENTS.md` | `~/.config/opencode/agents/` | `~/.config/opencode/skills/` |
| Pi | `~/.pi/agent/AGENTS.md` | — (not supported) | `~/.pi/agent/skills/` |

Rules are injected as **managed blocks** between `<!-- counterpart:managed:start -->` and `<!-- counterpart:managed:end -->` markers. Content outside the markers is preserved.

### context.lock

Each repo can have a `context/` directory with project knowledge (index, summaries, stories). `context.lock` is a SHA256 hash of all files in `context/`, committed with the code.

```bash
make context-generate   # regenerate context.lock
make context-validate   # check if lock is current
make context-check      # CI check (both enforcements)
```

CI is enforced via `.github/workflows/context-lock.yml` — runs two checks on every PR:
1. Lock matches current `context/` files on the branch
2. Branch is not missing context that landed on `main` after it was created

> **Enabling enforcement**: add `check` as a required status check under Settings → Branches → main in GitHub.

See `context/stories/how-to-adopt-context-lock.md` to add this to another repo.

---

## Personal Customizations

Add your own agents, rules, and skills to `.counterpart/personal/`. They sync to all your providers alongside the company defaults and are **never overwritten** by `yourcounterpart update`.

```
{workspace}/.counterpart/personal/
├── agents/
│   └── my-agent/
│       ├── body.md        ← shared system prompt
│       ├── opencode.md    ← OpenCode frontmatter (if you use OpenCode)
│       └── claude.md      ← Claude Code frontmatter (if you use Claude Code)
├── rules/
│   └── my-conventions.md  ← injected after company rules
└── skills/
    └── my-skill/
        └── SKILL.md
```

Use the `add-user-tool` skill to scaffold the right files for your configured providers:

```
/add-user-tool agent
/add-user-tool rule
/add-user-tool skill
```

Then apply: `yourcounterpart sync`

**Collision behaviour:** personal agents and skills override company ones if they share the same name. Personal rules are appended after company rules (never replace them).

---

## Updating

```bash
yourcounterpart update
```

Pulls the latest toolbox, copies updated company agents/rules/skills into `.counterpart/`, then re-syncs to all providers. Your `personal/` directory is never touched.

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
