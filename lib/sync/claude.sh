#!/usr/bin/env bash
# lib/sync/claude.sh — sync provider: Claude Code
#
# Installs rules, agents, and skills to Claude Code's config paths.
# Called by sync_global in lib/sync.sh when "claude" is in the providers list.
#
# Target paths:
#   Rules   → ~/.claude/CLAUDE.md     (managed block)
#   Agents  → ~/.claude/agents/
#   Skills  → ~/.claude/skills/

# shellcheck source=lib/sync/_common.sh
source "${TOOLBOX_DIR}/lib/sync/_common.sh"

sync_claude() {
  local agents_dir="$1"
  local personal_dir="${2:-}"
  local sync_dirs=("$agents_dir")
  [[ -d "$personal_dir" ]] && sync_dirs+=("$personal_dir")
  _sync_rules_combined "${HOME}/.claude/CLAUDE.md" "${sync_dirs[@]}"
  _sync_agents "$agents_dir" "${HOME}/.claude/agents" "claude"
  _sync_skills "$agents_dir" "${HOME}/.claude/skills"
  if [[ -d "$personal_dir" ]]; then
    _sync_agents "$personal_dir" "${HOME}/.claude/agents" "claude"
    _sync_skills "$personal_dir" "${HOME}/.claude/skills"
  fi
  echo "  [✓] claude"
}
