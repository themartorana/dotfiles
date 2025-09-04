#!/usr/bin/env bash
set -e

# Source utilities for conditional sudo
source ~/.dotfiles/utilities.sh

# Set as shell
maybe_sudo chsh -s "$(which zsh)" "$(whoami)"

# Install antidote
git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-~}/.antidote

# Install FZF
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all

# copy .zshenv
[ -f ~/.zshenv ] && cp ~/.zshenv ~/.zshenv.bak
cp ~/.dotfiles/zsh/zshenv ~/.zshenv

# copy .zshrc
[ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.bak
cp ~/.dotfiles/zsh/zshrc ~/.zshrc

# copy .aliases
[ -f ~/.aliases ] && cp ~/.aliases ~/.aliases.bak
cp ~/.dotfiles/zsh/aliases ~/.aliases

# copy .zsh_plugins.txt
[ -f ~/.zsh_plugins.txt ] && cp ~/.zsh_plugins.txt ~/.zsh_plugins.txt.bak
cp ~/.dotfiles/zsh/zsh_plugins.txt ~/.zsh_plugins.txt

# Set up the .zsh_history file
[ -f ~/.zsh_history ] || touch ~/.zsh_history

# Add local user completions to .zshrc
if ! grep -q "fpath+=\~/.zsh/completions" ~/.zshrc; then
    sed -i '1s/^/typeset -gaU fpath=($fpath ~\/.zsh\/completions)\n\n/' ~/.zshrc
    echo "Added '~/.zsh/completions' to .zshrc"
fi
