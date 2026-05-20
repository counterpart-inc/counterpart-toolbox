#!/usr/bin/env bash
# lib/lock.sh — counterpart-ai.lock management and stale file cleanup
#
# After each sync the local lock is updated to mirror the generated branch's lock.
# On next sync, stale files (present in old lock, absent in new lock) are removed.

[[ -n "${_CT_LOCK_LOADED:-}" ]] && return 0
_CT_LOCK_LOADED=1

LOCAL_LOCK="${HOME}/.config/counterpart/counterpart-ai.lock"

# lock_update <source_lock>
#   Copies the generated branch's lock to the local state dir.
lock_update() {
  local source_lock="$1"
  if [[ ! -f "$source_lock" ]]; then
    echo "  [!] lock_update: source lock not found: $source_lock" >&2
    return 1
  fi
  mkdir -p "$(dirname "$LOCAL_LOCK")"
  cp "$source_lock" "$LOCAL_LOCK"
}

# lock_list_paths <lock_file>
#   Prints all rel_paths from the lock (excludes the aggregate ". " line).
lock_list_paths() {
  local lock="$1"
  grep "^sha256:" "$lock" 2>/dev/null \
    | grep -v '[[:space:]]\.$' \
    | awk '{print $2}'
}

# lock_stale_files <old_lock> <new_lock>
#   Prints paths present in old_lock but absent in new_lock (stale).
lock_stale_files() {
  local old_lock="$1" new_lock="$2"
  if [[ ! -f "$old_lock" || ! -f "$new_lock" ]]; then return 0; fi

  comm -23 \
    <(lock_list_paths "$old_lock" | LC_ALL=C sort) \
    <(lock_list_paths "$new_lock" | LC_ALL=C sort)
}

# lock_prune_stale <old_lock> <new_lock> <base_dir>
#   Removes files in base_dir that appear in old_lock but not new_lock.
#   base_dir maps lock rel_paths to actual filesystem paths.
#   Mapping is: <base_dir>/<provider_prefix_stripped> for each provider.
#
#   Lock paths look like: claude/skills/cmpd-plan/SKILL.md
#   This function takes a provider→target mapping to resolve absolute paths.
lock_prune_stale() {
  local old_lock="$1"
  local new_lock="$2"
  shift 2
  # Remaining args: provider:target_dir pairs  e.g. "claude:${HOME}/.claude"
  declare -A provider_map
  for pair in "$@"; do
    local prov="${pair%%:*}"
    local target="${pair#*:}"
    provider_map["$prov"]="$target"
  done

  local pruned=0
  while IFS= read -r rel_path; do
    local provider="${rel_path%%/*}"
    local sub_path="${rel_path#*/}"
    local target_base="${provider_map[$provider]:-}"
    if [[ -z "$target_base" ]]; then continue; fi
    local abs_path="${target_base}/${sub_path}"
    if [[ -f "$abs_path" ]]; then
      rm -f "$abs_path"
      echo "  [→] pruned: ${abs_path}"
      pruned=$((pruned + 1))
    fi
  done < <(lock_stale_files "$old_lock" "$new_lock")

  [[ $pruned -gt 0 ]] && echo "  [✓] pruned ${pruned} stale file(s)"
}

# lock_aggregate <lock_file>
#   Returns the aggregate sha256 hash from a lock file.
lock_aggregate() {
  grep "^sha256:.*  \.$" "${1:-}" 2>/dev/null | awk '{print $1}' | sed 's/sha256://'
}

# lock_is_current <source_lock>
#   Returns 0 if local lock matches source lock aggregate hash.
lock_is_current() {
  local source_lock="$1"
  local remote_agg local_agg
  remote_agg=$(lock_aggregate "$source_lock")
  local_agg=$(lock_aggregate "$LOCAL_LOCK")
  [[ -n "$remote_agg" && "$remote_agg" == "$local_agg" ]]
}
