#!/usr/bin/env bash
# install.sh — bootstrap installer for counterpart-toolbox
#
# Usage (from onboarding docs):
#   curl -fsSL https://raw.githubusercontent.com/counterpart-inc/counterpart-toolbox/main/install.sh | bash
#
# Note: cloning uses SSH (git@github.com) — ensure your SSH key is added to GitHub before running.
#
# What this script does:
#   1. Clones counterpart-toolbox to ~/.local/share/counterpart-toolbox/
#   2. Symlinks yourcounterpart → ~/.local/bin/yourcounterpart
#   3. Adds ~/.local/bin to PATH in .zshrc / .bashrc if not present
#   4. Registers shell tab completions
#   5. Runs yourcounterpart setup (first-time configuration wizard)

set -euo pipefail

REPO_URL="${REPO_URL:-git@github.com:counterpart-inc/counterpart-toolbox.git}"
INSTALL_DIR="${HOME}/.local/share/counterpart-toolbox"
BIN_DIR="${HOME}/.local/bin"
SYMLINK="${BIN_DIR}/yourcounterpart"

BOLD="\033[1m"
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

info()    { echo -e "  ${CYAN}→${RESET} $*"; }
success() { echo -e "  ${GREEN}✓${RESET} $*"; }
warn()    { echo -e "  ${YELLOW}!${RESET} $*"; }
error()   { echo -e "  ${RED}✗${RESET} $*" >&2; }

echo ""
echo -e "${BOLD}${CYAN}  yourcounterpart installer — Counterpart AI toolbox${RESET}"
echo ""

# ── 1. Clone or update ──────────────────────────────────────────────────────────
if [[ -d "${INSTALL_DIR}/.git" ]]; then
  info "counterpart-toolbox already installed. Pulling latest..."
  git -C "$INSTALL_DIR" pull origin main 2>&1 | sed 's/^/    /'
  success "Toolbox updated."
else
  info "Cloning counterpart-toolbox to ${INSTALL_DIR}..."
  git clone "$REPO_URL" "$INSTALL_DIR" 2>&1 | sed 's/^/    /'
  success "Cloned."
fi

# ── 2. Symlink yourcounterpart ───────────────────────────────────────────────────────
mkdir -p "$BIN_DIR"
if [[ -L "$SYMLINK" ]]; then
  info "Updating symlink at ${SYMLINK}..."
  rm "$SYMLINK"
fi
ln -s "${INSTALL_DIR}/yourcounterpart" "$SYMLINK"
chmod +x "${INSTALL_DIR}/yourcounterpart"
success "Symlinked: ${SYMLINK} → ${INSTALL_DIR}/yourcounterpart"

# ── 4. Add ~/.local/bin to PATH ─────────────────────────────────────────────────
add_to_path() {
  local rc_file="$1"
  if [[ -f "$rc_file" ]] && grep -qF 'local/bin' "$rc_file"; then
    return 0  # already present
  fi
  if [[ -f "$rc_file" ]]; then
    {
      echo ""
      echo "# Added by counterpart-toolbox installer"
      echo 'export PATH="${HOME}/.local/bin:${PATH}"'
    } >> "$rc_file"
    info "Added ~/.local/bin to PATH in ${rc_file}"
    return 0
  fi
  return 1
}

path_added=0
if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$(basename "${SHELL:-}")" == "zsh" ]]; then
  add_to_path "${HOME}/.zshrc" && path_added=1
fi
if [[ "$(basename "${SHELL:-}")" == "bash" ]]; then
  add_to_path "${HOME}/.bashrc" && path_added=1
  add_to_path "${HOME}/.bash_profile" && path_added=1
fi
# Fallback: try both
if [[ "$path_added" -eq 0 ]]; then
  add_to_path "${HOME}/.zshrc" || true
  add_to_path "${HOME}/.bashrc" || true
fi

# Make PATH available in current session
export PATH="${BIN_DIR}:${PATH}"

# ── 5. Register shell completions ───────────────────────────────────────────────
add_completion() {
  local rc_file="$1"
  local completion_line="$2"
  if [[ -f "$rc_file" ]] && grep -qF 'yourcounterpart' "$rc_file"; then
    return 0  # already present
  fi
  if [[ -f "$rc_file" ]]; then
    {
      echo ""
      echo "# yourcounterpart shell completion (added by counterpart-toolbox installer)"
      echo "$completion_line"
    } >> "$rc_file"
    info "Registered yourcounterpart completion in ${rc_file}"
  fi
}

DETECTED_SHELL="$(basename "${SHELL:-bash}")"

if [[ "$DETECTED_SHELL" == "zsh" ]] || [[ -n "${ZSH_VERSION:-}" ]]; then
  add_completion "${HOME}/.zshrc" "source \"${INSTALL_DIR}/completions/yourcounterpart.zsh\""
  # Only source zsh completion if actually running inside zsh
  if [[ -n "${ZSH_VERSION:-}" ]]; then
    # shellcheck disable=SC1090
    source "${INSTALL_DIR}/completions/yourcounterpart.zsh" 2>/dev/null || true
  fi
else
  add_completion "${HOME}/.bashrc" "source \"${INSTALL_DIR}/completions/yourcounterpart.bash\""
  add_completion "${HOME}/.bash_profile" "source \"${INSTALL_DIR}/completions/yourcounterpart.bash\""
  # shellcheck disable=SC1090
  source "${INSTALL_DIR}/completions/yourcounterpart.bash" 2>/dev/null || true
fi
success "Shell completions active."

# ── 6. Run first-time setup ─────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Installation complete.${RESET}"
echo ""

if [[ -n "${COUNTERPART_WORKSPACE:-}" && -d "${COUNTERPART_WORKSPACE}/.counterpart" ]]; then
  success "Existing configuration found — skipping setup wizard."
  echo ""
  echo -e "  Run ${BOLD}yourcounterpart status${RESET} to verify your environment."
else
  echo "  Running first-time setup wizard..."
  echo ""
  "${INSTALL_DIR}/yourcounterpart" setup
fi

echo ""
echo -e "${BOLD}Next steps:${RESET}"
echo ""
echo -e "  1. Reload your shell to activate tab completions:"
if [[ "$DETECTED_SHELL" == "zsh" ]] || [[ -n "${ZSH_VERSION:-}" ]]; then
  echo -e "     ${BOLD}source ~/.zshrc${RESET}"
else
  echo -e "     ${BOLD}source ~/.bashrc${RESET}"
fi
echo ""
echo -e "  2. Run Claude from your Counterpart workspace:"
echo -e "     ${BOLD}cd \${COUNTERPART_WORKSPACE:-~/projects/work/counterpart} && yourcounterpart${RESET}"
echo ""
echo -e "  3. Inside Claude, authenticate your MCP servers:"
echo -e "     ${BOLD}/mcp${RESET}"
echo ""
echo -e "  4. Check your environment at any time:"
echo -e "     ${BOLD}yourcounterpart status${RESET}"
echo ""
