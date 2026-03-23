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
backup_or_rm_symlink "$HOME/.zshenv"
ln -s ~/.dotfiles/dotfiles/zsh/zshenv ~/.zshenv
[ ! -f ~/.zshenv.local ] && cp ~/.dotfiles/dotfiles/zsh/zshenv.local ~/.zshenv.local

# .zshrc
backup_or_rm_symlink "$HOME/.zshrc"
ln -s ~/.dotfiles/dotfiles/zsh/zshrc ~/.zshrc
[ ! -f ~/.zshrc.local ] && cp ~/.dotfiles/dotfiles/zsh/zshrc.local ~/.zshrc.local

# .zsh_plugins.txt
backup_or_rm_symlink "$HOME/.zsh_plugins.txt"
ln -s ~/.dotfiles/dotfiles/zsh/zsh_plugins.txt ~/.zsh_plugins.txt

# .zsh_history
[ -f ~/.zsh_history ] || touch ~/.zsh_history

