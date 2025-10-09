#!/usr/bin/env bash
set -e

# Install starship
if ! command -v starship >/dev/null 2>&1; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y || {
        echo "Error: Failed to install starship"
        exit 1
    }
fi

# Coming from pure prompt
mkdir -p ~/.config
starship preset pure-preset -o ~/.config/starship.toml
