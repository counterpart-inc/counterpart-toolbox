#!/usr/bin/env bash
# lib/sync/pi.sh — sync provider: Pi
#
# Installs rules to Pi's config path.
# Called by sync_global in lib/sync.sh when "pi" is in the providers list.
#
# Target paths:
#   Rules   → ~/.pi/agent/AGENTS.md     (managed block)
#   Agents  → (not supported by Pi)
#   Skills  → ~/.pi/agent/skills/

# shellcheck source=lib/sync/_common.sh
source "${TOOLBOX_DIR}/lib/sync/_common.sh"

sync_pi() {
  local agents_dir="$1"
  local personal_dir="${2:-}"
  local sync_dirs=("$agents_dir")
  [[ -d "$personal_dir" ]] && sync_dirs+=("$personal_dir")
  _sync_rules_combined "${HOME}/.pi/agent/AGENTS.md" "${sync_dirs[@]}"
  _sync_skills "$agents_dir" "${HOME}/.pi/agent/skills"
  if [[ -d "$personal_dir" ]]; then
    _sync_skills "$personal_dir" "${HOME}/.pi/agent/skills"
  fi
  echo "  [✓] pi"
}
