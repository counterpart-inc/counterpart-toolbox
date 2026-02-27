#!/usr/bin/env bash
# check_claude.sh — verify that the claude CLI is installed and callable

check_claude() {
  if ! command -v claude &>/dev/null; then
    echo "ERROR: claude CLI not found."
    echo ""
    echo "  Install it from: https://claude.ai/code"
    echo ""
    return 1
  fi

  local version
  version=$(claude --version 2>/dev/null || echo "unknown")
  echo "  [✓] claude CLI found ($version)"
  return 0
}
