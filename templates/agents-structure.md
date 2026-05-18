# .agents/ Directory Structure Standard

This document defines the canonical `.agents/` directory layout used by the counterpart-toolbox sync engine. Based on the [Agentloom](https://github.com/farnoodma/agentloom) canonical format.

## Layout

```
.agents/
├── agents/               # Agent definitions
│   └── [name].md         # One file per agent
├── commands/             # Slash commands / prompts
│   └── [name].md         # One file per command
├── rules/                # Always-on instruction rules
│   └── [name].md         # One file per rule
├── skills/               # On-demand skills
│   └── [skill-name]/
│       ├── SKILL.md      # The skill instructions (required)
│       ├── references/   # Supporting docs (optional)
│       └── assets/       # Supporting files (optional)
├── mcp.json              # MCP server definitions
├── agents.lock.json      # Tracks imported sources (like package-lock)
└── .sync-manifest.json   # Tracks generated files (managed by sync engine)
```

## Scopes

- **Global** (`~/.agents/`): Company defaults installed by `yourcounterpart setup`. Applies to all repos.
- **Local** (`{repo}/.agents/`): Repo-specific extensions. Layered on top of global — additive, never overrides.

## File Schemas

### Agent (`agents/[name].md`)

```markdown
---
name: agent-name
description: One sentence describing what this agent does.
claude:
  model: claude-sonnet-4-5        # Claude-specific override (optional)
cursor:
  model: claude-sonnet-4-5        # Cursor-specific override (optional)
codex:
  model: gpt-4o                   # Codex-specific override (optional)
opencode: {}                      # Empty = use defaults
gemini: false                     # false = disabled for this provider
---

You are a [role description].

[Agent system prompt body. Plain markdown. Applies to all providers unless overridden.]
```

**Rules:**
- `name` is required, must be kebab-case
- `description` is required
- Provider blocks are optional — omit for default behavior, `false` to disable
- Body is plain markdown, agent-agnostic

### Rule (`rules/[name].md`)

```markdown
---
name: Always run tests before committing
description: Require test passage before finishing any code change
globs:
  - "**/*.py"
  - "**/*.ts"
alwaysApply: true
---

Before finishing any change, run the test suite for the affected module and confirm it passes.

Include the test output summary in your response.
```

**Rules:**
- `name` is required (human-readable string, shown in managed blocks)
- `alwaysApply: true` → injected into all agent sessions
- `alwaysApply: false` → injected only when working on files matching `globs`
- `globs` is optional — only used when `alwaysApply: false`
- Body is plain markdown

### Skill (`skills/[name]/SKILL.md`)

```markdown
# Skill: [Name]

**Trigger**: When to invoke this skill (describe the situation, not the command).

**Description**: One sentence summary.

## Steps

1. [Step 1]
2. [Step 2]
3. [Step 3]

## Output

What the skill produces when complete.

## References

- See `references/[file]` for [supporting documentation]
```

**Rules:**
- `SKILL.md` is required; `references/` and `assets/` are optional
- Skills are invoked on-demand, not injected automatically
- Plain markdown only

### MCP Config (`mcp.json`)

```json
{
  "version": 1,
  "mcpServers": {
    "server-name": {
      "base": {
        "command": "npx",
        "args": ["package-name"]
      },
      "providers": {
        "codex": {
          "args": ["package-name", "--codex-flag"]
        },
        "gemini": false
      }
    },
    "remote-server": {
      "base": {
        "url": "https://mcp.example.com/sse"
      }
    }
  }
}
```

**Rules:**
- `base` defines the default config for all providers
- `providers.[name]` overrides specific keys for that provider
- `providers.[name]: false` disables the server for that provider

### Lock File (`agents.lock.json`)

```json
{
  "version": 1,
  "sources": {
    "counterpart-inc/counterpart-plugins": {
      "commit": "abc123def456",
      "importedAt": "2026-05-18T12:00:00Z",
      "agents": ["default"],
      "rules": ["code-quality", "security"],
      "skills": ["capture", "doc-check"]
    }
  }
}
```

## Sync Behaviour

The sync engine (`yourcounterpart setup/update`) reads from `.agents/` and writes to each detected agent's native format:

| Provider | Global output | Local (per-repo) output |
|----------|--------------|------------------------|
| Claude Code | `~/.claude/CLAUDE.md` (managed block) | `AGENTS.md` in repo |
| Cursor | `~/.cursor/rules/` | `.cursor/rules/` in repo |
| OpenCode | `~/.config/opencode/AGENTS.md` | `AGENTS.md` in repo |
| Copilot | `~/.copilot/copilot-instructions.md` | `.github/copilot-instructions.md` |
| Pi | `~/.pi/` | n/a |
| Gemini | `~/.gemini/GEMINI.md` | `GEMINI.md` in repo |

**Managed blocks**: The sync engine injects rules between marker comments. Hand-written content outside the markers is preserved.

```
<!-- counterpart:managed:start -->
[company rules injected here]
<!-- counterpart:managed:end -->
```
