#!/usr/bin/env bash
# bash completion for yourclaude

_yourclaude_completions() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local subcommands="setup status update reset uninstall help --help -h"
  COMPREPLY=($(compgen -W "$subcommands" -- "$cur"))
}

complete -F _yourclaude_completions yourclaude
