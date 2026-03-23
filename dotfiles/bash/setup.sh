#!/usr/bin/env bash
set -e

source "$HOME/.dotfiles/dotfiles/utilities.sh"

# copy .bash_profile
backup_or_rm_symlink "$HOME/.bash_profile"
ln -s ~/.dotfiles/dotfiles/bash/bash_profile ~/.bash_profile
[ ! -f ~/.bash_profile.local ] && cp ~/.dotfiles/dotfiles/bash/bash_profile.local ~/.bash_profile.local

# copy .bashrc
backup_or_rm_symlink "$HOME/.bashrc"
ln -s ~/.dotfiles/dotfiles/bash/bashrc ~/.bashrc
[ ! -f ~/.bashrc.local ] && cp ~/.dotfiles/dotfiles/bash/bashrc.local ~/.bashrc.local

# Set up the .bash_history file
[ -f ~/.bash_history ] || touch ~/.bash_history

