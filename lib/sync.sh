#!/usr/bin/env bash
set -euo pipefail

MANAGED_START="<!-- counterpart:managed:start -->"
MANAGED_END="<!-- counterpart:managed:end -->"

_slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-'
}

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
  [[ ! -f "$target" ]] && touch "$target"

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
  [[ ! -d "$rules_dir" ]] && return 0
  while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    local name body
    name=$(_parse_field "$f" "name")
    body=$(_extract_body "$f")
    [[ -z "$name" ]] && name=$(basename "$f" .md)
    printf '## %s\n%s\n\n' "$name" "$body"
  done < <(find "$rules_dir" -name "*.md" | LC_ALL=C sort)
}

_sync_to_managed() {
  local agents_dir="$1" target="$2"
  local tmp
  tmp=$(mktemp)
  _rules_combined "$agents_dir" > "$tmp"
  [[ ! -s "$tmp" ]] && { rm "$tmp"; return 0; }
  _upsert_managed "$target" "$tmp"
  rm "$tmp"
}

_sync_cursor() {
  local agents_dir="$1" cursor_dir="$2"
  local rules_dir="${agents_dir}/rules"
  [[ ! -d "$rules_dir" ]] && return 0
  mkdir -p "$cursor_dir"
  while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    local name desc always body slug
    name=$(_parse_field "$f" "name")
    desc=$(_parse_field "$f" "description")
    always=$(_parse_field "$f" "alwaysApply")
    body=$(_extract_body "$f")
    [[ -z "$name" ]] && name=$(basename "$f" .md)
    [[ -z "$always" ]] && always="true"
    slug=$(_slugify "$name")
    printf -- '---\ndescription: %s\nalwaysApply: %s\n---\n\n%s\n' \
      "${desc:-$name}" "$always" "$body" > "${cursor_dir}/${slug}.mdc"
  done < <(find "$rules_dir" -name "*.md" | LC_ALL=C sort)
}

_sync_skills() {
  local agents_dir="$1" target_dir="$2"
  local skills_dir="${agents_dir}/skills"
  [[ ! -d "$skills_dir" ]] && return 0
  mkdir -p "$target_dir"
  for skill in "${skills_dir}"/*/; do
    [[ -d "$skill" ]] || continue
    local sname
    sname=$(basename "$skill")
    [[ ! -f "${skill}SKILL.md" ]] && continue
    mkdir -p "${target_dir}/${sname}"
    cp "${skill}SKILL.md" "${target_dir}/${sname}/SKILL.md"
    [[ -d "${skill}references" ]] && cp -r "${skill}references" "${target_dir}/${sname}/"
  done
}

sync_global() {
  local agents_dir="${1:-${HOME}/.agents}"
  [[ ! -d "$agents_dir" ]] && return 0
  _sync_to_managed "$agents_dir" "${HOME}/.claude/CLAUDE.md"
  _sync_to_managed "$agents_dir" "${HOME}/.config/opencode/AGENTS.md"
  _sync_to_managed "$agents_dir" "${HOME}/.copilot/copilot-instructions.md"
  _sync_cursor "$agents_dir" "${HOME}/.cursor/rules"
  _sync_skills "$agents_dir" "${HOME}/.claude/skills"
  _sync_skills "$agents_dir" "${HOME}/.config/opencode/skills"
  echo "  [✓] Global sync complete"
}

sync_local() {
  local repo_dir="${1:-$PWD}"
  local agents_dir="${2:-${repo_dir}/.agents}"
  [[ ! -d "$agents_dir" ]] && return 0
  _sync_to_managed "$agents_dir" "${repo_dir}/AGENTS.md"
  _sync_cursor "$agents_dir" "${repo_dir}/.cursor/rules"
  echo "  [✓] Local sync complete"
}
