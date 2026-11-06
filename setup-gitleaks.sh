#!/bin/sh
# Installs gitleaks if it's missing, then adds a pre-commit hook to one repo.
# An existing, different pre-commit hook is never overwritten.
#
# Usage: ./setup-gitleaks.sh [repo-path]   (defaults to the current directory)

set -eu

HOOK_BODY='#!/bin/sh
exec gitleaks git --pre-commit --staged --redact --no-banner .'

fail() {
  echo "error: $1" >&2
  exit 1
}

install_gitleaks() {
  if command -v brew >/dev/null 2>&1; then
    brew install gitleaks
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm gitleaks
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y gitleaks
  else
    fail "no supported package manager found (brew, pacman, apt-get). See https://github.com/gitleaks/gitleaks#installing"
  fi
}

# Check the repo first so nothing gets installed for a bad path.
repo=$(git -C "${1:-.}" rev-parse --show-toplevel 2>/dev/null) ||
  fail "not a git repository: ${1:-.}"
cd "$repo"

if command -v gitleaks >/dev/null 2>&1; then
  echo "gitleaks is already installed: $(gitleaks version)"
else
  echo "gitleaks not found, installing..."
  install_gitleaks
  command -v gitleaks >/dev/null 2>&1 ||
    fail "gitleaks was installed but isn't on your PATH. Open a new shell and run this again."
fi

# Respects core.hooksPath if this repo sets one.
hooks_dir=$(git rev-parse --git-path hooks)
hook="$hooks_dir/pre-commit"

if [ -e "$hook" ]; then
  if [ "$(cat "$hook")" = "$HOOK_BODY" ]; then
    chmod +x "$hook"
    echo "Hook already installed: $repo/$hook"
    exit 0
  fi
  fail "$repo/$hook already exists with different content. Add this line to it manually:
  gitleaks git --pre-commit --staged --redact --no-banner ."
fi

mkdir -p "$hooks_dir"
printf '%s\n' "$HOOK_BODY" >"$hook"
chmod +x "$hook"
echo "Hook installed: $repo/$hook"
