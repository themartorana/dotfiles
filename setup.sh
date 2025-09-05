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
    cp -rv .dotfiles ~

    # If zsh exists on the system, call zsh/setup.sh
    # else call bash/setup.sh
    if [[ "$SHELL" == *"zsh" ]]; then
        echo "Zsh shell detected, using Zsh"
        source ~/.dotfiles/zsh/setup.sh
    elif [[ "$SHELL" == *"bash" ]]; then
        echo "Bash shell detected, using Bash"
        source ~/.dotfiles/bash/setup.sh
    else
        echo "Unknown shell: $SHELL, defaulting to Bash"
        source ~/.dotfiles/bash/setup.sh
    fi

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
