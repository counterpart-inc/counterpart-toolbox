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
#   Merges hooks from source into target .claude/settings.json.
#   Source format: { "hooks": { "PreToolUse": [...], ... } }
#   Creates target if it doesn't exist.
#   Deduplicates hook entries by JSON identity.
merge_hooks_claude() {
  local source="$1"
  local target="$2"

  if ! command -v jq &>/dev/null; then
    echo "  [!] jq required for hooks merge" >&2; return 1
  fi
  if [[ ! -f "$source" ]]; then
    echo "  [!] Hooks source not found: $source" >&2; return 1
  fi

  mkdir -p "$(dirname "$target")"
  [[ -f "$target" ]] || echo '{}' > "$target"

  local tmp
  tmp=$(mktemp)

  # For each event type, merge arrays and deduplicate by JSON identity
  jq -s '
    .[0] as $target |
    .[1].hooks as $source_hooks |
    $target |
    .hooks = (
      (($target.hooks // {}) + ($source_hooks // {})) |
      to_entries |
      map({
        key: .key,
        value: (
          (.value | unique_by(tojson))
        )
      }) |
      from_entries
    )
  ' "$target" "$source" > "$tmp" && mv "$tmp" "$target"

  local count
  count=$(jq '[.hooks // {} | to_entries[] | .value | length] | add // 0' "$target")
  echo "  [✓] claude hooks: ${count} hook(s) in $(basename "$target")"
}
