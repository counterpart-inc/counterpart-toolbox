#compdef yourclaude
# zsh completion for yourclaude

_yourclaude() {
  local -a subcommands
  subcommands=(
    'setup:Run the first-time setup wizard'
    'status:Show health check results without launching Claude'
    'update:Self-update toolbox, plugins submodule, and re-install plugins'
    'reset:Clear configuration and start fresh'
    'uninstall:Remove yourclaude, plugins, and marketplaces from this machine'
    'help:Show usage information'
    '--help:Show usage information'
    '-h:Show usage information'
  )

  if (( CURRENT == 2 )); then
    _describe 'subcommand' subcommands
  fi
}

_yourclaude "$@"
