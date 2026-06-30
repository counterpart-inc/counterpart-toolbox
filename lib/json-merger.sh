#!/usr/bin/env bash
# lib/json-merger.sh — namespace-based JSON merge for MCP and hooks
#
# MCP:   only touches keys prefixed "counterpart-*" in the target's .mcp section
# Hooks: merges into .claude/settings.json at the project level (never user global)

[[ -n "${_CT_JSON_MERGER_LOADED:-}" ]] && return 0
_CT_JSON_MERGER_LOADED=1

# merge_mcp_opencode <source_mcp_json> <target_opencode_json>
#   Merges counterpart-* MCP keys from source into target opencode.json.
#   Source format: { "mcp": { "counterpart-*": { ... } } }
#   Creates target if it doesn't exist.
#   Never touches non-counterpart-* keys in target.
merge_mcp_opencode() {
  local source="$1"
  local target="$2"

  if ! command -v jq &>/dev/null; then
    echo "  [!] jq required for MCP merge" >&2; return 1
  fi
  if [[ ! -f "$source" ]]; then
    echo "  [!] MCP source not found: $source" >&2; return 1
  fi

  mkdir -p "$(dirname "$target")"
  [[ -f "$target" ]] || echo '{}' > "$target"

  local tmp
  tmp=$(mktemp)

  # Remove old counterpart-* keys from target, then add all from source
  jq -s '
    .[0] as $target |
    .[1].mcp as $source_mcp |
    $target |
    .mcp = (
      ((.mcp // {}) | with_entries(select(.key | startswith("counterpart-") | not))) +
      ($source_mcp // {})
    )
  ' "$target" "$source" > "$tmp" && mv "$tmp" "$target"

  local count
  count=$(jq '.mcp | [keys[] | select(startswith("counterpart-"))] | length' "$target")
  echo "  [✓] opencode MCP: ${count} counterpart-* server(s) merged"
}

# merge_hooks_claude <source_hooks_json> <target_settings_json>
#   Merges hooks from source into target ~/.claude/settings.json (user-level).
#   Source format: { "hooks": { "PreToolUse": [...], ... } }
#   Creates target if it doesn't exist.
#
#   Counterpart-owned hooks are tracked in ~/.config/counterpart/last-claude-hooks.json.
#   On each sync, old counterpart hooks are removed and new ones are added.
#   User's own hooks are never touched — they are never in the tracked set.
merge_hooks_claude() {
  local source="$1"
  local target="$2"
  local state_file="${HOME}/.config/counterpart/last-claude-hooks.json"

  if ! command -v jq &>/dev/null; then
    echo "  [!] jq required for hooks merge" >&2; return 1
  fi
  if [[ ! -f "$source" ]]; then
    echo "  [!] Hooks source not found: $source" >&2; return 1
  fi

  mkdir -p "$(dirname "$target")"
  [[ -f "$target" ]] || echo '{}' > "$target"

  # Load last-synced counterpart hooks (empty object on first run)
  local old_hooks="{}"
  [[ -f "$state_file" ]] && old_hooks=$(cat "$state_file")

  # Extract new hooks from source
  local new_hooks
  new_hooks=$(jq '.hooks // {}' "$source")

  local tmp
  tmp=$(mktemp)

  # For each event type managed by counterpart (union of old and new):
  #   - Remove entries that match the old counterpart set (cleaning up removed hooks)
  #   - Add entries from the new counterpart set
  #   - Leave user hooks (not in old counterpart set) untouched
  jq -s --argjson old "$old_hooks" --argjson new "$new_hooks" '
    .[0] as $target |
    ([$old, $new] | map(keys) | add | unique) as $managed_events |
    $target |
    .hooks = (
      reduce $managed_events[] as $event (
        ($target.hooks // {});
        . + {
          ($event): (
            [
              (.[$event] // [])[] |
              . as $item |
              select(($old[$event] // []) | map(. == $item) | any | not)
            ] +
            ($new[$event] // []) |
            unique_by(tojson)
          )
        }
      )
    )
  ' "$target" > "$tmp" && mv "$tmp" "$target"

  # Persist the new counterpart hooks as the reference for the next sync
  mkdir -p "$(dirname "$state_file")"
  echo "$new_hooks" > "$state_file"

  local count
  count=$(jq '[.hooks // {} | to_entries[] | .value | length] | add // 0' "$target")
  echo "  [✓] claude hooks: ${count} hook(s) in $(basename "$target")"
}
