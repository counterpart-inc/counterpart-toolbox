---
name: extend-context
description: Add repo-level or user-level rules, skills, or agents to extend the company AI context baseline. Triggers when a developer wants to add project-specific conventions, personal preferences, or custom skills outside the toolbox.
---

# Extend Context

Before adding anything, read `context/stories/where-does-it-go.md` in the toolbox to confirm which tier is correct. If you are not in the toolbox repo, use this guide:

---

## Repo-level extensions (rules only)

Rules and context specific to this codebase belong in `AGENTS.md` at the repo root. All agents discover this file automatically when launched in the directory.

**Add a repo rule:**
1. Create or edit `{repo}/AGENTS.md`
2. Write your rule in plain markdown — no managed block needed
3. Commit it — this is team-shared context

**What belongs here:**
- Project-specific conventions ("always run `make lint` before committing")
- Domain knowledge the agent needs about this codebase
- Workflow steps specific to this project

**What does NOT belong here:**
- Company-wide rules → those go in the toolbox (`rules/`)
- Personal preferences → those go below the managed block in your global config
- Skills → not supported at repo level (see below)

---

## User-level extensions

### Rules
Add personal rules below the managed block in your global agent config. The managed block is clearly marked — write below it, never inside it.

- Claude Code: `~/.claude/CLAUDE.md`
- OpenCode: `~/.config/opencode/AGENTS.md`
- Pi: `~/.pi/agent/AGENTS.md`

### Skills
Drop a skill directory directly into your agent's global skills path. The skill must follow the Agent Skills standard (`SKILL.md` with `name` and `description` frontmatter).

- Claude Code: `~/.claude/skills/<name>/SKILL.md`
- OpenCode: `~/.config/opencode/skills/<name>/SKILL.md`
- Pi: `~/.pi/agent/skills/<name>/SKILL.md`

### Agents
Drop an agent file into your agent's global agents path.

- Claude Code: `~/.claude/agents/<name>.md`
- OpenCode: `~/.config/opencode/agents/<name>.md`

---

## Company-wide extensions

If what you want to add should apply to **every Counterpart engineer on every project**, it belongs in the toolbox — not here. Open a PR to `counterpart-toolbox` and add it to `rules/`, `skills/`, or `agents/`. It will be distributed on the next `yourcounterpart update`.

Use the story `context/stories/where-does-it-go.md` in the toolbox to decide.
