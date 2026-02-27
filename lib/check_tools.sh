#!/usr/bin/env bash
# check_tools.sh — verify required CLI tools are installed (macOS/brew)
#
# Reads `required_tools` from COUNTERPART_CONFIG (or a path passed as $1).
# Each entry: { "cmd": "rg", "brew": "ripgrep" }

check_tools() {
  local config_file="${1:-${COUNTERPART_CONFIG:-}}"

  if [[ -z "$config_file" || ! -f "$config_file" ]]; then
    echo "  [!] check_tools: no config file found — skipping."
    return 0
  fi

  local tool_count
  tool_count=$(jq '.required_tools | length' "$config_file" 2>/dev/null)
  if [[ -z "$tool_count" || "$tool_count" -eq 0 ]]; then
    return 0
  fi

  local brew_missing=()

  while IFS=$'\t' read -r cmd brew_pkg; do
    [[ -z "$cmd" ]] && continue
    if ! command -v "$cmd" &>/dev/null; then
      echo "  [!] '$cmd' is not installed."
      brew_missing+=("${brew_pkg:-$cmd}")
    fi
  done < <(jq -r '.required_tools[]? | "\(.cmd)\t\(.brew // .cmd)"' "$config_file" 2>/dev/null)

  if [[ ${#brew_missing[@]} -gt 0 ]]; then
    echo ""
    echo "    brew install ${brew_missing[*]}"
    printf "  Install now with brew? [Y/n] "
    read -r answer </dev/tty
    answer="${answer:-Y}"
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      brew install "${brew_missing[@]}" 2>&1 | sed 's/^/    /'
      echo "  [✓] Tools installed."
    fi
    echo ""
  else
    local tool_list
    tool_list=$(jq -r '[.required_tools[]?.cmd] | join(", ")' "$config_file" 2>/dev/null)
    echo "  [✓] Required tools present (${tool_list})."
  fi
}
