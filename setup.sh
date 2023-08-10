#!/bin/bash

echo "Setting up via dotfiles..."

CHECKFILE="$HOME/.config/initial-setup-done"
if [ ! -f $CHECKFILE ]; then
    echo "Initial setup already done"
    exit 0
fi

# Make directories
mkdir -p $HOME/bin
mkdir -p $HOME/code
mkdir -p $HOME/.config
cp -v .config/* $HOME/.config

# Run zsh/setup.sh
source $HOME/.config/zsh/setup.sh

# Run fzf/setup.sh
source $HOME/.config/fzf/setup.sh

# Install antibody
source $HOME/.config/antibody/setup.sh

# Change shell
ZSH=$(which zsh)
chsh -s $ZSH

# Make sure we don't do it again
touch $CHECKFILE