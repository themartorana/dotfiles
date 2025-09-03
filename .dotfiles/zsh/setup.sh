#!/bin/bash

# Install ZSH
if test ! $(which zsh); then
    sudo apt-get update && sudo apt-get -y install zsh
fi

# loop in zshrc
# echo 'source $HOME/.dotfiles/zsh/zshrc' >> $HOME/.zshrc
if [ -f $HOME/.zshrc ]; then
    mv $HOME/.zshrc $HOME/.zshrc.bak
fi
cp $HOME/.dotfiles/zsh/zshrc $HOME/.zshrc
cp $HOME/.dotfiles/zsh/aliases $HOME/.aliases
cp $HOME/.dotfiles/zsh/zshenv $HOME/.zshenv

# Set up the .zsh_history file
touch $HOME/.zsh_history
