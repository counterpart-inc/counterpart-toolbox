#!/usr/bin/env bash
# lib/sync/opencode.sh — sync assets to OpenCode

sync_provider_opencode() {
  local source="$1"   # path to generated/opencode/
  local assets=("${@:2}")
  local target="${HOME}/.config/opencode"

  for asset in "${assets[@]}"; do
    case "$asset" in
      skills)
        local n; n=$(copy_lock_assets "$COUNTERPART_NEW_LOCK" "opencode" "skills" "$source" "$target")
        echo "  [✓] opencode/skills → ${target}/skills/ (${n} files)"
        ;;
      agents)
        local n; n=$(copy_lock_assets "$COUNTERPART_NEW_LOCK" "opencode" "agents" "$source" "$target")
        echo "  [✓] opencode/agents → ${target}/agents/ (${n} files)"
        ;;
      commands)
        local n; n=$(copy_lock_assets "$COUNTERPART_NEW_LOCK" "opencode" "commands" "$source" "$target")
        echo "  [✓] opencode/commands → ${target}/commands/ (${n} files)"
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
