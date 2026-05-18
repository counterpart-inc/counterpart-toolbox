# AI Context Onboarding

`yourcounterpart` distributes Counterpart's standard AI coding context — rules, skills, and MCP servers — to every developer's AI tool. You keep using your agent as-is; it already has the right context after a one-time setup.

## Install

> **Prerequisite:** your SSH key must be added to your GitHub account.

Grab the install token from Notion under **Engineering Onboarding → counterpart-toolbox install token**, then run:

```bash
curl -fsSL https://<TOKEN>@raw.githubusercontent.com/counterpart-inc/counterpart-toolbox/main/install.sh | bash
```

Or clone manually if the token doesn't work:

```bash
git clone git@github.com:counterpart-inc/counterpart-toolbox.git
cd counterpart-toolbox
bash install.sh
```

## What `yourcounterpart setup` does

1. Detects which AI agents you have installed (Claude Code, Cursor, OpenCode, Copilot, Gemini, Pi)
2. Copies company rules and skills into each agent's config
3. Configures company MCP servers (Linear, Sentry, Context7)
4. Saves your detected agents to `~/.config/counterpart/config.json`
5. Writes `~/.agents/toolbox.lock` recording what was installed and from which commit

After setup, open your AI agent directly. No wrapper, no interception.

## Keeping context current

When new company rules are published:

```bash
yourcounterpart update
```

This pulls the latest `counterpart-plugins` submodule and re-syncs all detected agents.

## context.lock is stale

If you see a warning about a stale `context.lock` in a repo:

```bash
# From inside the repo
yourcounterpart context sync
git add context.lock
git commit -m "chore: update context.lock"
```

This happens when files in `context/` are edited but `context.lock` wasn't regenerated.

## Adding a repo-specific rule

Create a `.md` file in the repo's `.agents/rules/` directory with frontmatter:

```markdown
---
name: My Rule
description: What this rule covers
alwaysApply: true
---

Your rule content here.
```

Then run `yourcounterpart update` inside the repo to sync it into your agent.

## Supported agents

| Agent | Global config | Per-repo config |
|-------|--------------|----------------|
| Claude Code | `~/.claude/CLAUDE.md` | `AGENTS.md` |
| OpenCode | `~/.config/opencode/AGENTS.md` | `AGENTS.md` |
| Cursor | `~/.cursor/rules/` | `.cursor/rules/` |
| Copilot | `~/.copilot/copilot-instructions.md` | `.github/copilot-instructions.md` |
| Gemini | `~/.gemini/GEMINI.md` | `GEMINI.md` |
| Pi | `~/.pi/AGENTS.md` | (global only) |

## FAQ

**Do I need to change my workflow?**
No. Open your AI agent as you always do. The context is already there.

**Does this track my usage or send data anywhere?**
No. Everything runs locally. The only network calls are checking for toolbox updates (reads only) and MCP server health checks.

**What if my agent isn't detected?**
Run `yourcounterpart setup` again. Detection checks for binaries (`claude`, `opencode`) and directories (`~/.cursor`, `~/.gemini`, etc.).

**How do I check what's installed?**
```bash
yourcounterpart status
```

**How do I start fresh?**
```bash
yourcounterpart reset
yourcounterpart setup
```
