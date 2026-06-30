---
title: "How the Counterpart Toolbox Works"
scope:
  "How the counterpart CLI distributes AI assets (skills, agents, commands, hooks, MCP servers) from counterpart-plugins
  to local AI providers on an engineer's machine. Does not cover how counterpart-plugins generates its output, or how
  individual skills/agents are authored."
status: draft
last_updated: 2026-06-30
contributors:
  - name: "Artur Gomes"
    role: "Engineer"
tags: [toolbox, cli, bash, ai-context, sync, counterpart-plugins, opencode, claude]
---

## Note for AI Agents Consuming This Document

This document is a **starting point, not an exhaustive reference.** It tells the story of how the toolbox works based on
code scanning at the time of writing. Check the `scope` field above to see what's explicitly NOT covered.

How to use this document:

1. Read it first to orient yourself — understand the architecture, terminology, key files, and gotchas.
2. Check **Related Context** at the bottom of **Beyond This Story**.
3. Search for your task's concepts in the codebase, not just the doc's concepts.
4. Explore directories near the Key Files — adjacent modules often exist that this story doesn't cover.
5. Treat it as high-confidence context, not ground truth. Verify claims against current code when precision matters.

---

## Overview

`counterpart-toolbox` is the distribution mechanism for Counterpart's company-wide AI context — a CLI tool that keeps
every engineer's local AI providers in sync with a central repository of skills, agents, commands, hooks, and MCP server
configs. The mental model is simple: `counterpart-plugins` is the source of truth; this toolbox is the delivery
mechanism.

The audience is Counterpart engineers. When onboarding or pulling updates, they run `counterpart sync`, which fetches
pre-built assets from the `counterpart-plugins@generated` branch and distributes them into the right directories for
each AI provider they use (Claude Code, OpenCode, Pi, Cursor). The toolbox never generates anything — it only
distributes what the plugins repo's CI has already built.

The toolbox is written in bash and explicitly targets bash 3.2 for macOS compatibility. It has no runtime dependencies
beyond `git` and `jq` (jq only required for MCP and hooks merges). This is a deliberate design choice — engineers should
be able to install and run it with nothing more than what ships on a stock Mac.

---

## The Story

### Installation

An engineer installs the toolbox once via curl-pipe-bash:

```bash
curl -fsSL https://raw.githubusercontent.com/counterpart-inc/counterpart-toolbox/main/install.sh | bash
```

[`install.sh`](../../install.sh) does three things:

1. Clones `counterpart-toolbox` to `~/.local/share/counterpart-toolbox`
2. Symlinks the `counterpart` binary into `~/.local/bin/`
3. Injects a shell hook into `~/.zshrc` (and `~/.bashrc`) between `# >>> counterpart-toolbox` /
   `# <<< counterpart-toolbox` markers

The shell hook does two things on every terminal open: exports `~/.local/bin` to PATH (so `counterpart` is available),
and calls `_ct_update_check` — a background function that silently checks for updates and prompts if the plugins have
changed since the last sync.

For local development, `make install` symlinks the current working directory's `counterpart` binary directly, so changes
to lib scripts are immediately reflected without reinstalling.

### The Data Flow

```
counterpart-plugins (main branch)
        ↓ CI on push
counterpart-plugins (generated branch)
        ↓ counterpart sync
~/.config/counterpart/cache/  (local git mirror)
        ↓ per-provider sync functions
~/.claude/   ~/.config/opencode/   ~/.pi/agent/   ~/.cursor/
```

The generated branch contains pre-built, provider-specific output. Engineers never need the plugins repo or any build
tools — the toolbox only needs `git` to pull the generated branch.

### First Sync and Configuration

On the first `counterpart sync`, if no `~/.config/counterpart/sync.json` exists, the CLI automatically runs the
interactive configure flow. This detects which providers are installed on the machine by checking whether their config
directories exist (e.g., `~/.claude` for Claude Code, `~/.config/opencode` for OpenCode). For each detected provider,
the engineer chooses which asset types to sync.

Preferences are stored in `~/.config/counterpart/sync.json` as a simple JSON object:

```json
{ "providers": { "claude": ["skills", "agents", "mcp"], "opencode": ["skills", "mcp"] } }
```

The configure flow can be re-run at any time with `counterpart configure`.

### Fetching the Plugins Source

`fetch_plugins_source()` in [`lib/plugins-source.sh`](../../lib/plugins-source.sh) manages a local git mirror of
`counterpart-plugins@generated` at `~/.config/counterpart/cache/`. On first sync it does a shallow clone (`--depth 1`);
on subsequent syncs it fetches and hard-resets to `origin/generated`. This means the cache is always a clean checkout —
no merge conflicts, no drift.

