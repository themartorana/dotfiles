#!/usr/bin/env bash
set -e

# The clone this script lives in (also set by setup.sh when it sources us)
DOTFILES="$(CDPATH='' cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
source "$DOTFILES/dotfiles/utilities.sh"

# Shell-agnostic files
link "$DOTFILES"/dotfiles/localfiles/profile ~/.profile
seed_local "$DOTFILES"/dotfiles/localfiles/profile.local ~/.profile.local

link "$DOTFILES"/dotfiles/localfiles/aliases ~/.aliases
seed_local "$DOTFILES"/dotfiles/localfiles/aliases.local ~/.aliases.local

link "$DOTFILES"/dotfiles/localfiles/CLAUDE.md ~/.claude/CLAUDE.md
