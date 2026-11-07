#!/bin/sh
# Installs oh-my-zsh and the plugins listed in mac/.zshrc. Safe to run again:
# anything already installed is left alone, and ~/.zshrc is never touched.
#
# Usage: ./setup-shell.sh
#
# On a new Mac, run it before ./link-dotfiles.sh, so the linked .zshrc finds
# everything it loads.

set -eu

omz="$HOME/.oh-my-zsh"
plugins="$omz/custom/plugins"

if ! command -v git >/dev/null 2>&1; then
  echo "error: git is required" >&2
  exit 1
fi

clone() {
  repo=$1
  path=$2

  if [ -e "$path" ]; then
    echo "OK    ${path#"$HOME"/}"
    return
  fi

  git clone --quiet --depth 1 "https://github.com/$repo.git" "$path"
  echo "CLONE ${path#"$HOME"/}"
}

clone ohmyzsh/ohmyzsh "$omz"
clone zsh-users/zsh-syntax-highlighting "$plugins/zsh-syntax-highlighting"
clone zsh-users/zsh-autosuggestions "$plugins/zsh-autosuggestions"
clone djui/alias-tips "$plugins/alias-tips"
