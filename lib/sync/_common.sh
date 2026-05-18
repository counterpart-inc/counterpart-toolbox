#!/usr/bin/env bash
# lib/sync/_common.sh — shared helpers for all provider sync scripts
#
# Sourced by lib/sync.sh and each lib/sync/{provider}.sh.
# Guard prevents double-loading if both the orchestrator and a provider
# script source this file in the same shell session.

[[ -n "${_COUNTERPART_COMMON_LOADED:-}" ]] && return 0
_COUNTERPART_COMMON_LOADED=1

MANAGED_START="<!-- counterpart:managed:start -->"
MANAGED_END="<!-- counterpart:managed:end -->"

# ── Frontmatter helpers ─────────────────────────────────────────────────────────

# _parse_field <file> <field>
# Extract a single frontmatter field value from a markdown file.
_parse_field() {
  local file="$1" field="$2"
  awk -v f="$field" \
    'BEGIN{in_fm=0}
     /^---/{in_fm=!in_fm;next}
     in_fm && $0 ~ "^"f":"{gsub("^"f":[[:space:]]*",""); gsub(/"/,""); print; exit}' \
    "$file"
}

# _extract_body <file>
# Return everything after the closing --- of the frontmatter block.
_extract_body() {
  local file="$1"
  awk 'BEGIN{d=0} /^---/{d++;next} d>=2{print}' "$file"
}

# ── Managed-block injection ─────────────────────────────────────────────────────

# _upsert_managed <target> <content_file>
# Inject content_file into the managed block inside target.
# If no managed block exists yet, appends one. Content outside markers is preserved.
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

# ── High-level sync primitives ──────────────────────────────────────────────────

# _rules_combined <agents_dir>
# Concatenate all rules/*.md bodies into a single markdown blob.
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

# _sync_rules <agents_dir> <target_file>
# Write the combined rules block into target_file's managed section.
_sync_rules() {
  local agents_dir="$1" target="$2"
  local tmp
  tmp=$(mktemp)
  _rules_combined "$agents_dir" > "$tmp"
  if [[ ! -s "$tmp" ]]; then rm "$tmp"; return 0; fi
  _upsert_managed "$target" "$tmp"
  rm "$tmp"
}

# _sync_agents <agents_dir> <target_dir>
# Copy all agents/*.md files to target_dir.
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

# _sync_skills <agents_dir> <target_dir>
# Copy all skills/{name}/SKILL.md (and optional references/) to target_dir.
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
