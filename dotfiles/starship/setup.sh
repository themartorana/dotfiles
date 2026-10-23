#!/usr/bin/env bash
set -e

# The clone this script lives in (also set by setup.sh when it sources us)
DOTFILES="$(CDPATH='' cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
source "$DOTFILES/dotfiles/utilities.sh"

# Install starship to ~/.local/bin, or update a copy we installed there.
# A starship from elsewhere (e.g. Homebrew) is left to its own updater.
starship_bin="$HOME/.local/bin/starship"
# Download the installer to a file first: with `curl | sh`, a failed
# download looks like success. The installer's stdout is shell setup advice
# our rc files already follow.
install_starship() {
    local installer rc=0
    mkdir -p "$HOME/.local/bin"
    installer="$(mktemp)"
    if curl -fsSL https://starship.rs/install.sh -o "$installer"; then
        sh "$installer" -y -b "$HOME/.local/bin" >/dev/null || rc=$?
    else
        rc=$?
    fi
    rm -f "$installer"
    return "$rc"
}
if ! command -v starship >/dev/null 2>&1; then
    echo "Installing starship to ~/.local/bin"
    install_starship || {
        echo "Error: Failed to install starship"
        exit 1
    }
elif [ "$(command -v starship)" = "$starship_bin" ]; then
    installed="$("$starship_bin" --version | awk 'NR == 1 { print $2 }')"
    latest="$(curl -fsSL https://api.github.com/repos/starship/starship/releases/latest 2>/dev/null \
        | sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p')"
    if [ -z "$latest" ]; then
        echo "Warning: could not check for a starship update"
    elif [ "$installed" != "$latest" ]; then
        echo "Updating starship $installed -> $latest"
        install_starship || echo "Warning: starship update failed"
    else
        echo "starship $installed is up to date"
    fi
else
    echo "starship at $(command -v starship) is not managed here; skipping update"
fi

# Tracked config (Pure preset plus our changes)
link "$DOTFILES"/dotfiles/starship/starship.toml ~/.config/starship.toml
