#!/usr/bin/env bash
set -e

# Install starship
if ! command -v starship >/dev/null 2>&1; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" || {
        echo "Error: Failed to install starship"
        exit 1
    }
fi

# Coming from pure prompt
mkdir -p ~/.config
# scan_timeout (ms, default 30) is a top-level key, so it must come before
# any [table] in the preset. Raised to avoid "Scanning current directory
# timed out" warnings in large directories.
{
    echo "scan_timeout = 500"
    echo
    starship preset pure-preset
} > ~/.config/starship.toml
