#!/bin/bash

set -e

echo "Setting up via dotfiles..."

CHECKFILE="$HOME/.dotfiles/initial-setup-done"
if [ ! -f $CHECKFILE ]; then
    # Make directories
    mkdir -p $HOME/bin
    mkdir -p $HOME/code
    cp -rv .dotfiles $HOME

    # Run zsh/setup.sh
    source $HOME/.dotfiles/zsh/setup.sh

    # Run fzf/setup.sh
    source $HOME/.dotfiles/fzf/setup.sh

    # Install antidote
    source $HOME/.dotfiles/antidote/setup.sh

    # Install ASDF - not by default
    # source $HOME/.dotfiles/asdf/setup.sh

    # VSCode settings
    source $HOME/.dotfiles/vscode/setup.sh

    # Install claude
    source $HOME/.dotfiles/claude/setup.sh

    # Make sure we don't do it again
    touch $CHECKFILE
fi

# Change shell if need be
if [[ ! "$SHELL" == *"zsh"* ]]; then
    echo "Changing shell to ZSH..."
    sudo chsh -s $(which zsh) $(whoami) # https://askubuntu.com/a/1325754
fi


