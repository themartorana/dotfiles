#!/usr/bin/env bash

set -e

echo "Setting up via dotfiles..."

CHECKFILE="$HOME/.dotfiles/initial-setup-done"
if [ ! -f "$CHECKFILE" ]; then
    # Make directories
    mkdir -p ~/bin
    mkdir -p ~/code
    mkdir -p ~/.config
    mkdir -p ~/.local/bin

    # Check to see if we're already in ~/.dotfiles or a subdirectory
    if [[ "$PWD" == "$HOME/.dotfiles"* ]]; then
        echo "Already in ~/.dotfiles, skipping copy step"
    else
        echo "Copying dotfiles to ~/.dotfiles..."
        # Copy dotfiles, including hidden files
        mkdir -p ~/.dotfiles
        cp -rv . ~/.dotfiles
    fi

    # Copy .profile 
    [[ -f "$HOME/.profile" ]] && mv "$HOME/.profile" "$HOME/.profile.bak"
    ln -s "$HOME/.dotfiles/dotfiles/localfiles/profile" "$HOME/.profile"
    [ ! -f ~/.profile.local ] && cp ~/.dotfiles/dotfiles/localfiles/profile.local ~/.profile.local

    # copy .aliases
    [ -f ~/.aliases ] && mv ~/.aliases ~/.aliases.bak
    ln -s ~/.dotfiles/dotfiles/localfiles/aliases ~/.aliases
    [ ! -f ~/.aliases.local ] && cp ~/.dotfiles/dotfiles/localfiles/aliases.local ~/.aliases.local

    # Use your $SHELL to determine which setup script to run,
    # and if it's neither bash or zsh, default to bash and 
    # inform the user.
    echo "Setting up zsh..."
    source ~/.dotfiles/dotfiles/zsh/setup.sh

    echo "Setting up bash..."
    source ~/.dotfiles/dotfiles/bash/setup.sh

    # Setup Starship.rs
    source ~/.dotfiles/dotfiles/starship/setup.sh

    # Install ASDF - not by default
    # source ~/.dotfiles/dotfiles/asdf/setup.sh 

    # Install FZF
    source ~/.dotfiles/dotfiles/fzf/setup.sh

    # VSCode settings
    source ~/.dotfiles/dotfiles/vscode/setup.sh

    # Install Claude Code
    source ~/.dotfiles/dotfiles/claude/setup.sh

    # Make sure we don't do it again
    touch "$CHECKFILE"
fi
