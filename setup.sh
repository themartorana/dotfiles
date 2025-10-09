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
    cp -rv dotfiles ~/.dotfiles

    # Move profile 
    [[ -s "$HOME/.profile" ]] && mv "$HOME/.profile" "$HOME/.profile.bak"
    cp "$HOME/.dotfiles/profile" "$HOME/.profile"

    # Use your $SHELL to determine which setup script to run,
    # and if it's neither bash or zsh, default to bash and 
    # inform the user.
    echo "Setting up zsh..."
    source ~/.dotfiles/zsh/setup.sh

    echo "Setting up bash..."
    source ~/.dotfiles/bash/setup.sh

    # Setup Starship.rs
    source ~/.dotfiles/starship/setup.sh

    # copy .aliases
    [ -f ~/.aliases ] && cp ~/.aliases ~/.aliases.bak
    cp ~/.dotfiles/aliases ~/.aliases

    # Install ASDF - not by default
    # source ~/.dotfiles/asdf/setup.sh

    # Install FZF
    source ~/.dotfiles/fzf/setup.sh

    # VSCode settings
    source ~/.dotfiles/vscode/setup.sh

    # Install Claude Code
    source ~/.dotfiles/claude/setup.sh

    # Make sure we don't do it again
    touch "$CHECKFILE"
fi
