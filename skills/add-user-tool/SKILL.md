---
name: add-user-tool
description: Add a personal agent, rule, or skill to your .counterpart/personal/ directory so it syncs to all your AI providers. Pass the type you want to add — agent, rule, or skill. Triggers on: "add personal agent", "add my rule", "create my skill", "add user tool".
---

# Add User Tool

Add a personal tool to `.counterpart/personal/` so `yourcounterpart sync` distributes it to all your AI providers alongside the company defaults.

## Before you start

1. Confirm `COUNTERPART_WORKSPACE` is set: `echo $COUNTERPART_WORKSPACE`
2. The personal directory lives at `$COUNTERPART_WORKSPACE/.counterpart/personal/`
3. Personal content is **never overwritten** by `yourcounterpart update` — it's yours

---

## Adding an agent

Personal agents use the same directory format as the toolbox: one dir per agent with provider-specific frontmatter and a shared body.

**First, read the user's configured providers:**
```bash
jq -r '.providers[]' $COUNTERPART_WORKSPACE/.counterpart/config.json
```

Create one `{provider}.md` file **per configured provider** — skip providers not in that list.

```
$COUNTERPART_WORKSPACE/.counterpart/personal/agents/<name>/
├── body.md          ← shared system prompt (plain markdown, no frontmatter)
├── opencode.md      ← only if "opencode" is in providers
└── claude.md        ← only if "claude" is in providers
```

**`opencode.md`:**
```yaml
---
description: What this agent does and when to use it.
mode: all
---
```

**`claude.md`:**
```yaml
---
name: <name>
description: What this agent does and when to use it.
---
```

**`body.md`** — plain markdown, no frontmatter:
```markdown
You are a specialist in X. Focus on Y.
Always do Z.
```

- `mode: all` — available via Tab (primary) and @ mention (subagent)
- `mode: subagent` — @ mention only
- `mode: primary` — Tab only (avoid, hides agent from @ menu)

If a provider file is missing for an agent, that agent is skipped for that provider.

---

## Adding a rule

Personal rules are injected into the managed block in your provider's rules file, **after** company rules.

Create `$COUNTERPART_WORKSPACE/.counterpart/personal/rules/<name>.md`:

```yaml
---
name: my-conventions
---

Always do X when working in this codebase.
Prefer Y over Z.
```

The `name` field is required — it becomes the section heading in the injected rules.

---

## Adding a skill

Personal skills sync to every provider's skills directory.

Create `$COUNTERPART_WORKSPACE/.counterpart/personal/skills/<name>/SKILL.md`:

```yaml
---
name: <name>
description: What this skill does and when to invoke it. Used by the agent to decide when to load it.
---

# Skill instructions here

Step-by-step guidance the agent follows when this skill is loaded.
```

---

## Apply to all providers

After creating your file, run:

```bash
yourcounterpart sync
```

---

## Notes

- Personal agents override company agents if they share the same filename
- Personal rules are appended after company rules (not replacing them)
- Personal skills override company skills if they share the same directory name
