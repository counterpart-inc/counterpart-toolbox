#!/usr/bin/env bash
# bash completion for yourcounterpart

_yourcounterpart_completions() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local subcommands="setup status update reset uninstall help --help -h"
  COMPREPLY=($(compgen -W "$subcommands" -- "$cur"))
}

complete -F _yourcounterpart_completions yourcounterpart
