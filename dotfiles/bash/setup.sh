#!/usr/bin/env bash
set -e

# copy .bash_profile
[ -f ~/.bash_profile ] && mv ~/.bash_profile ~/.bash_profile.bak
ln -s ~/.dotfiles/dotfiles/bash/bash_profile ~/.bash_profile

# copy .bashrc
[ -f ~/.bashrc ] && mv ~/.bashrc ~/.bashrc.bak
ln -s ~/.dotfiles/dotfiles/bash/bashrc ~/.bashrc
[ ! -f ~/.bashrc.local ] && ln -s ~/.dotfiles/dotfiles/bash/bashrc.local ~/.bashrc.local

# Set up the .bash_history file
[ -f ~/.bash_history ] || touch ~/.bash_history

# Add aliases sourcing to .profile
if ! grep -q "source \$HOME/.aliases" ~/.profile 2>/dev/null; then
    echo "[ -f \$HOME/.aliases ] && source \$HOME/.aliases" >> ~/.profile
fi
