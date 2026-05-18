# Context Hierarchy Spec

This document defines the four-layer knowledge hierarchy used by the counterpart-toolbox context engine.

## Overview

Codebase knowledge lives co-located with the code it describes. Any AI agent working in a directory should read `.context.md` files walking up to the repo root, plus `context/index.md` at the repo root. This gives agents the right context at the right granularity — without loading everything at once.

## Layers

| Layer | Owner | Location | What It Contains | Required? |
|-------|-------|----------|-----------------|-----------|
| **Company** | Engineering leadership | `~/.agents/` (toolbox) | Engineering guidelines, base skills, MCP servers | Yes |
| **Repo** | Repo maintainers | `{repo}/context/index.md` + `{repo}/.agents/` | What the repo is, how to run it, architecture, key integrations | Yes |
| **Scope/Domain** | Domain team | `{repo}/{domain}/.context.md` | What the domain does, key flows, data models, gotchas | Recommended |
| **Module** | Feature dev | `{repo}/{module}/.context.md` | Specific conventions, patterns, examples, counter-examples | As needed |

## Discovery Rules

When an AI agent starts working in a directory:

1. Read `context/index.md` at the repo root (always)
2. Walk up the directory tree from the current file, reading any `.context.md` found at each level
3. Stop at the repo root (`.git` directory)
4. Apply: deeper context overrides/extends broader context — never replaces it

Example: working in `apps/notifications/emails/welcome.py`:
- Reads `context/index.md` (repo level)
- Reads `apps/notifications/emails/.context.md` (module level, if exists)
- Reads `apps/notifications/.context.md` (scope level, if exists)
- Reads `apps/.context.md` (scope level, if exists)

## Ownership

- Any dev can write or update a `.context.md` file
- Changes are reviewed in PRs like any other code change
- No designated owner per module — communal, like the code itself
- Stale docs are surfaced by the doc-check skill at PR time

## Format Rules

- Plain markdown only — no YAML frontmatter, no agent-specific syntax
- Human-readable first: a human reviewer should be able to understand and verify it
- Concise: prefer bullet points over prose paragraphs
- Required sections must always be present; optional sections only when relevant

## Update Trigger

After creating or modifying any `.context.md` or `context/` file:

```bash
yourcounterpart context sync
```

This regenerates `context.lock` (SHA256 hash of all context files). The lock is committed with the change. CI checks that the lock is current before merge.

## Templates

| Use this template | When |
|------------------|------|
| `index.md` | Creating the repo-level `context/index.md` entry point |
| `repo.md` | Creating a repo-level `.context.md` |
| `scope.md` | Creating a scope/domain `.context.md` (e.g. `apps/notifications/.context.md`) |
| `module.md` | Creating a module `.context.md` (e.g. `apps/notifications/emails/.context.md`) |
