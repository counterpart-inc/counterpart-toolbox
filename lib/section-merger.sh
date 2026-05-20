#!/usr/bin/env bash
# lib/section-merger.sh — managed-block injection for AGENTS.md / CLAUDE.md
#
# Preserves user content outside the managed block.
# On first run: prepends managed block at the top of the file.
# On subsequent runs: replaces only the content between the markers.

[[ -n "${_CT_SECTION_MERGER_LOADED:-}" ]] && return 0
_CT_SECTION_MERGER_LOADED=1

_SM_START="<!-- counterpart:managed:start -->"
_SM_END="<!-- counterpart:managed:end -->"

# upsert_managed_section <target_file> <content>
#   Injects <content> into the managed block in <target_file>.
#   Creates the file if it doesn't exist.
#   If no managed block exists yet, prepends one.
upsert_managed_section() {
  local target="$1"
  local content="$2"

  mkdir -p "$(dirname "$target")"
  [[ -f "$target" ]] || touch "$target"

  local tmp
  tmp=$(mktemp)

  if grep -qF "$_SM_START" "$target" 2>/dev/null; then
    # Replace content between markers, preserve everything outside
    local in_block=0
    while IFS= read -r line; do
      if [[ "$line" == "$_SM_START" ]]; then
        printf '%s\n' "$line"
        printf '%s\n' "$content"
        in_block=1
      elif [[ "$line" == "$_SM_END" ]]; then
        printf '%s\n' "$line"
        in_block=0
      elif [[ $in_block -eq 0 ]]; then
        printf '%s\n' "$line"
      fi
    done < "$target" > "$tmp"
  else
    # No managed block yet — prepend it, keep user content below
    {
      printf '%s\n' "$_SM_START"
      printf '%s\n' "$content"
      printf '%s\n' "$_SM_END"
      echo ""
      cat "$target"
    } > "$tmp"
  fi

  mv "$tmp" "$target"
}
