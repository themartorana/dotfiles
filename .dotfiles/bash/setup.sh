#!/usr/bin/env bash
set -e

# copy .bash_profile
[ -f ~/.bash_profile ] && cp ~/.bash_profile ~/.bash_profile.bak
cp ~/.dotfiles/bash/bash_profile ~/.bash_profile

# copy .bashrc
[ -f ~/.bashrc ] && cp ~/.bashrc ~/.bashrc.bak
cp ~/.dotfiles/bash/bashrc ~/.bashrc

# copy .aliases
[ -f ~/.aliases ] && cp ~/.aliases ~/.aliases.bak
cp ~/.dotfiles/aliases ~/.aliases

# Set up the .bash_history file
[ -f ~/.bash_history ] || touch ~/.bash_history

