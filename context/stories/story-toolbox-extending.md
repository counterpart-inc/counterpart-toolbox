---
title: "How to Extend the Counterpart Toolbox"
scope:
  "How to add a new AI provider or a new asset type to the counterpart-toolbox sync pipeline. Does not cover how to
  author the assets themselves (that lives in counterpart-plugins) or how to modify the lock format."
status: draft
last_updated: 2026-06-30
contributors:
  - name: "Artur Gomes"
    role: "Engineer"
tags: [toolbox, cli, bash, extensibility, providers, assets]
---

## Note for AI Agents Consuming This Document

This document is a **starting point, not an exhaustive reference.** Read [story-toolbox.md](story-toolbox.md) first — it
explains the overall architecture that this story builds on.

---

## Overview

The toolbox is explicitly designed to be easy to extend. Adding a new AI provider or a new asset type touches a small,
predictable set of files — there is no hidden wiring. The pattern is consistent across all existing providers and
assets, so reading any existing implementation (e.g., `lib/sync/pi.sh` for a minimal provider, `lib/sync/claude.sh` for
a full one) gives you the template.

---

## The Story

### How the Extension Points Fit Together

The toolbox has two orthogonal dimensions of configuration:

- **Providers** — the AI tools engineers run (Claude Code, OpenCode, Pi, Cursor). Each provider has a sync function and
  a directory where its assets land.
- **Assets** — the types of content distributed (skills, agents, commands, hooks, MCP servers, output-styles,
  global-rules). Each asset type may or may not be supported by each provider.

The support matrix lives in one place: `lib/providers.sh`. Everything else — detection, UI labels, descriptions — hangs
off of it. Adding a new provider or asset type means extending this matrix and then wiring up the sync logic.

### Adding a New Provider

**Step 1 — Register the provider in `lib/providers.sh`**

Add the provider name to `ALL_PROVIDERS` (controls display order) and set its config path:

```bash
PROVIDER_PATH_NEWPROVIDER="${HOME}/.newprovider"
ALL_PROVIDERS=(claude opencode pi cursor newprovider)
```

Add cases to `provider_supports()` for each asset type the provider supports:

```bash
newprovider:skills) return 0 ;;
```

Add a human label to `provider_label()`:

```bash
newprovider) echo "New Provider" ;;
```

Add asset descriptions to `asset_description()` for each supported asset — these appear in the interactive configure UI:

```bash
skills)
  case "$provider" in
    newprovider) echo "Skills for New Provider → ~/.newprovider/skills/" ;;
  esac ;;
```

**Step 2 — Create `lib/sync/newprovider.sh`**

Write a `sync_provider_newprovider()` function that handles each supported asset:

```bash
#!/usr/bin/env bash
# lib/sync/newprovider.sh — sync assets to New Provider

sync_provider_newprovider() {
  local source="$1"   # path to generated/newprovider/
  local assets=("${@:2}")
  local target="${HOME}/.newprovider"

  for asset in "${assets[@]}"; do
    case "$asset" in
      skills)
        mkdir -p "${target}/skills"
        cp -r "${source}/skills/." "${target}/skills/"
        echo "  [✓] newprovider/skills → ${target}/skills/"
        ;;
    esac
  done
}
```

**Step 3 — Source the new script in `counterpart`**

Add it to the lib loading block near the top of the `counterpart` binary:

```bash
source "${TOOLBOX_DIR}/lib/sync/newprovider.sh"
```

**Step 4 — Add the provider→target mapping in `run_sync()`**

In `counterpart`, `lock_prune_stale` is called with a list of `provider:target_dir` pairs. Add the new provider:

```bash
lock_prune_stale "$old_lock" "$new_lock" \
  "claude:${HOME}/.claude" \
  "opencode:${HOME}/.config/opencode" \
  "pi:${HOME}/.pi/agent" \
  "cursor:${HOME}/.cursor" \
  "newprovider:${HOME}/.newprovider"
```

**Step 5 — Verify**

Run `counterpart configure` — the new provider should appear in the detected list (if its config dir exists) and offer
the supported asset toggles. Then `counterpart sync --source <local-generated-dir>` to exercise the sync path.

---

### Adding a New Asset Type

