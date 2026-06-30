#!/usr/bin/env bash
# lib/sync/pi.sh — sync assets to Pi
# Pi supports: skills only. Agents/commands/hooks/mcp not supported.
#
# NOTE: Pi's source lives at the cache root (not cache/pi/), and files are
# under agent/skills/. Lock-based copying is not yet implemented for Pi
# because the lock path structure for Pi needs verification against real
# Pi-installed lock entries. Using cp -r in the meantime.
# TODO: migrate to copy_lock_assets once Pi lock paths are confirmed.

sync_provider_pi() {
  local source="$1"   # path to generated/ (cache root for Pi)
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
