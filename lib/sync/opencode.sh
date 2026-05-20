#!/usr/bin/env bash
# lib/sync/opencode.sh — sync assets to OpenCode

sync_provider_opencode() {
  local source="$1"   # path to generated/opencode/
  local assets=("${@:2}")
  local target="${HOME}/.config/opencode"

  for asset in "${assets[@]}"; do
    case "$asset" in
      skills)
        mkdir -p "${target}/skills"
        cp -r "${source}/skills/." "${target}/skills/"
        echo "  [✓] opencode/skills → ${target}/skills/"
        ;;
      agents)
        mkdir -p "${target}/agents"
        cp -r "${source}/agents/." "${target}/agents/"
        echo "  [✓] opencode/agents → ${target}/agents/"
        ;;
      commands)
        mkdir -p "${target}/commands"
        cp -r "${source}/commands/." "${target}/commands/"
        echo "  [✓] opencode/commands → ${target}/commands/"
        ;;
      mcp)
        local mcp_source="${source}/opencode.mcp.json"
        local mcp_target="${HOME}/.config/opencode/opencode.json"
        if [[ -f "$mcp_source" ]]; then
          merge_mcp_opencode "$mcp_source" "$mcp_target"
        fi
        ;;
    esac
  done
}
