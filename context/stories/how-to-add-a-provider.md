# How to Add a New Sync Provider

A **provider** is an AI coding agent (Claude Code, OpenCode, Pi, etc.) that `yourcounterpart sync` pushes company context into.

Adding a provider means:
1. Creating `lib/sync/{provider}.sh`
2. Adding detection logic in `yourcounterpart` setup
3. That's it — `sync_global` discovers and calls it automatically

---

## Step 1 — Create `lib/sync/{provider}.sh`

Each provider script owns exactly one thing: where its config files live.

Create `lib/sync/cursor.sh` (replace `cursor` with the actual provider name):

```bash
#!/usr/bin/env bash
# lib/sync/cursor.sh — sync provider: Cursor

# shellcheck source=lib/sync/_common.sh
source "${TOOLBOX_DIR}/lib/sync/_common.sh"

sync_cursor() {
  local agents_dir="$1"
  _sync_rules  "$agents_dir" "${HOME}/.cursor/rules/counterpart.md"
  _sync_agents "$agents_dir" "${HOME}/.cursor/agents" "cursor"
  _sync_skills "$agents_dir" "${HOME}/.cursor/skills"
  echo "  [✓] cursor"
}
```

### Rules of the contract

- **File name** must be `lib/sync/{provider}.sh` — this is how `sync_global` finds it
- **Function name** must be `sync_{provider}` — this is how `sync_global` calls it
- **Single argument**: `agents_dir` — the `.counterpart/` path with `agents/`, `rules/`, `skills/` subdirs
- Use `_sync_rules`, `_sync_agents`, `_sync_skills` from `_common.sh` for the actual work
- Pass your provider name as the third arg to `_sync_agents` (see agent directory format below)
- Omit primitives the provider doesn't support (e.g., Pi has no agents)
- Print `[✓] {provider}` on success

### Available primitives (`_common.sh`)

| Function | What it does |
|----------|-------------|
| `_sync_rules <agents_dir> <target_file>` | Injects combined rules into the managed block of target_file |
| `_sync_agents <agents_dir> <target_dir> <provider>` | Composes and copies agents to target_dir (see below) |
| `_sync_skills <agents_dir> <target_dir>` | Copies `skills/*/SKILL.md` (+ `references/`) to target_dir |

---

## Agent directory format

Agents support a directory structure that lets each provider have its own frontmatter while sharing the prompt body:

```
agents/
└── my-agent/
    ├── body.md        ← shared prompt body (written once, used by all providers)
    ├── claude.md      ← Claude Code frontmatter
    ├── opencode.md    ← OpenCode frontmatter
    └── cursor.md      ← Cursor frontmatter  (add when supporting Cursor)
```

`_sync_agents` composes `{provider}.md` + `body.md` into a single file and writes it to the target directory. If the provider file doesn't exist for an agent, that agent is skipped for that provider.

**`claude.md`** example:
```yaml
---
name: my-agent
description: What this agent does and when to invoke it.
---
```

**`opencode.md`** example:
```yaml
---
description: What this agent does and when to invoke it.
mode: subagent
---
```

**`body.md`** — plain markdown, no frontmatter:
```markdown
You are a specialist in X. Focus on Y.
Always do Z.
```

When adding a new provider, add `{provider}.md` to every existing agent directory that should be available in that provider.

---

## Step 2 — Add detection in `yourcounterpart` setup

In `run_setup()`, find the provider detection block and add your provider:

```bash
# 5. Detect providers
local detected_providers=()
if command -v claude &>/dev/null;   then detected_providers+=("claude");   echo "  [✓] Claude Code"; fi
if command -v opencode &>/dev/null; then detected_providers+=("opencode"); echo "  [✓] OpenCode"; fi
if [[ -d "${HOME}/.pi" ]];          then detected_providers+=("pi");       echo "  [✓] Pi"; fi
if command -v cursor &>/dev/null;   then detected_providers+=("cursor");   echo "  [✓] Cursor"; fi   # ← add here
```

Detection strategies:
- `command -v {binary}` — for providers installed as a CLI binary
- `[[ -d "${HOME}/.{provider}" ]]` — for providers that create a home directory
- `[[ -f "${HOME}/Library/Application Support/{provider}/..." ]]` — for macOS app paths

---

## How `sync_global` picks it up

`_do_sync` in `yourcounterpart` reads the `providers` array from `config.json` and calls:

```bash
sync_global "$cp_dir" "${providers[@]}"
```

`sync_global` loops over each provider, sources `lib/sync/${provider}.sh`, and calls `sync_${provider}`. If the file doesn't exist it prints a warning and skips — no crash, no side effects on other providers.

---

## Checklist

- [ ] `lib/sync/{provider}.sh` created
- [ ] Function named `sync_{provider}`
- [ ] `_sync_agents` called with provider name as third arg
- [ ] `{provider}.md` frontmatter added to every agent directory in `agents/`
- [ ] Detection added to `run_setup()` in `yourcounterpart`
- [ ] `README.md` sync targets table updated
- [ ] `context.lock` regenerated: `yourcounterpart context sync`
