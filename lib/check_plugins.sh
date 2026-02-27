#!/usr/bin/env bash
# check_plugins.sh — verify marketplace registration and required plugin installs

# Reads from COUNTERPART_CONFIG (set by yourclaude main script)

check_marketplace() {
  local registered_list
  registered_list=$(claude plugin marketplace list 2>/dev/null || true)

  local marketplaces=()
  while IFS= read -r mp; do
    [[ -n "$mp" ]] && marketplaces+=("$mp")
  done < <(jq -r '.marketplaces[]? // .marketplace // empty' "$COUNTERPART_CONFIG" 2>/dev/null)

  if [[ ${#marketplaces[@]} -eq 0 ]]; then
    echo "  [!] No marketplaces configured in config.json — skipping."
    return 0
  fi

  for marketplace in "${marketplaces[@]}"; do
    local registered
    registered=$(echo "$registered_list" | grep -F "$marketplace" || true)

    if [[ -z "$registered" ]]; then
      echo "  [!] Marketplace not registered: $marketplace"
      printf "      Register it now? [Y/n] "
      read -r answer </dev/tty
      answer="${answer:-Y}"
      if [[ "$answer" =~ ^[Yy]$ ]]; then
        if claude plugin marketplace add "$marketplace" 2>&1; then
          echo "      [✓] Marketplace registered."
        else
          echo "      [✗] Failed to register marketplace. Continuing..."
        fi
      else
        echo "      Skipped."
      fi
    else
      echo "  [✓] Marketplace registered: $(basename "$marketplace")"
    fi
  done
}

check_plugins() {
  local required_plugins=()
  while IFS= read -r plugin; do
    [[ -n "$plugin" ]] && required_plugins+=("$plugin")
  done < <(jq -r '.required_plugins[]? // empty' "$COUNTERPART_CONFIG" 2>/dev/null)

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
