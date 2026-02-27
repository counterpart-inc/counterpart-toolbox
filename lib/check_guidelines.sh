#!/usr/bin/env bash
# check_guidelines.sh — ensure CLAUDE.md exists in CWD and contains company guidelines header

# Reads from COUNTERPART_CONFIG and COUNTERPART_WORKSPACE (set by yourclaude main script)

check_guidelines() {
  local guidelines_header
  guidelines_header=$(jq -r '.guidelines_header // "# Counterpart Guidelines"' "$COUNTERPART_CONFIG" 2>/dev/null)

  local workspace_guidelines="${COUNTERPART_WORKSPACE}/.counterpart/guidelines.md"
  local target_claude_md="${PWD}/CLAUDE.md"

  # Determine the guidelines content source
  local guidelines_content=""
  if [[ -f "$workspace_guidelines" ]]; then
    guidelines_content=$(cat "$workspace_guidelines")
  elif [[ -f "${TOOLBOX_DIR}/templates/guidelines.md" ]]; then
    guidelines_content=$(cat "${TOOLBOX_DIR}/templates/guidelines.md")
  else
    echo "  [!] No guidelines template found. Skipping CLAUDE.md check."
    return 0
  fi

  if [[ ! -f "$target_claude_md" ]]; then
    echo "  [!] No CLAUDE.md found in current directory ($PWD)."
    printf "      Create one with Counterpart guidelines? [Y/n] "
    read -r answer </dev/tty
    answer="${answer:-Y}"
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      echo "$guidelines_content" > "$target_claude_md"
      echo "  [✓] Created CLAUDE.md with Counterpart guidelines."
    else
      echo "      Skipped CLAUDE.md creation."
    fi
    return 0
  fi

  # CLAUDE.md exists — check if the guidelines header is present
  if grep -qF "$guidelines_header" "$target_claude_md"; then
    echo "  [✓] CLAUDE.md contains Counterpart guidelines."
  else
    echo "  [!] CLAUDE.md exists but is missing Counterpart guidelines header."
    printf "      Prepend company guidelines to CLAUDE.md? [Y/n] "
    read -r answer </dev/tty
    answer="${answer:-Y}"
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      local tmp
      tmp=$(mktemp)
      {
        echo "$guidelines_content"
        echo ""
        echo "---"
        echo ""
        cat "$target_claude_md"
      } > "$tmp"
      mv "$tmp" "$target_claude_md"
      echo "  [✓] Prepended Counterpart guidelines to CLAUDE.md."
    else
      echo "      Skipped prepending guidelines."
    fi
  fi
}
