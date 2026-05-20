#!/usr/bin/env bash
# lib/providers.sh — provider detection, asset support matrix, and UI descriptions
#
# Sourced by the counterpart CLI. Do not execute directly.

[[ -n "${_CT_PROVIDERS_LOADED:-}" ]] && return 0
_CT_PROVIDERS_LOADED=1

# ── Provider config paths ───────────────────────────────────────────────────────

PROVIDER_PATH_CLAUDE="${HOME}/.claude"
PROVIDER_PATH_OPENCODE="${HOME}/.config/opencode"
PROVIDER_PATH_PI="${HOME}/.pi/agent"
PROVIDER_PATH_CURSOR="${HOME}/.cursor"

# ── All known providers (display order) ────────────────────────────────────────

ALL_PROVIDERS=(claude opencode pi cursor)

# ── All known assets (display order) ───────────────────────────────────────────

ALL_ASSETS=(skills agents commands hooks output-styles mcp)

# ── Asset support matrix ────────────────────────────────────────────────────────
# provider_supports <provider> <asset>  → returns 0 (yes) or 1 (no)

provider_supports() {
  local provider="$1" asset="$2"
  case "${provider}:${asset}" in
    claude:skills)        return 0 ;;
    claude:agents)        return 0 ;;
    claude:commands)      return 0 ;;
    claude:hooks)         return 0 ;;
    claude:output-styles) return 0 ;;
    claude:mcp)           return 0 ;;
    opencode:skills)      return 0 ;;
    opencode:agents)      return 0 ;;
    opencode:commands)    return 0 ;;
    opencode:mcp)         return 0 ;;
    pi:skills)            return 0 ;;
    cursor:skills)        return 0 ;;
    *)                    return 1 ;;
  esac
}

# ── Asset descriptions (shown in the toggle UI) ─────────────────────────────────

asset_description() {
  local provider="$1" asset="$2"
  case "$asset" in
    skills)
      case "$provider" in
        claude)   echo "Load on-demand instructions via /skill → ~/.claude/skills/" ;;
        opencode) echo "Load on-demand instructions via /skill → ~/.config/opencode/skills/" ;;
        pi)       echo "Load on-demand instructions via /skill → ~/.pi/agent/skills/" ;;
        cursor)   echo "Flattened into .mdc rule files → .cursor/rules/" ;;
      esac ;;
    agents)
      case "$provider" in
        claude)   echo "Specialized subagents (reviewer, planner...) → ~/.claude/agents/" ;;
        opencode) echo "Specialized subagents → ~/.config/opencode/agents/" ;;
        *)        echo "Not supported by ${provider}" ;;
      esac ;;
    commands)
      case "$provider" in
        claude)   echo "Slash commands (/review, /plan...) → ~/.claude/commands/" ;;
        opencode) echo "Slash commands → ~/.config/opencode/commands/" ;;
        *)        echo "Not supported by ${provider}" ;;
      esac ;;
    hooks)
      case "$provider" in
        claude)   echo "Automatic actions on tool use → .claude/settings.json (project-level)" ;;
        *)        echo "Not supported by ${provider}" ;;
      esac ;;
    output-styles)
      case "$provider" in
        claude)   echo "Response formatting preferences → ~/.claude/output-styles/" ;;
        *)        echo "Not supported by ${provider}" ;;
      esac ;;
    mcp)
      case "$provider" in
        claude)   echo "Sentry, Linear, Context7, Chrome DevTools → .mcp.json (project-level)" ;;
        opencode) echo "Sentry, Linear, Context7, Chrome DevTools → ~/.config/opencode/opencode.json (merged, counterpart-* keys)" ;;
        *)        echo "Not supported by ${provider}" ;;
      esac ;;
  esac
}

# ── Provider detection ──────────────────────────────────────────────────────────

detect_provider() {
  local provider="$1"
  local upper
  upper=$(echo "$provider" | tr '[:lower:]' '[:upper:]')
  local path_var="PROVIDER_PATH_${upper}"
  local path="${!path_var:-}"
  [[ -n "$path" && -d "$path" ]]
}

# detect_providers — prints detected provider names, one per line
detect_providers() {
  for p in "${ALL_PROVIDERS[@]}"; do
    detect_provider "$p" && echo "$p"
  done
}

# provider_label <provider> — human label for display
provider_label() {
  case "$1" in
    claude)   echo "Claude Code" ;;
    opencode) echo "OpenCode" ;;
    pi)       echo "Pi" ;;
    cursor)   echo "Cursor" ;;
    *)        echo "$1" ;;
  esac
}
