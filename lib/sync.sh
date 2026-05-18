#!/usr/bin/env bash

MANAGED_START="<!-- counterpart:managed:start -->"
MANAGED_END="<!-- counterpart:managed:end -->"


_parse_field() {
  local file="$1" field="$2"
  awk -v f="$field" 'BEGIN{in_fm=0} /^---/{in_fm=!in_fm;next} in_fm && $0 ~ "^"f":"{gsub("^"f":[[:space:]]*",""); gsub(/"/,""); print; exit}' "$file"
}

_extract_body() {
  local file="$1"
  awk 'BEGIN{d=0} /^---/{d++;next} d>=2{print}' "$file"
}

_upsert_managed() {
  local target="$1" content_file="$2"
  mkdir -p "$(dirname "$target")"
  if [[ ! -f "$target" ]]; then touch "$target"; fi

  local tmp
  tmp=$(mktemp)

  if grep -qF "$MANAGED_START" "$target" 2>/dev/null; then
    local in_block=0
    while IFS= read -r line; do
      if [[ "$line" == "$MANAGED_START" ]]; then
        echo "$line"
        cat "$content_file"
        in_block=1
      elif [[ "$line" == "$MANAGED_END" ]]; then
        echo "$line"
        in_block=0
      elif [[ $in_block -eq 0 ]]; then
        echo "$line"
      fi
    done < "$target" > "$tmp"
    mv "$tmp" "$target"
  else
    {
      echo ""
      echo "$MANAGED_START"
      cat "$content_file"
      echo "$MANAGED_END"
    } >> "$target"
  fi
}

_rules_combined() {
  local agents_dir="$1"
  local rules_dir="${agents_dir}/rules"
  if [[ ! -d "$rules_dir" ]]; then return 0; fi
  while IFS= read -r f; do
    if [[ ! -f "$f" ]]; then continue; fi
    local name body
    name=$(_parse_field "$f" "name")
    body=$(_extract_body "$f")
    if [[ -z "$name" ]]; then name=$(basename "$f" .md); fi
    printf '## %s\n%s\n\n' "$name" "$body"
  done < <(find "$rules_dir" -name "*.md" | LC_ALL=C sort)
}

_sync_to_managed() {
  local agents_dir="$1" target="$2"
  local tmp
  tmp=$(mktemp)
  _rules_combined "$agents_dir" > "$tmp"
  if [[ ! -s "$tmp" ]]; then rm "$tmp"; return 0; fi
  _upsert_managed "$target" "$tmp"
  rm "$tmp"
}


_sync_agents() {
  local agents_dir="$1" target_dir="$2"
  local src="${agents_dir}/agents"
  if [[ ! -d "$src" ]]; then return 0; fi
  mkdir -p "$target_dir"
  while IFS= read -r f; do
    if [[ ! -f "$f" ]]; then continue; fi
    cp "$f" "${target_dir}/$(basename "$f")"
  done < <(find "$src" -maxdepth 1 -name "*.md" | LC_ALL=C sort)
}

_sync_skills() {
  local agents_dir="$1" target_dir="$2"
  local skills_dir="${agents_dir}/skills"
  if [[ ! -d "$skills_dir" ]]; then return 0; fi
  mkdir -p "$target_dir"
  for skill in "${skills_dir}"/*/; do
    if [[ ! -d "$skill" ]]; then continue; fi
    local sname
    sname=$(basename "$skill")
    if [[ ! -f "${skill}SKILL.md" ]]; then continue; fi
    mkdir -p "${target_dir}/${sname}"
    cp "${skill}SKILL.md" "${target_dir}/${sname}/SKILL.md"
    if [[ -d "${skill}references" ]]; then
      cp -r "${skill}references" "${target_dir}/${sname}/"
    fi
  done
}

sync_global() {
  local agents_dir="${1:-${HOME}/.agents}"
  if [[ ! -d "$agents_dir" ]]; then return 0; fi
  _sync_to_managed "$agents_dir" "${HOME}/.claude/CLAUDE.md"
  _sync_to_managed "$agents_dir" "${HOME}/.config/opencode/AGENTS.md"
  _sync_to_managed "$agents_dir" "${HOME}/.pi/AGENTS.md"
  _sync_agents "$agents_dir" "${HOME}/.claude/agents"
  _sync_agents "$agents_dir" "${HOME}/.config/opencode/agents"
  _sync_skills "$agents_dir" "${HOME}/.claude/skills"
  _sync_skills "$agents_dir" "${HOME}/.config/opencode/skills"
  echo "  [✓] Global sync complete"
}

sync_local() {
  local repo_dir="${1:-$PWD}"
  local agents_dir="${2:-${repo_dir}/.agents}"
  if [[ ! -d "$agents_dir" ]]; then return 0; fi
  _sync_to_managed "$agents_dir" "${repo_dir}/AGENTS.md"
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
  agents_list=$(find "${agents_dir}/agents" -name "*.md" 2>/dev/null | while IFS= read -r f; do basename "$f" .md; done | jq -Rsc 'split("\n") | map(select(length>0))')
  rules_list=$(find "${agents_dir}/rules" -name "*.md" 2>/dev/null | while IFS= read -r f; do basename "$f" .md; done | jq -Rsc 'split("\n") | map(select(length>0))')
  skills_list=$(find "${agents_dir}/skills" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | while IFS= read -r d; do basename "$d"; done | jq -Rsc 'split("\n") | map(select(length>0))')

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
