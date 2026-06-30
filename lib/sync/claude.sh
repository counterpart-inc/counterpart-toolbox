#!/usr/bin/env bash
# lib/sync/claude.sh — sync assets to Claude Code

sync_provider_claude() {
  local source="$1"   # path to generated/claude/
  local assets=("${@:2}")
  local target="${HOME}/.claude"

  for asset in "${assets[@]}"; do
    case "$asset" in
      skills)
        local n; n=$(copy_lock_assets "$COUNTERPART_NEW_LOCK" "claude" "skills" "$source" "$target")
        echo "  [✓] claude/skills → ${target}/skills/ (${n} files)"
        ;;
      agents)
        local n; n=$(copy_lock_assets "$COUNTERPART_NEW_LOCK" "claude" "agents" "$source" "$target")
        echo "  [✓] claude/agents → ${target}/agents/ (${n} files)"
        ;;
      commands)
        local n; n=$(copy_lock_assets "$COUNTERPART_NEW_LOCK" "claude" "commands" "$source" "$target")
        echo "  [✓] claude/commands → ${target}/commands/ (${n} files)"
        ;;
      output-styles)
        local n; n=$(copy_lock_assets "$COUNTERPART_NEW_LOCK" "claude" "output-styles" "$source" "$target")
        echo "  [✓] claude/output-styles → ${target}/output-styles/ (${n} files)"
        ;;
      global-rules)
        local rules_source="${source}/AGENTS.md"
        local rules_target="${HOME}/.claude/CLAUDE.md"
        if [[ -f "$rules_source" ]]; then
          local content; content=$(cat "$rules_source")
          upsert_managed_section "$rules_target" "$content"
          echo "  [✓] claude global-rules → ${rules_target}"
        fi
        ;;
      hooks)
        local hooks_source="${source}/hooks/hooks.json"
        local hooks_target="${HOME}/.claude/settings.json"
        if [[ -f "$hooks_source" ]]; then
          mkdir -p "${HOME}/.claude"
          merge_hooks_claude "$hooks_source" "$hooks_target"
        fi
        ;;
      mcp)
        local mcp_source="${source}/mcp.json"
        local mcp_target="${HOME}/.claude.json"
        if [[ -f "$mcp_source" ]]; then
          _merge_mcp_claude "$mcp_source" "$mcp_target"
        fi
        ;;
    esac
  done
}

# _merge_mcp_claude <source_mcp_json> <target_claude_json>
#   Merges counterpart-* keys from source into ~/.claude.json under .mcpServers
#   (user scope — available across all projects).
#   Never touches non-counterpart-* keys in target.
_merge_mcp_claude() {
  local source="$1"
  local target="$2"

  command -v jq &>/dev/null || { echo "  [!] jq required for MCP merge" >&2; return 1; }

  [[ -f "$target" ]] || echo '{}' > "$target"

  local tmp
  tmp=$(mktemp)

  jq -s '
    .[0] as $target |
    .[1].mcpServers as $source_servers |
    $target |
    .mcpServers = (
      ((.mcpServers // {}) | with_entries(select(.key | startswith("counterpart-") | not))) +
      ($source_servers // {})
    )
  ' "$target" "$source" > "$tmp" && mv "$tmp" "$target"

  local count
  count=$(jq '.mcpServers | [keys[] | select(startswith("counterpart-"))] | length' "$target")
  echo "  [✓] claude MCP: ${count} counterpart-* server(s) → $(basename "$target")"
}
