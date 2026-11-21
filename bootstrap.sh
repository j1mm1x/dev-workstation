#!/bin/bash
set -euo pipefail
case "${1:-}" in
  ''|--apply|--configure-shell|--check-containers) ;;
  --help) echo 'Usage: ./bootstrap.sh [--apply|--configure-shell|--check-containers]'; exit 0 ;;
  *) echo 'Usage: ./bootstrap.sh [--apply|--configure-shell|--check-containers]' >&2; exit 2 ;;
esac
[[ $# -le 1 ]] || exit 2
[[ "$(id -u)" != 0 ]] || { echo 'Run as an ordinary user' >&2; exit 1; }
[[ "$(uname -s)/$(uname -m)" == Darwin/arm64 ]] || {
  echo 'This bootstrap requires native Apple Silicon macOS.' >&2
  exit 1
}
if [[ "${1:-}" == --check-containers ]]; then
  if command -v docker >/dev/null; then
    if docker_context=$(docker context show 2>/dev/null); then
      printf 'Docker context: %s\n' "$docker_context"
    else
      echo 'Docker context: unavailable'
    fi
    if [[ -n ${DOCKER_HOST:-} && -z ${DOCKER_CONTEXT:-} ]]; then
      echo 'Docker endpoint: overridden by DOCKER_HOST'
    fi
    if docker info --format '{{.ServerVersion}}' >/dev/null 2>&1; then
      echo 'Docker engine: reachable'
    else
      echo 'Docker engine: unreachable'
    fi
  else
    echo 'Docker CLI: missing'
  fi

  if ! command -v colima >/dev/null; then
    echo 'Colima: missing'
  elif [[ ! -d "${COLIMA_HOME:-$HOME/.colima}/default" ]]; then
    echo 'Colima (default profile): not configured'
  elif colima status --profile default >/dev/null 2>&1; then
    echo 'Colima (default profile): running'
  else
    echo 'Colima (default profile): not running or status unavailable'
  fi
  exit 0
fi
if [[ "${1:-}" == --configure-shell ]]; then
  shell_file="${ZDOTDIR:-$HOME}/.zshrc"
  [[ ! -L "$shell_file" ]] || { echo 'Review the existing .zshrc symlink manually.' >&2; exit 1; }
  [[ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]] || { echo 'Run --apply first.' >&2; exit 1; }
  if [[ -f "$shell_file" ]] && /usr/bin/grep -q 'oh-my-zsh.sh' "$shell_file"; then
    echo 'Existing Oh My Zsh configuration found. Set ZSH_THEME="agnoster" in your .zshrc.'
    exit 1
  fi
  if [[ -e "$shell_file" ]]; then
    backup=$(mktemp "${shell_file}.backup.XXXXXX")
    cp -p "$shell_file" "$backup"
    cmp -s "$shell_file" "$backup"
    printf 'Backup saved to %s\n' "$backup"
  fi
  cat >> "$shell_file" <<'SHELL_CONFIG'

# dev-workstation terminal configuration
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
plugins=(git)
source "$ZSH/oh-my-zsh.sh"
SHELL_CONFIG
  echo 'Agnoster configured. Open a new terminal session.'
  exit 0
fi
printf '%s\n' 'Workstation package plan: kubectl, docker (CLI), colima, devbox, fzf.'
if [[ "${1:-}" != --apply ]]; then
  echo 'Run ./bootstrap.sh --apply to install these tools with Homebrew setup if needed.'
  echo 'Oh My Zsh with Agnoster requires a separate shell configuration step.'
  exit 0
fi
brew_bin=$(command -v brew || true)
if [[ -z "$brew_bin" && -x /opt/homebrew/bin/brew ]]; then
  brew_bin=/opt/homebrew/bin/brew
fi
if [[ -z "$brew_bin" ]]; then
  echo 'Homebrew installation may request administrator access and install Command Line Tools.'
  read -r -p 'Install Homebrew using its official installer? [y/N] ' consent
  [[ "$consent" == y || "$consent" == Y ]] || exit 1
  installer=$(mktemp)
  trap 'rm -f "$installer"' EXIT
  curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer"
  /bin/bash "$installer"
  rm -f "$installer"
  trap - EXIT
  brew_bin=/opt/homebrew/bin/brew
  [[ -x "$brew_bin" ]] || { echo 'Homebrew installation did not complete.' >&2; exit 1; }
fi
eval "$("$brew_bin" shellenv)"
"$brew_bin" install kubectl docker colima fzf
if ! command -v devbox >/dev/null; then
  echo 'Devbox uses the official Jetify installer, which may request administrator access.'
  read -r -p 'Run the official Devbox installer? [y/N] ' consent
  [[ "$consent" == y || "$consent" == Y ]] || exit 1
  installer=$(mktemp)
  trap 'rm -f "$installer"' EXIT
  curl -fsSL https://get.jetify.com/devbox -o "$installer"
  /bin/bash "$installer"
  rm -f "$installer"
  trap - EXIT
fi
if [[ ! -e "$HOME/.oh-my-zsh" && ! -L "$HOME/.oh-my-zsh" ]]; then
  omz_stage=$(mktemp -d "$HOME/.oh-my-zsh-install.XXXXXX")
  trap 'rm -rf "$omz_stage"' EXIT
  git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$omz_stage"
  mv "$omz_stage" "$HOME/.oh-my-zsh"
  trap - EXIT
fi
[[ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]] || {
  echo 'Existing .oh-my-zsh directory requires manual review.' >&2; exit 1;
}
echo 'Tools and Oh My Zsh available. Run --configure-shell to back up .zshrc and add Agnoster.' 
echo 'Devbox may require a separately approved Nix installation on first use.'
