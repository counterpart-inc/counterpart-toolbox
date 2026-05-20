#!/usr/bin/env bash
# lib/plugins-source.sh — fetch counterpart-plugins@generated branch
#
# Clones or updates a local mirror of the generated branch.
# The mirror lives at ~/.local/share/counterpart-ai-context.

[[ -n "${_CT_PLUGINS_SOURCE_LOADED:-}" ]] && return 0
_CT_PLUGINS_SOURCE_LOADED=1

PLUGINS_REPO="git@github.com:counterpart-inc/counterpart-plugins.git"
PLUGINS_BRANCH="generated"
PLUGINS_CACHE="${HOME}/.local/share/counterpart-ai-context"
PLUGINS_LOCK="${HOME}/.config/counterpart/counterpart-ai.lock"

# fetch_plugins_source — clone or pull the generated branch into local cache
fetch_plugins_source() {
  mkdir -p "$(dirname "$PLUGINS_LOCK")"

  if [[ -d "${PLUGINS_CACHE}/.git" ]]; then
    echo "  [→] Updating AI context cache..."
    git -C "$PLUGINS_CACHE" fetch origin "$PLUGINS_BRANCH" --quiet 2>&1 | sed 's/^/  /'
    git -C "$PLUGINS_CACHE" checkout "$PLUGINS_BRANCH" --quiet 2>/dev/null || true
    git -C "$PLUGINS_CACHE" reset --hard "origin/${PLUGINS_BRANCH}" --quiet
  else
    echo "  [→] Cloning AI context (first time)..."
    mkdir -p "$PLUGINS_CACHE"
    git clone --branch "$PLUGINS_BRANCH" --single-branch --depth 1 \
      "$PLUGINS_REPO" "$PLUGINS_CACHE" 2>&1 | sed 's/^/  /'
  fi

  echo "  [✓] AI context ready at ${PLUGINS_CACHE}"
}

# plugins_remote_lock_hash — fetch only the aggregate hash from remote lock
# Returns the aggregate sha256 line without a full clone (uses git ls-remote + archive)
plugins_remote_aggregate_hash() {
  git ls-remote "$PLUGINS_REPO" "refs/heads/${PLUGINS_BRANCH}" 2>/dev/null \
    | awk '{print $1}' \
    | head -1
}

# plugins_local_aggregate_hash — read aggregate from local lock file
plugins_local_aggregate_hash() {
  if [[ ! -f "$PLUGINS_LOCK" ]]; then echo ""; return; fi
  grep "^sha256:.*  \.$" "$PLUGINS_LOCK" | awk '{print $1}' | sed 's/sha256://'
}

# plugins_has_update — returns 0 if remote has changes, 1 if up to date
plugins_has_update() {
  if [[ ! -d "${PLUGINS_CACHE}/.git" ]]; then return 0; fi

  local remote_ref local_ref
  remote_ref=$(git -C "$PLUGINS_CACHE" ls-remote origin "refs/heads/${PLUGINS_BRANCH}" 2>/dev/null | awk '{print $1}')
  local_ref=$(git -C "$PLUGINS_CACHE" rev-parse HEAD 2>/dev/null || echo "")

  [[ -n "$remote_ref" && "$remote_ref" != "$local_ref" ]]
}

# plugins_source_dir — path to local cache
plugins_source_dir() {
  echo "$PLUGINS_CACHE"
}