The `--source <dir>` flag bypasses the remote fetch entirely, using a local directory instead. This is the primary
development workflow: run `make generate-clean` in `counterpart-plugins`, then
`counterpart sync --source ../counterpart-plugins/generated` to test the full pipeline locally.

### Lock File and Change Detection

The generated branch contains a `counterpart-ai.lock` file listing SHA256 hashes for every distributed file, plus an
aggregate hash of the whole set. This file is the change-detection mechanism.

After each sync, the toolbox copies the generated lock to `~/.config/counterpart/counterpart-ai.lock`. At the start of
the next sync, it compares the aggregate hash from the local lock against the aggregate hash from the newly-fetched
generated branch. If they match, sync exits early with "Already up to date." If they differ, sync proceeds and the
old→new hash is printed for visibility.

The lock also drives stale file cleanup. `lock_prune_stale()` in [`lib/lock.sh`](../../lib/lock.sh) computes the set
difference between the old and new lock — files present in the old lock but absent from the new one. These are files
that were removed from the plugins repo. The toolbox deletes them from the engineer's local provider directories
automatically. This means adding a new skill doesn't require any cleanup step; removing a skill from the plugins repo
propagates to all engineers on their next sync.

### Per-Provider Sync

Once the source is ready and locks differ, the toolbox iterates over the engineer's configured providers and calls
`sync_provider_<name>()` for each. These functions live in `lib/sync/`:

- **Skills, agents, commands, output-styles**: Copied per-file from the lock manifest using `copy_lock_assets()` in
  [`lib/lock.sh`](../../lib/lock.sh). Only files explicitly listed in `counterpart-ai.lock` are written — user files
  with unique names in the same directories are never touched. The generated branch has provider-specific subdirectories
  (e.g., `generated/claude/skills/`, `generated/opencode/skills/`) that mirror the lock paths.

- **MCP servers**: Not a simple copy. The toolbox merges using a `counterpart-*` namespace convention — it only touches
  keys prefixed `counterpart-` in the target config, leaving the engineer's own entries alone. `_merge_mcp_claude()` in
  [`lib/sync/claude.sh`](../../lib/sync/claude.sh) merges into `~/.claude.json` under `.mcpServers` (user scope —
  available across all projects); `merge_mcp_opencode()` in [`lib/json-merger.sh`](../../lib/json-merger.sh) handles
  `~/.config/opencode/opencode.json` (merged under `.mcp`).

- **Global rules** (Claude + OpenCode): Content from `generated/<provider>/AGENTS.md` is injected into
  `~/.claude/CLAUDE.md` or `~/.config/opencode/AGENTS.md` via `upsert_managed_section()`. See the Managed Section
  Merging section above for the full picture.

- **Hooks** (Claude only): Merged into `~/.claude/settings.json` (user-level, global). The toolbox tracks which hooks it
  owns in `~/.config/counterpart/last-claude-hooks.json`. On each sync, previously-synced counterpart hooks are removed
  and the current set is added — so removed hooks are cleaned up automatically. User's own hooks are never in the
  tracked set and are never touched. [`lib/json-merger.sh`](../../lib/json-merger.sh) handles this with a `jq` pipeline.

- **Pi and Cursor**: Currently only support skills. Pi's generated output lives at the cache root (not under a `pi/`
  subdirectory) — the main CLI explicitly sets `source_dir` to the cache root for Pi, which `lib/sync/pi.sh` then reads
  as `${source}/agent/skills/`. Skills land at `~/.pi/agent/skills/`. Pi can also read skills from `~/.agents/skills/`,
  but the toolbox only syncs to the former — one location is sufficient.

### Managed Section Merging (Global Rules)

[`lib/section-merger.sh`](../../lib/section-merger.sh) provides `upsert_managed_section()` — a function that injects
content into a `<!-- counterpart:managed:start --> ... <!-- counterpart:managed:end -->` block in a file. On first run
it prepends the managed block; on subsequent runs it replaces only the content inside the markers. User content outside
the markers is never touched.

This is how **global rules** are distributed. The `counterpart-plugins` repo has a `rules/` directory; its CI pipeline
concatenates all `.md` files in it and emits the result to `generated/claude/AGENTS.md` and
`generated/opencode/AGENTS.md`. The toolbox picks these up via the `global-rules` asset type:

