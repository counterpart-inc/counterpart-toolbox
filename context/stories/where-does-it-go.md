# Where Does It Go?

A decision framework for placing content in the right tier.

---

## The Three Tiers

| Tier | Location | Audience | Updated by |
|------|----------|----------|------------|
| **Toolbox** | `counterpart-toolbox` repo | All Counterpart engineers | Platform team via `yourcounterpart update` |
| **Repo** | Each project repo (`context/`) | Devs working on that codebase | Any engineer via PR |
| **User** | Local machine only, never committed | Individual developer | The developer themselves |

---

## Decision Framework

Ask these questions in order:

### 1. Does it apply to every Counterpart engineer regardless of project?
→ **Toolbox** (`rules/`, `agents/`, `skills/`)

Examples: security conventions, context-discovery rule, the company agent, the capture skill.

### 2. Does it apply only to a specific codebase?
→ **Repo** (`context/stories/`, `context/index.md`, module `.context.md`)

Examples: how to add a provider to this repo, the email notification pattern, Django migration conventions for this app.

### 3. Is it a personal preference or workflow that shouldn't affect teammates?
→ **User** (outside the managed block in `CLAUDE.md`/`AGENTS.md`, local settings files)

Examples: preferred model, personal skills, custom keybindings, UI theme.

---

## Quick Reference

| What | Where |
|------|-------|
| Company-wide engineering rule | Toolbox → `rules/` |
| Company agent definition | Toolbox → `agents/` |
| Company skill (on-demand workflow) | Toolbox → `skills/` |
| How to do X in this specific repo | Repo → `context/stories/` |
| What this module does / conventions | Repo → `{module}/.context.md` |
| Project knowledge index | Repo → `context/index.md` |
| Personal model preference | User → local config |
| Personal rule (not for teammates) | User → outside managed block |

---

## Hierarchy Enforcement

The toolbox tier is authoritative. `rules/00-hierarchy.md` is always the first rule injected into every agent's managed block. It explicitly instructs the agent to disregard any instruction outside that block that contradicts company rules.

This means:
- Repo-level rules can refine and extend — they cannot override
- User-level rules can personalise — they cannot contradict
- If there is a conflict, the toolbox rule wins, always

---

## The Key Test

> "If I push this change, should every Counterpart engineer on every project get it?"

- **Yes** → Toolbox
- **No, only devs on this project** → Repo
- **No, only me** → User
