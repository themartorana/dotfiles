#!/usr/bin/env bash
set -e

source "$HOME/.dotfiles/dotfiles/utilities.sh"

link ~/.dotfiles/dotfiles/bash/bash_profile ~/.bash_profile
seed_local ~/.dotfiles/dotfiles/bash/bash_profile.local ~/.bash_profile.local

link ~/.dotfiles/dotfiles/bash/bashrc ~/.bashrc
seed_local ~/.dotfiles/dotfiles/bash/bashrc.local ~/.bashrc.local

# Set up the .bash_history file
[ -f ~/.bash_history ] || touch ~/.bash_history
