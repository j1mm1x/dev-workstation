# dev-workstation: Agnoster-independent command timing and prompt timestamp.
# Source once AFTER oh-my-zsh.sh, from an interactive Zsh shell only.
[[ -o interactive ]] || return 0
[[ -n "${DEV_WORKSTATION_PROMPT_LOADED:-}" ]] && return 0
typeset -g DEV_WORKSTATION_PROMPT_LOADED=1

zmodload zsh/datetime || return 1
autoload -Uz add-zsh-hook

typeset -g DEV_WORKSTATION_STARTED=''
typeset -g DEV_WORKSTATION_BASE_PROMPT=''
typeset -g DEV_WORKSTATION_LAST_PROMPT=''
typeset -g DEV_WORKSTATION_DATE_PREFIX='%D{%Y-%m-%d %H:%M:%S} '

dev_workstation_preexec() {
  DEV_WORKSTATION_STARTED=$EPOCHREALTIME
}

dev_workstation_precmd() {
  local previous_status=$?
  local -F 3 elapsed
  local duration=''
  if [[ -n $DEV_WORKSTATION_STARTED ]]; then
    elapsed=$(( EPOCHREALTIME - DEV_WORKSTATION_STARTED ))
    if (( elapsed >= 1 )); then
      if (( elapsed >= 60 )); then
        local minutes=$(( int(elapsed / 60) ))
        local -F 3 seconds
        seconds=$(( elapsed - minutes * 60 ))
        duration="⏱ ${minutes}m ${seconds}s"
      else
        duration="⏱ ${elapsed}s"
      fi
    fi
    DEV_WORKSTATION_STARTED=''
  fi

  # Restore our previous prefix if the theme has not rebuilt the prompt.
  # When Agnoster rebuilds it, preserve its new status, context, and git segments.
  if [[ $PROMPT == "$DEV_WORKSTATION_LAST_PROMPT" ]]; then
    PROMPT=$DEV_WORKSTATION_BASE_PROMPT
  fi
  DEV_WORKSTATION_BASE_PROMPT=$PROMPT
  PROMPT="${DEV_WORKSTATION_DATE_PREFIX}${PROMPT}"
  DEV_WORKSTATION_LAST_PROMPT=$PROMPT

  # Preserve other right-side prompt customization when no timer is needed.
  RPROMPT=$duration
  return $previous_status
}

add-zsh-hook preexec dev_workstation_preexec
add-zsh-hook precmd dev_workstation_precmd

# Command start timestamp and duration are stored by native Zsh history.
setopt EXTENDED_HISTORY
