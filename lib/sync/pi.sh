#!/usr/bin/env bash
# lib/sync/pi.sh — sync assets to Pi
# Pi supports: skills only. Agents/commands/hooks/mcp not supported.

sync_provider_pi() {
  local source="$1"   # path to generated/pi/
  local assets=("${@:2}")
  local target="${HOME}/.pi/agent"

  for asset in "${assets[@]}"; do
    case "$asset" in
      skills)
        mkdir -p "${target}/skills"
        cp -r "${source}/agent/skills/." "${target}/skills/"
        echo "  [✓] pi/skills → ${target}/skills/"
        ;;
    esac
  done
}
