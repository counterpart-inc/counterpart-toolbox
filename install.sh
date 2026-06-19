#!/usr/bin/env bash
# install.sh — Counterpart AI toolbox installer
#
# Usage (one-time):
#   curl -fsSL https://raw.githubusercontent.com/counterpart-inc/counterpart-toolbox/main/install.sh | bash
#
# What it does:
#   1. Clones counterpart-toolbox to ~/.local/share/counterpart-toolbox
#   2. Symlinks `counterpart` into ~/.local/bin/
#   3. Adds update-check hook to ~/.zshrc (or ~/.bashrc)

set -euo pipefail

REPO="git@github.com:counterpart-inc/counterpart-toolbox.git"
INSTALL_DIR="${HOME}/.local/share/counterpart-toolbox"
BIN_DIR="${HOME}/.local/bin"
BOLD="\033[1m"; RESET="\033[0m"; CYAN="\033[36m"; GREEN="\033[32m"; YELLOW="\033[33m"

echo ""
echo -e "${BOLD}${CYAN}  counterpart-toolbox installer${RESET}"
echo ""

# ── 1. Clone or update ──────────────────────────────────────────────────────────

if [[ -d "${INSTALL_DIR}/.git" ]]; then
  echo "  Updating existing installation..."
  git -C "$INSTALL_DIR" pull origin main --quiet
  echo -e "  ${GREEN}[✓]${RESET} Updated"
else
  echo "  Cloning counterpart-toolbox..."
  git clone --depth 1 "$REPO" "$INSTALL_DIR" 2>&1 | sed 's/^/  /'
  echo -e "  ${GREEN}[✓]${RESET} Cloned to ${INSTALL_DIR}"
fi
echo ""

# ── 2. Symlink binary ───────────────────────────────────────────────────────────

mkdir -p "$BIN_DIR"
ln -sf "${INSTALL_DIR}/counterpart" "${BIN_DIR}/counterpart"
chmod +x "${INSTALL_DIR}/counterpart"
echo -e "  ${GREEN}[✓]${RESET} Symlinked: ${BIN_DIR}/counterpart"
echo ""

# ── 3. Add PATH + update-check hook to shell rc ─────────────────────────────────

_add_to_rc() {
  local rc="$1"
  [[ -f "$rc" ]] || return 0

  if grep -qF "# >>> counterpart-toolbox" "$rc" 2>/dev/null; then
    echo -e "  ${YELLOW}[→]${RESET} Already installed in ${rc}"
    return 0
  fi

  cat >> "$rc" << 'SHELL_HOOK'

# >>> counterpart-toolbox
export PATH="${HOME}/.local/bin:${PATH}"
_CT_TOOLBOX="${HOME}/.local/share/counterpart-toolbox"
if [[ -f "${_CT_TOOLBOX}/lib/update-check.sh" ]]; then
  source "${_CT_TOOLBOX}/lib/update-check.sh"
  _ct_update_check 2>/dev/null || true
fi
unset _CT_TOOLBOX
# <<< counterpart-toolbox
SHELL_HOOK

  echo -e "  ${GREEN}[✓]${RESET} Added hook to ${rc}"
}

_add_to_rc "${HOME}/.zshrc"
_add_to_rc "${HOME}/.bashrc"
echo ""

# ── Done ────────────────────────────────────────────────────────────────────────

echo -e "${BOLD}  Installation complete.${RESET}"
echo ""
echo "  Reload your shell or run:"
echo -e "  ${BOLD}  source ~/.zshrc${RESET}"
echo ""
echo "  Then run:"
echo -e "  ${BOLD}  counterpart sync${RESET}"
echo ""