**Step 1 — Register the asset in `lib/providers.sh`**

Add to `ALL_ASSETS` (controls display order in the configure UI):

```bash
ALL_ASSETS=(skills agents commands hooks output-styles mcp newasset)
```

Add `provider_supports()` cases for each provider that supports it:

```bash
claude:newasset)   return 0 ;;
opencode:newasset) return 0 ;;
```

Add an `asset_description()` case for each supporting provider:

```bash
newasset)
  case "$provider" in
    claude)   echo "Description of new asset for Claude → ~/.claude/newasset/" ;;
    opencode) echo "Description of new asset for OpenCode → ~/.config/opencode/newasset/" ;;
  esac ;;
```

**Step 2 — Add a `case` branch in each supporting `sync_provider_*` function**

There are two patterns depending on whether the asset writes new files or injects into an existing file.

**Pattern A — file copy** (skills, agents, commands, output-styles): use `copy_lock_assets` so only lock-tracked files
are written and user files are preserved:

```bash
newasset)
  local n; n=$(copy_lock_assets "$COUNTERPART_NEW_LOCK" "claude" "newasset" "$source" "$target")
  echo "  [✓] claude/newasset → ${target}/newasset/ (${n} files)"
  ;;
```

**Pattern B — managed block injection** (global-rules): use `upsert_managed_section` to inject content into an existing
file without touching anything outside the markers:

```bash
newasset)
  local content_source="${source}/newasset.md"
  if [[ -f "$content_source" ]]; then
    local content; content=$(cat "$content_source")
    upsert_managed_section "${HOME}/.claude/TARGETFILE.md" "$content"
    echo "  [✓] claude/newasset → ~/.claude/TARGETFILE.md"
  fi
  ;;
```

`upsert_managed_section` is available in all sync functions because `lib/section-merger.sh` is sourced by the main
`counterpart` script before the sync loop.

Repeat for each provider that supports the new asset type.

**Step 3 — Verify**

`counterpart configure` should now offer the new asset toggle for supported providers.
`counterpart sync --source <local-generated-dir>` will exercise it if the generated directory contains the expected file
or subdirectory.

---

## Key Files

| Path                                             | Role                                                             |
| ------------------------------------------------ | ---------------------------------------------------------------- |
| [`lib/providers.sh`](../../lib/providers.sh)     | The support matrix — all providers, assets, and detection logic  |
| [`counterpart`](../../counterpart)               | Source the new sync script here; add to `lock_prune_stale` pairs |
| [`lib/sync/claude.sh`](../../lib/sync/claude.sh) | Full-featured reference implementation                           |
| [`lib/sync/pi.sh`](../../lib/sync/pi.sh)         | Minimal reference implementation (skills only)                   |

---

## Gotchas & Known Failure Modes

**Bash 3.2 compatibility**

All lib scripts must target bash 3.2 (stock macOS). Avoid `declare -A`, bash 4+ features, and `[[ ]] && cmd` patterns
under `set -e`. Use loops instead of associative arrays for any provider/asset lookups. See the Gotchas section of
[story-toolbox.md](story-toolbox.md) for details.

**Provider detection requires the config directory to exist**

`detect_provider()` checks whether `PROVIDER_PATH_<PROVIDER>` exists on disk. If the engineer hasn't installed the
provider, the directory won't exist and the provider won't appear in `counterpart configure`. This is by design — don't
prompt for providers that aren't installed.

**The generated branch must include the new asset's output**

The sync pipeline is purely a consumer — it distributes whatever the generator in `counterpart-plugins` produces. A new
asset type in the toolbox does nothing until `counterpart-plugins` is updated to emit that asset type in the generated
branch. Coordinate both changes together.

---

## Testing & Verification

```bash
# Dev mode — symlink this repo's counterpart binary
make install

# Generate output locally in counterpart-plugins
make generate-clean

# Test the full sync pipeline with the local output
counterpart sync --source ../counterpart-plugins/generated
```

Run `counterpart configure` to verify the new provider/asset appears in the toggle UI. Then `counterpart status` to
confirm preferences are saved correctly.

---

## Beyond This Story

**Related context:**

- [story-toolbox.md](story-toolbox.md) — The full toolbox architecture — read this first before extending anything.
