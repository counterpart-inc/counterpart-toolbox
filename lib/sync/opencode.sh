#!/usr/bin/env bash
# lib/sync/opencode.sh — sync provider: OpenCode
#
# Installs rules, agents, and skills to OpenCode's config paths.
# Called by sync_global in lib/sync.sh when "opencode" is in the providers list.
#
# Target paths:
#   Rules   → ~/.config/opencode/AGENTS.md     (managed block)
#   Agents  → ~/.config/opencode/agents/
#   Skills  → ~/.config/opencode/skills/

# shellcheck source=lib/sync/_common.sh
source "${TOOLBOX_DIR}/lib/sync/_common.sh"

sync_opencode() {
  local agents_dir="$1"
  _sync_rules "$agents_dir" "${HOME}/.config/opencode/AGENTS.md"
  _sync_agents     "$agents_dir" "${HOME}/.config/opencode/agents"
  _sync_skills     "$agents_dir" "${HOME}/.config/opencode/skills"
  echo "  [✓] opencode"
}
