#!/bin/sh
# Links mac dotfiles in this repo into your home folder. Safe to run again:
# good links are left alone, and broken links are recreated.
# A normal file matching the repo is backed up as <file>.bak.<timestamp>, then
# linked. A file that differs from the repo is never touched.
#
# Usage: ./link-dotfiles.sh
#
# Repairing a dotfile symlink:
# ~/.zshrc, ~/.hyper.js, ~/.config/starship.toml, ~/.config/mise/config.toml
# and ~/.config/bat/config are symlinks into this repo.
# A tool that saves through a temp file and rename (like `sed -i`) can replace
# the link with a normal file. If `ls -l ~/.zshrc` shows no `->` arrow, run this
# script. If it reports that the file differs and you want to keep the tool's
# edit, copy it into the repo, run this script again, and review with `git diff`:
#
#   cp ~/.zshrc ~/This/repo/path/dot-files/mac/.zshrc
#   ./link-dotfiles.sh

set -eu

if [ "$(uname -s)" != "Darwin" ]; then
  echo "error: these links are for macOS" >&2
  exit 1
fi

repo=$(cd "$(dirname "$0")" && pwd -P)
problems=0

link() {
  target="$repo/$1"
  path="$HOME/$2"

  if [ ! -f "$target" ]; then
    echo "SKIP  ~/$2: $target is missing"
    problems=1
    return
  fi

  if [ -L "$path" ]; then
    if [ "$(readlink "$path")" = "$target" ]; then
      echo "OK    ~/$2"
      return
    fi
    if [ -e "$path" ]; then
      echo "SKIP  ~/$2: already links to $(readlink "$path")"
      problems=1
      return
    fi
    rm "$path" # Broken link, so there's no content to lose.
  elif [ -e "$path" ]; then
    if ! cmp -s "$path" "$target"; then
      echo "SKIP  ~/$2: differs from the repo. Compare with:"
      echo "        diff \"$path\" \"$target\""
      echo "      Keep the home version: cp \"$path\" \"$target\""
      echo "      Keep the repo version: mv \"$path\" \"$path.bak\""
      echo "      Then run this script again."
      problems=1
      return
    fi
    mv "$path" "$path.bak.$(date +%Y%m%d%H%M%S)"
  fi

  mkdir -p "$(dirname "$path")"
  ln -s "$target" "$path"
  echo "LINK  ~/$2"
}

link mac/.zshrc .zshrc
link mac/.hyper.js .hyper.js
link mac/starship.toml .config/starship.toml
link mac/mise/config.toml .config/mise/config.toml
link mac/bat/config .config/bat/config

exit "$problems"
