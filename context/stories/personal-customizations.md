# Personal Customizations

Users can add their own agents, rules, and skills to `.counterpart/personal/`. These are synced to all providers alongside company content and are **never overwritten** by `yourcounterpart update`.

---

## Directory layout

```
{workspace}/.counterpart/personal/
├── agents/            ← same directory format as toolbox agents/
│   └── my-agent/
│       ├── body.md        ← shared system prompt
│       ├── opencode.md    ← OpenCode frontmatter
│       └── claude.md      ← Claude Code frontmatter
├── rules/             ← .md files with name frontmatter, appended after company rules
└── skills/            ← skill dirs (name/SKILL.md), copied to provider skill dirs
```

---

## How sync works

`sync_global` passes both `agents_dir` and `agents_dir/personal` to each provider script. Provider scripts apply the company layer first, then the personal layer on top:

- **Agents/skills**: personal files are copied after company files — same filename wins (personal overrides company)
- **Rules**: combined via `_sync_rules_combined` which concatenates both dirs before writing a single managed block — personal rules appear after company rules

---

## Adding personal content

Use the `add-user-tool` skill:

```
/add-user-tool agent    ← create a personal agent
/add-user-tool rule     ← create a personal rule
/add-user-tool skill    ← create a personal skill
```

Then sync: `yourcounterpart sync`

---

## What goes in personal vs toolbox

| Content | Goes in |
|---------|---------|
| Applies to every Counterpart engineer | Toolbox (`agents/`, `rules/`, `skills/`) |
| Applies only to you | `.counterpart/personal/` |
| Applies only to one repo | That repo's `AGENTS.md` or `.opencode/agents/` |

See `context/stories/where-does-it-go.md` for the full decision framework.
-- test --
