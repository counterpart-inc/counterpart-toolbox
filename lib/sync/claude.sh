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
        local mcp_source="${source}/../opencode/opencode.mcp.json"  # reuse MCP source
        local mcp_target="${PWD}/.mcp.json"
        if [[ -f "$mcp_source" ]]; then
          # Claude uses its own format: convert back from opencode format
          # Actually Claude's .mcp.json is already in counterpart-plugins@generated
          # The raw .mcp.json lives at the plugin level; for now just merge counterpart-* keys
          _merge_mcp_claude "$mcp_source" "$mcp_target"
        fi
        ;;
    esac
  done
}

# _merge_mcp_claude <opencode_mcp_source> <target_mcp_json>
#   Converts OpenCode MCP format back to Claude format and merges counterpart-* keys.
_merge_mcp_claude() {
  local source="$1"
  local target="$2"

  command -v jq &>/dev/null || { echo "  [!] jq required for MCP merge" >&2; return 1; }

  [[ -f "$target" ]] || echo '{}' > "$target"

  local tmp
  tmp=$(mktemp)

  # Convert opencode format → claude format and merge counterpart-* keys
  jq -s '
    .[0] as $target |
    .[1].mcp as $source_mcp |
    # Convert opencode format to claude format
    ($source_mcp // {} | to_entries | map({
      key: .key,
      value: (
        if .value.type == "remote" then { type: "http", url: .value.url }
        elif .value.type == "local" then {
          type: "stdio",
          command: .value.command[0],
          args: .value.command[1:]
        }
        else .value
        end
      )
    }) | from_entries) as $claude_mcp |
    $target |
    .mcpServers = (
      ((.mcpServers // {}) | with_entries(select(.key | startswith("counterpart-") | not))) +
      $claude_mcp
    )
  ' "$target" "$source" > "$tmp" && mv "$tmp" "$target"

  local count
  count=$(jq '.mcpServers | [keys[] | select(startswith("counterpart-"))] | length' "$target")
  echo "  [✓] claude MCP: ${count} counterpart-* server(s) → $(basename "$target")"
}
