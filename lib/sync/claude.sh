#!/usr/bin/env bash
# lib/sync/claude.sh — sync assets to Claude Code

sync_provider_claude() {
  local source="$1"   # path to generated/claude/
  local assets=("${@:2}")
  local target="${HOME}/.claude"

  for asset in "${assets[@]}"; do
    case "$asset" in
      skills)
        mkdir -p "${target}/skills"
        cp -r "${source}/skills/." "${target}/skills/"
        echo "  [✓] claude/skills → ${target}/skills/"
        ;;
      agents)
        mkdir -p "${target}/agents"
        cp -r "${source}/agents/." "${target}/agents/"
        echo "  [✓] claude/agents → ${target}/agents/"
        ;;
      commands)
        mkdir -p "${target}/commands"
        cp -r "${source}/commands/." "${target}/commands/"
        echo "  [✓] claude/commands → ${target}/commands/"
        ;;
      output-styles)
        mkdir -p "${target}/output-styles"
        cp -r "${source}/output-styles/." "${target}/output-styles/"
        echo "  [✓] claude/output-styles → ${target}/output-styles/"
        ;;
      hooks)
        local hooks_source="${source}/hooks/hooks.json"
        local hooks_target="${PWD}/.claude/settings.json"
        if [[ -f "$hooks_source" ]]; then
          mkdir -p "${PWD}/.claude"
          merge_hooks_claude "$hooks_source" "$hooks_target"
        fi
        ;;
      mcp)
        local mcp_source="${source}/mcp.json"
        local mcp_target="${PWD}/.mcp.json"
        if [[ -f "$mcp_source" ]]; then
          _merge_mcp_claude "$mcp_source" "$mcp_target"
        fi
        ;;
    esac
  done
}

# _merge_mcp_claude <source_mcp_json> <target_mcp_json>
#   Merges counterpart-* keys from source (Claude format) into target .mcp.json.
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
