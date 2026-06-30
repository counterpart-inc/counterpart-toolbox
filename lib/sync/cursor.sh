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
        # Note: asset is "skills" in prefs but "rules" in the lock/generated dir
        local n; n=$(copy_lock_assets "$COUNTERPART_NEW_LOCK" "cursor" "rules" "$source" "$target")
        echo "  [✓] cursor/rules → ${target}/rules/ (${n} files)"
        ;;
    esac
  done
}
