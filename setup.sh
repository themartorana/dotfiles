#!/usr/bin/env bash

set -e

echo "Setting up via dotfiles..."

# set local shell to zsh
sudo chsh -s "$(which zsh)" "$(whoami)"

# make local bin folder
mkdir -p ~/bin

# make private bin folder
mkdir -p ~/.local/bin

CHECKFILE="~/.dotfiles/initial-setup-done"
if [ ! -f $CHECKFILE ]; then
    # Make directories
    mkdir -p ~/bin
    mkdir -p ~/code
    cp -rv .dotfiles ~

    # Run zsh/setup.sh
    source ~/.dotfiles/zsh/setup.sh

    # Install ASDF - not by default
    # source ~/.dotfiles/asdf/setup.sh

    # VSCode settings
    source ~/.dotfiles/vscode/setup.sh

    # Make sure we don't do it again
    touch $CHECKFILE
fi



