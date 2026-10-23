#!/usr/bin/env bash
set -e

# The clone this script lives in (also set by setup.sh when it sources us)
DOTFILES="$(CDPATH='' cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
source "$DOTFILES/dotfiles/utilities.sh"

link "$DOTFILES"/dotfiles/bash/bash_profile ~/.bash_profile
seed_local "$DOTFILES"/dotfiles/bash/bash_profile.local ~/.bash_profile.local

link "$DOTFILES"/dotfiles/bash/bashrc ~/.bashrc
seed_local "$DOTFILES"/dotfiles/bash/bashrc.local ~/.bashrc.local

# Set up the .bash_history file
[ -f ~/.bash_history ] || touch ~/.bash_history
