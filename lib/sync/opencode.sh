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
  local personal_dir="${2:-}"
  local sync_dirs=("$agents_dir")
  [[ -d "$personal_dir" ]] && sync_dirs+=("$personal_dir")
  _sync_rules_combined "${HOME}/.config/opencode/AGENTS.md" "${sync_dirs[@]}"
  _sync_agents "$agents_dir" "${HOME}/.config/opencode/agents" "opencode"
  _sync_skills "$agents_dir" "${HOME}/.config/opencode/skills"
  if [[ -d "$personal_dir" ]]; then
    _sync_agents "$personal_dir" "${HOME}/.config/opencode/agents" "opencode"
    _sync_skills "$personal_dir" "${HOME}/.config/opencode/skills"
  fi
  echo "  [✓] opencode"
}
