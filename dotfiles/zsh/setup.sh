#!/usr/bin/env bash
set -e

# Set ZDOTDIR to the home directory if not already set
export ZDOTDIR="${ZDOTDIR:-$HOME}"

# Install antidote
if [ ! -d "${ZDOTDIR:-~}/.antidote" ]; then
    git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-~}/.antidote || {
        echo "Error: Failed to clone antidote repository"
        exit 1
    }
fi

# .zshenv
[ -f ~/.zshenv ] && mv ~/.zshenv ~/.zshenv.bak
ln -s ~/.dotfiles/dotfiles/zsh/zshenv ~/.zshenv
[ ! -f ~/.zshenv.local ] && cp ~/.dotfiles/dotfiles/zsh/zshenv.local ~/.zshenv.local

# .zshrc
[ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.bak
ln -s ~/.dotfiles/dotfiles/zsh/zshrc ~/.zshrc
[ ! -f ~/.zshrc.local ] && cp ~/.dotfiles/dotfiles/zsh/zshrc.local ~/.zshrc.local

# .zsh_plugins.txt
[ -f ~/.zsh_plugins.txt ] && mv ~/.zsh_plugins.txt ~/.zsh_plugins.txt.bak
ln -s ~/.dotfiles/dotfiles/zsh/zsh_plugins.txt ~/.zsh_plugins.txt

# .zsh_history
[ -f ~/.zsh_history ] || touch ~/.zsh_history

# Add local user completions to .zshrc.local
if ! grep -q "fpath+=\~/.zsh/completions" ~/.zshrc; then
    sed -i '1s/^/typeset -gaU fpath=($fpath ~\/.zsh\/completions)\n\n/' ~/.zshrc.local
    echo "Added '~/.zsh/completions' to .zshrc.local"
fi