- **Claude**: content is injected into `~/.claude/CLAUDE.md` via `upsert_managed_section`
- **OpenCode**: content is injected into `~/.config/opencode/AGENTS.md` via `upsert_managed_section`
- **Cursor**: the generator emits `generated/cursor/rules/counterpart.mdc` (with `alwaysApply: true` frontmatter); this
  file is synced normally by the existing cursor rules copy — no managed block needed

The managed block approach means engineers can add their own content to `CLAUDE.md` or `AGENTS.md` freely — the sync
only ever updates the block between the markers and leaves everything else alone.

### Background Update Check

[`lib/update-check.sh`](../../lib/update-check.sh) provides `_ct_update_check()`, which is sourced into the engineer's
shell via the zshrc hook. It's throttled — by default once every 7 days via a `~/.config/counterpart/.last-check`
timestamp file. When it runs, it does a background `git fetch` of the generated branch and compares the remote HEAD to
the local cache HEAD. If they differ, it prints a one-line prompt suggesting `counterpart sync`.

The check runs in a subshell (`(...) &`) so it never blocks terminal startup, even if the network is slow or
unavailable. The throttle interval is overridable via `COUNTERPART_CHECK_INTERVAL` environment variable.

---

## Key Files

| Path                                                   | Role                                                                                 |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------ |
| [`counterpart`](../../counterpart)                     | Main CLI entry point — routing and top-level orchestration                           |
| [`install.sh`](../../install.sh)                       | One-time installer — clones toolbox, symlinks binary, injects shell hook             |
| [`Makefile`](../../Makefile)                           | Dev shortcuts for install, uninstall, sync, configure                                |
| [`lib/providers.sh`](../../lib/providers.sh)           | Provider detection, asset support matrix, display labels                             |
| [`lib/plugins-source.sh`](../../lib/plugins-source.sh) | Fetch/cache management for counterpart-plugins@generated                             |
| [`lib/lock.sh`](../../lib/lock.sh)                     | Lock file parsing, hash comparison, stale file pruning                               |
| [`lib/section-merger.sh`](../../lib/section-merger.sh) | Managed-block injection for AGENTS.md / CLAUDE.md                                    |
| [`lib/json-merger.sh`](../../lib/json-merger.sh)       | Namespace-based JSON merge for MCP configs and Claude hooks                          |
| [`lib/update-check.sh`](../../lib/update-check.sh)     | Background update check, throttled to once per 7 days                                |
| [`lib/sync/claude.sh`](../../lib/sync/claude.sh)       | Claude Code sync — skills, agents, commands, hooks, MCP                              |
| [`lib/sync/opencode.sh`](../../lib/sync/opencode.sh)   | OpenCode sync — skills, agents, commands, MCP                                        |
| [`lib/sync/pi.sh`](../../lib/sync/pi.sh)               | Pi sync — skills only                                                                |
| [`lib/sync/cursor.sh`](../../lib/sync/cursor.sh)       | Cursor sync — skills (flattened to `.mdc` rules)                                     |
| `~/.config/counterpart/`                               | All runtime state — prefs, lock, cache, last-check timestamp, last-claude-hooks.json |

---

## Integrations & Dependencies

**counterpart-plugins (generated branch)** — The source of truth. The toolbox is entirely downstream of this repo. The
generated branch is built by CI on every push to main. The toolbox has no knowledge of how the output is generated; it
just consumes the directory structure.

**git** — Required for cloning and fetching the plugins cache. The toolbox shells out to `git` directly. SSH access to
`github.com:counterpart-inc/counterpart-plugins` is required for remote sync.

**jq** — Required only for MCP and hooks merges. If `jq` is not installed, those asset types silently skip with an error
message. Skills, agents, commands, and output-styles work without it.

---

## Gotchas & Known Failure Modes

**SSH key required for remote sync**

- **What happens:** `counterpart sync` fails with a git auth error.
- **Why:** The plugins repo is cloned via SSH (`git@github.com:...`). Engineers without SSH keys configured for GitHub
  will get an error.
- **What to do:** Set up SSH keys for GitHub, or use `--source` to sync from a local directory.

**Migrating from old project-level Claude MCP**

- **What happens:** Previous versions of the toolbox wrote `counterpart-*` MCP servers to `${PWD}/.mcp.json`
  (project-scoped). The toolbox now correctly writes them to `~/.claude.json` (user scope, available across all
  projects) and hooks to `~/.claude/settings.json`.
