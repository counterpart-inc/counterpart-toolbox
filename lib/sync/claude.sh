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
  _sync_rules "$agents_dir" "${HOME}/.claude/CLAUDE.md"
  _sync_agents     "$agents_dir" "${HOME}/.claude/agents"
  _sync_skills     "$agents_dir" "${HOME}/.claude/skills"
  echo "  [✓] claude"
}
