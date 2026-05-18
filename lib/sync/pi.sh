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
  _sync_rules  "$agents_dir" "${HOME}/.pi/agent/AGENTS.md"
  _sync_skills "$agents_dir" "${HOME}/.pi/agent/skills"
  echo "  [✓] pi"
}
