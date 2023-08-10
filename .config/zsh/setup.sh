#!/bin/sh

# Install ZSH
if test ! $(which zsh); then
    sudo apt-get update && sudo apt-get install zsh
fi

# loop in zshrc
echo 'source $HOME/.config/zsh/zshrc' >> $HOME/.zshrc

# Set up the .zsh_history file
touch $HOME/.zsh_history