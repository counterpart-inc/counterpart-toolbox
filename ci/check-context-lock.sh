#!/usr/bin/env bash
set -euo pipefail

LOCK_FILE="${CONTEXT_LOCK_FILE:-context.lock}"
BASE_BRANCH="${CONTEXT_LOCK_BASE_BRANCH:-main}"
HARD_MODE="${CONTEXT_LOCK_HARD:-0}"

TOOLBOX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${TOOLBOX_DIR}/lib/context-lock.sh"

context_lock_ci_check "$LOCK_FILE" "$BASE_BRANCH"
