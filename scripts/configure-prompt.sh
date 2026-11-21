#!/bin/bash
# Explicit, backup-first Zsh prompt installer; compatible with macOS Bash 3.2.
set -euo pipefail

usage() {
  printf 'Usage: bash scripts/configure-prompt.sh [--apply]\n'
}
case "${1:-}" in
  '') ;;
  --apply) ;;
  --help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac
[[ $# -le 1 ]] || exit 2
[[ "$(id -u)" -ne 0 ]] || { echo 'Do not run as root.' >&2; exit 1; }
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_file="$script_dir/../dotfiles/zsh/prompt.zsh"
shell_file="${ZDOTDIR:-$HOME}/.zshrc"
dest_dir="$HOME/.config/dev-workstation"
dest_file="$dest_dir/prompt.zsh"
marker='# dev-workstation prompt (managed)'
source_line='[[ -f "$HOME/.config/dev-workstation/prompt.zsh" ]] && source "$HOME/.config/dev-workstation/prompt.zsh"'

[[ -f "$source_file" ]] || { echo 'Missing source prompt file.' >&2; exit 1; }
[[ ! -L "$shell_file" && ! -L "$dest_dir" && ! -L "$dest_file" ]] || {
  echo 'Symlink detected; review paths manually before applying.' >&2
  exit 1
}
if [[ -e "$shell_file" ]]; then
  if grep -Eq 'agnoster-timestamp|command-timer[.]zsh' "$shell_file"; then
    echo 'Legacy timestamp theme or timer detected in .zshrc.'
    echo 'First remove its source line and set ZSH_THEME="agnoster" using vim.'
    echo 'Preserve legacy files until verification. No files changed.'
    exit 1
  fi
  if ! grep -q 'oh-my-zsh.sh' "$shell_file"; then
    echo 'Missing Oh My Zsh setup; configure it before using this installer.'
    exit 1
  fi
  if ! grep -Eq 'ZSH_THEME=["\x27]agnoster["\x27]' "$shell_file"; then
    echo 'Set ZSH_THEME="agnoster" in .zshrc before installing.'
    exit 1
  fi
else
  echo 'No .zshrc found; configure Oh My Zsh first.'
  exit 1
fi
if grep -Fq "$marker" "$shell_file" && ! grep -Fq "$source_line" "$shell_file"; then
  echo 'Existing managed marker differs from expected state; manual review required.'
  exit 1
fi
if grep -Fq "$source_line" "$shell_file" && ! grep -Fq "$marker" "$shell_file"; then
  echo 'Existing source line without managed marker; manual review required.'
  exit 1
fi
if [[ "${1:-}" != --apply ]]; then
  printf 'Preview only; no changes made.\nSource: %s\nInstall: %s\nIntegration: %s\n' "$source_file" "$dest_file" "$shell_file"
  printf 'Run bash scripts/configure-prompt.sh --apply to consent to modifications.\n'
  exit 0
fi

# Back up and verify each existing file before changes.
backup_file() {
  local path="$1" backup
  if [[ -f "$path" ]]; then
    backup="$(mktemp "${path}.backup.XXXXXX")"
    cp -p "$path" "$backup"
    if ! cmp -s "$path" "$backup"; then
      echo "Backup verification failed: $path" >&2
      exit 1
    fi
    printf 'Verified backup: %s\n' "$backup"
  fi
}
mkdir -p "$dest_dir"
if [[ ! -f "$dest_file" ]] || ! cmp -s "$source_file" "$dest_file"; then
  backup_file "$dest_file"
  cp "$source_file" "$dest_file"
  chmod 644 "$dest_file"
fi
if ! grep -Fq "$marker" "$shell_file"; then
  backup_file "$shell_file"
  {
    printf '\n%s\n' "$marker"
    printf '%s\n' "$source_line"
  } >> "$shell_file"
fi
printf 'Configured successfully. Open a new terminal or run: exec zsh\n'
