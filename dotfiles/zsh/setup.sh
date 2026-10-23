#!/usr/bin/env bash
set -e

source "$HOME/.dotfiles/dotfiles/utilities.sh"

# Set ZDOTDIR to the home directory if not already set
export ZDOTDIR="${ZDOTDIR:-$HOME}"

# Install antidote (plugins are updated below, once zsh_plugins.txt is linked)
if [ ! -d "$ZDOTDIR/.antidote" ]; then
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$ZDOTDIR/.antidote" || {
        echo "Error: Failed to clone antidote repository"
        exit 1
    }
fi

link ~/.dotfiles/dotfiles/zsh/zshenv ~/.zshenv
seed_local ~/.dotfiles/dotfiles/zsh/zshenv.local ~/.zshenv.local

link ~/.dotfiles/dotfiles/zsh/zshrc ~/.zshrc
seed_local ~/.dotfiles/dotfiles/zsh/zshrc.local ~/.zshrc.local

link ~/.dotfiles/dotfiles/zsh/zprofile ~/.zprofile
seed_local ~/.dotfiles/dotfiles/zsh/zprofile.local ~/.zprofile.local

link ~/.dotfiles/dotfiles/zsh/zsh_plugins.txt ~/.zsh_plugins.txt

# Update antidote and the plugin bundles. `antidote bundle` first clones any
# missing ones (`antidote update` errors when there are none). Without zsh,
# only antidote itself can be updated.
if command -v zsh >/dev/null 2>&1; then
    zsh -c "source '$ZDOTDIR/.antidote/antidote.zsh' \
        && antidote bundle < ~/.zsh_plugins.txt >/dev/null && antidote update" \
        || echo "Warning: antidote update failed"
else
    git_update "$ZDOTDIR/.antidote"
fi

# .zsh_history
[ -f ~/.zsh_history ] || touch ~/.zsh_history
