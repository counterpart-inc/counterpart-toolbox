#!/usr/bin/env bash
# lib/sync.sh — sync orchestrator
#
# Public API used by yourcounterpart:
#   sync_global <agents_dir> [provider...]   — sync to all listed providers
#   sync_local  <repo_dir> [agents_dir]      — sync into a local repo's AGENTS.md
#   write_agents_lock <agents_dir> <toolbox_dir> [workspace]

# shellcheck source=lib/sync/_common.sh
source "${TOOLBOX_DIR}/lib/sync/_common.sh"

sync_global() {
  local agents_dir="$1"
  shift
  local providers=("$@")

  if [[ ! -d "$agents_dir" ]]; then return 0; fi

  if [[ ${#providers[@]} -eq 0 ]]; then
    echo "  [!] No providers configured — nothing to sync"
    return 0
  fi

  for provider in "${providers[@]}"; do
    local provider_script="${TOOLBOX_DIR}/lib/sync/${provider}.sh"
    if [[ ! -f "$provider_script" ]]; then
      echo "  [!] No sync script for '${provider}' — skipping (add lib/sync/${provider}.sh to support it)"
      continue
    fi
    # shellcheck source=/dev/null
    source "$provider_script"
    "sync_${provider}" "$agents_dir"
  done

  echo "  [✓] Sync complete"
}

sync_local() {
  local repo_dir="${1:-$PWD}"
  local agents_dir="${2:-${repo_dir}/.agents}"
  if [[ ! -d "$agents_dir" ]]; then return 0; fi
  _sync_rules "$agents_dir" "${repo_dir}/AGENTS.md"
  echo "  [✓] Local sync complete"
}

write_agents_lock() {
  local agents_dir="${1:-}"
  local toolbox_dir="${2:-}"
  local workspace="${3:-${COUNTERPART_WORKSPACE:-}}"
  local lock_file="${workspace}/.counterpart/toolbox.lock"

  command -v jq &>/dev/null || return 0

  local commit="unknown"
  if [[ -n "$toolbox_dir" && -d "${toolbox_dir}/.git" ]]; then
    commit=$(git -C "${toolbox_dir}" rev-parse HEAD 2>/dev/null || echo "unknown")
  fi

  local synced_at
  synced_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  local agents_list rules_list skills_list
  agents_list=$(find "${agents_dir}/agents" -name "*.md" 2>/dev/null \
    | while IFS= read -r f; do basename "$f" .md; done \
    | jq -Rsc 'split("\n") | map(select(length>0))')
  rules_list=$(find "${agents_dir}/rules" -name "*.md" 2>/dev/null \
    | while IFS= read -r f; do basename "$f" .md; done \
    | jq -Rsc 'split("\n") | map(select(length>0))')
  skills_list=$(find "${agents_dir}/skills" -maxdepth 1 -mindepth 1 -type d 2>/dev/null \
    | while IFS= read -r d; do basename "$d"; done \
    | jq -Rsc 'split("\n") | map(select(length>0))')

  mkdir -p "$(dirname "$lock_file")"
  jq -n \
    --arg commit "$commit" \
    --arg synced_at "$synced_at" \
    --argjson agents "${agents_list:-[]}" \
    --argjson rules "${rules_list:-[]}" \
    --argjson skills "${skills_list:-[]}" \
    '{
      version: 1,
      sources: {
        "counterpart-inc/counterpart-toolbox": {
          commit: $commit,
          syncedAt: $synced_at,
          agents: $agents,
          rules: $rules,
          skills: $skills
        }
      }
    }' > "$lock_file"
}
