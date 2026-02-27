#!/usr/bin/env bash
# check_plugins.sh — verify marketplace registration and required plugin installs

# Reads from COUNTERPART_CONFIG (set by yourclaude main script)

check_marketplace() {
  local marketplace
  marketplace=$(jq -r '.marketplace // empty' "$COUNTERPART_CONFIG" 2>/dev/null)

  if [[ -z "$marketplace" ]]; then
    echo "  [!] No marketplace URL configured in config.json — skipping marketplace check."
    return 0
  fi

  # Check if marketplace is already registered by looking at claude plugin list output
  local registered
  registered=$(claude plugin marketplace list 2>/dev/null | grep -F "$marketplace" || true)

  if [[ -z "$registered" ]]; then
    echo "  [!] Counterpart plugin marketplace is not registered."
    printf "      Register it now? [Y/n] "
    read -r answer </dev/tty
    answer="${answer:-Y}"
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      echo "      Registering marketplace..."
      if claude plugin marketplace add "$marketplace" 2>&1; then
        echo "      [✓] Marketplace registered."
      else
        echo "      [✗] Failed to register marketplace. Continuing..."
      fi
    else
      echo "      Skipped marketplace registration."
    fi
  else
    echo "  [✓] Plugin marketplace registered."
  fi
}

check_plugins() {
  local required_plugins
  mapfile -t required_plugins < <(jq -r '.required_plugins[]? // empty' "$COUNTERPART_CONFIG" 2>/dev/null)

  if [[ ${#required_plugins[@]} -eq 0 ]]; then
    echo "  [✓] No required plugins configured."
    return 0
  fi

  local installed_output
  installed_output=$(claude plugin list 2>/dev/null || echo "")

  for plugin in "${required_plugins[@]}"; do
    if echo "$installed_output" | grep -qF "$plugin"; then
      echo "  [✓] Plugin '$plugin' installed."
    else
      echo "  [!] Plugin '$plugin' is not installed."
      printf "      Install '$plugin' now? [Y/n] "
      read -r answer </dev/tty
      answer="${answer:-Y}"
      if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "      Installing '$plugin'..."
        if claude plugin install "$plugin" 2>&1; then
          echo "      [✓] '$plugin' installed."
        else
          echo "      [✗] Failed to install '$plugin'. Continuing..."
        fi
      else
        echo "      Skipped installing '$plugin'."
      fi
    fi
  done
}
