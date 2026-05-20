#!/usr/bin/env bash
# lib/update-check.sh — throttled background update check for zshrc hook
#
# Sourced by the zshrc hook injected during install.
# Checks if counterpart-plugins@generated has new commits since last sync.

[[ -n "${_CT_UPDATE_CHECK_LOADED:-}" ]] && return 0
_CT_UPDATE_CHECK_LOADED=1

_ct_update_check() {
  local stamp_file="${HOME}/.config/counterpart/.last-check"
  local interval_days="${COUNTERPART_CHECK_INTERVAL:-7}"
  local interval_secs=$(( interval_days * 86400 ))

  # Throttle: skip if checked recently
  if [[ -f "$stamp_file" ]]; then
    local last_check now
    last_check=$(cat "$stamp_file" 2>/dev/null || echo 0)
    now=$(date +%s)
    (( now - last_check < interval_secs )) && return 0
  fi

  # Update timestamp immediately so parallel shells don't all check at once
  mkdir -p "$(dirname "$stamp_file")"
  date +%s > "$stamp_file"

  # Run in background — never block the shell open
  (
    local cache_dir="${HOME}/.config/counterpart/cache"
    [[ -d "${cache_dir}/.git" ]] || return 0

    git -C "$cache_dir" fetch origin generated --quiet 2>/dev/null || return 0

    local remote_ref local_ref
    remote_ref=$(git -C "$cache_dir" rev-parse "origin/generated" 2>/dev/null || echo "")
    local_ref=$(git -C "$cache_dir" rev-parse HEAD 2>/dev/null || echo "")

    if [[ -n "$remote_ref" && "$remote_ref" != "$local_ref" ]]; then
      printf '\n\033[33m  counterpart: AI context update available — run \033[1mcounterpart sync\033[0m\033[33m\033[0m\n'
    fi
  ) &
}
