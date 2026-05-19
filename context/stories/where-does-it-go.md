# Where Does It Go?

A decision framework for placing content in the right tier.

---

## The Three Tiers

| Tier | Location | Audience | Updated by |
|------|----------|----------|------------|
| **Toolbox** | `counterpart-toolbox` repo | All Counterpart engineers | Platform team via `yourcounterpart update` |
| **Repo** | Each project repo (`context/`) | Devs working on that codebase | Any engineer via PR |
| **Personal** | `{workspace}/.counterpart/personal/` | Individual developer | The developer themselves via `yourcounterpart sync` |

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
→ **Personal** (`.counterpart/personal/agents/`, `rules/`, or `skills/`) — synced to all your providers via `yourcounterpart sync`

Examples: a Django specialist agent, your own coding conventions, a personal skill for a workflow only you use.

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
| Repo-specific rule or convention | Repo → `AGENTS.md` at repo root |
| Personal agent | Personal → `.counterpart/personal/agents/` → use `add-user-tool` skill |
| Personal rule (not for teammates) | Personal → `.counterpart/personal/rules/` → use `add-user-tool` skill |
| Personal skill | Personal → `.counterpart/personal/skills/` → use `add-user-tool` skill |

> **Note:** Skills and agents are not supported at the repo level — no single path is natively discovered by all providers. Use the toolbox for company-wide content, or `.counterpart/personal/` for personal content — both sync to all your providers via `yourcounterpart sync`.

---

## Rules vs Stories — The Context Window Tax

Every rule in the managed block is injected into **every session, every message, across every repo**. It permanently occupies context window space, whether relevant or not.

Stories are free until read. They only cost tokens when the agent actually loads them — triggered by `context/index.md` discovery.

This means the bar for adding a rule is high:

| Add as a rule if... | Add as a story if... |
|---------------------|----------------------|
| Must be enforced on every single message | Only relevant in specific situations |
| Non-negotiable company baseline | Guidance, how-tos, conventions |
| Short — a sentence or two | Can be as long as needed |
| Applies to all repos, all users, always | Applies when doing a specific task |

When in doubt, make it a story.

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
