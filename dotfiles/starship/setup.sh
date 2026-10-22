#!/usr/bin/env bash
set -e

source "$HOME/.dotfiles/dotfiles/utilities.sh"

# Install starship
if ! command -v starship >/dev/null 2>&1; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" || {
        echo "Error: Failed to install starship"
        exit 1
    }
fi

# Tracked config (Pure preset plus our changes)
mkdir -p ~/.config
backup_or_rm_symlink "$HOME/.config/starship.toml"
ln -s ~/.dotfiles/dotfiles/starship/starship.toml ~/.config/starship.toml
