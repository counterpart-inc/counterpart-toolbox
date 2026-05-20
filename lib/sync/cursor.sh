#!/usr/bin/env bash
# lib/sync/cursor.sh — sync assets to Cursor
# Cursor supports: skills (as .mdc rule files) only.
# Rules are written to ~/.cursor/rules/ (global Cursor rules directory).

sync_provider_cursor() {
  local source="$1"   # path to generated/cursor/
  local assets=("${@:2}")
  local target="${HOME}/.cursor"

  for asset in "${assets[@]}"; do
    case "$asset" in
      skills)
        mkdir -p "${target}/rules"
        cp -r "${source}/rules/." "${target}/rules/"
        echo "  [✓] cursor/rules → ${target}/rules/"
        ;;
    esac
  done
}