- **Why:** Claude Code supports three MCP scopes. User scope (`~/.claude.json`) is the right target for company-wide
  tools — they should be available everywhere, not only in the directory where `counterpart sync` was run.
- **What to do:** If you have leftover `counterpart-*` entries in any project's `.mcp.json`, remove them manually — the
  toolbox no longer maintains that file. The user-level entries in `~/.claude.json` are the source of truth now.

**Personal files in provider directories are safe — with one exception (Pi)**

- **What happens:** Sync copies only files listed in `counterpart-ai.lock`. User-added files with unique names anywhere
  in the provider's skills/agents/commands folders are never touched. Name collisions with a company-owned file are
  still overwritten — the lock entry wins.
- **Why:** `copy_lock_assets()` iterates the lock manifest and copies individual files rather than doing `cp -r`. Only
  paths the toolbox explicitly owns are written.
- **Exception — Pi**: Pi's sync still uses `cp -r` because its source directory layout (`agent/skills/` at the cache
  root) doesn't cleanly map to lock paths without confirming real Pi lock entries. Pi users should avoid putting
  personal files in `~/.pi/agent/skills/` until this is resolved.
- **No documented convention yet**: there is no official guidance on where engineers should put personal skills
  alongside company ones. This documentation should exist and explicitly list every path the toolbox may write to.

**Bash 3.2 compatibility**

- **What happens:** Scripts that use `declare -A` (bash associative arrays) or `[[ ]] && cmd` patterns with `set -e`
  will fail on stock macOS bash (which ships as 3.2).
- **Why:** macOS hasn't updated the system bash since 3.2 due to GPLv3 licensing. The toolbox explicitly targets 3.2 for
  maximum compatibility.
- **What to do:** When adding to lib scripts, avoid `declare -A`, `bash 4+` features, and `[[...]] && cmd` patterns
  under `set -e`. Use loops for provider lookups instead of associative arrays.

**`counterpart update` re-syncs even if already current**

- **What happens:** `counterpart update` always runs `counterpart sync` after pulling the toolbox itself, even if
  plugins haven't changed.
- **Why:** The toolbox update (pulling `counterpart-toolbox@main`) is separate from the plugins update (pulling
  `counterpart-plugins@generated`). After pulling the toolbox, a re-sync is forced to ensure consistency.
- **What to do:** This is by design. It's slightly wasteful but harmless.

---

## Testing & Verification

The primary test path is the local source flag:

```bash
# In counterpart-plugins
make generate-clean

# In counterpart-toolbox
counterpart sync --source ../counterpart-plugins/generated
```

This exercises the full sync pipeline (lock comparison, pruning, per-provider copy, MCP merge) without touching the
remote.

`make install` puts the toolbox in dev mode — the `counterpart` binary symlinks directly to the working directory, so
edits to `lib/` scripts are live immediately.

For MCP and hooks merges specifically, verify by inspecting the target config file after sync and confirming only
`counterpart-*` keys were touched.

There are no automated tests. All verification is manual via the `--source` local workflow above.

---

## Beyond This Story

**counterpart-plugins** — The upstream monorepo that produces the `generated` branch this toolbox consumes. Contains
skill authoring, the CI pipeline that runs the generator, and the source-of-truth for what gets distributed.
Understanding the generator's output format (directory structure, lock format) is necessary to extend the toolbox with
new asset types.

**Global rules source in counterpart-plugins** — The `rules/` directory in `counterpart-plugins` is the source of truth
for global AI rules. Adding a new `.md` file there triggers CI, which concatenates all rules and emits the output to the
`generated` branch. The toolbox picks it up on the next `counterpart sync`. See the "Managed Section Merging" section of
The Story for the full distribution picture.

**Pi support** — Pi currently only receives skills. Pi as a platform is more "do it yourself" and natively supports
fewer features than Claude or OpenCode, so asset expansion is gated by what Pi itself supports. The toolbox is written
to be easy to extend — adding new asset types for Pi is straightforward once Pi supports them.

**Cursor support** — Cursor only receives skills, emitted as `.mdc` rule files into `~/.cursor/rules/`. The flattening
from skill format to `.mdc` is done by the **generator** in `counterpart-plugins` — `lib/sync/cursor.sh` just copies the
pre-built `.mdc` files wholesale. Same `cp -r` design gap applies here as with skills (see Gotchas).

**Extending the toolbox** — Adding new providers or asset types follows a clear pattern across a small set of files. See
[story-toolbox-extending.md](story-toolbox-extending.md) for the full walkthrough.

**Related context:**

- No related context stories exist in this repo yet.
