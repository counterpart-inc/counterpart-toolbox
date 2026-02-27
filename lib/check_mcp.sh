#!/usr/bin/env bash
# check_mcp.sh — ping each MCP server URL from config and warn if unreachable

# Reads from COUNTERPART_CONFIG (set by yourclaude main script)

check_mcp_servers() {
  local mcp_count
  mcp_count=$(jq -r '.mcp_servers | length' "$COUNTERPART_CONFIG" 2>/dev/null || echo "0")

  if [[ "$mcp_count" -eq 0 ]]; then
    echo "  [✓] No MCP servers configured."
    return 0
  fi

  local any_unreachable=0
  local any_auth_needed=0

  echo "  Checking MCP servers (this may take a moment)..."

  while IFS="=" read -r name url; do
    if [[ -z "$url" || "$url" == "null" ]]; then
      continue
    fi

    local http_code
    http_code=$(curl -o /dev/null -s --max-time 3 -w "%{http_code}" --head "$url" 2>/dev/null)
    http_code="${http_code:-000}"

    # SSE/streaming endpoints often return 405 to HEAD — try GET for reachability
    if [[ "$http_code" == "000" || "$http_code" == "405" ]]; then
      http_code=$(curl -o /dev/null -s --max-time 3 -w "%{http_code}" \
        -H "Accept: text/event-stream" \
        "$url" 2>/dev/null)
      http_code="${http_code:-000}"
    fi

    if [[ "$http_code" == "000" ]]; then
      echo "  [!] '$name' MCP server is not responding ($url)."
      printf "      Continue anyway? [y/N] "
      read -r answer </dev/tty
      answer="${answer:-N}"
      if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo "      Aborting. Check your network or MCP server status."
        return 1
      fi
      any_unreachable=1
    elif [[ "$http_code" == "401" ]]; then
      echo "  [!] '$name' MCP requires authentication."
      any_auth_needed=1
    else
      echo "  [✓] '$name' MCP server reachable."
    fi
  done < <(jq -r '.mcp_servers | to_entries[] | "\(.key)=\(.value)"' "$COUNTERPART_CONFIG" 2>/dev/null)

  if [[ "$any_auth_needed" -eq 1 ]]; then
    echo ""
    echo "  Some MCP servers need authentication."
    echo "  Inside a Claude session, run: /mcp"
  fi

  if [[ "$any_unreachable" -eq 1 ]]; then
    echo "  [!] Some MCP servers are unreachable — continuing with degraded MCP support."
  fi

  return 0
}
