#!/usr/bin/env bash
set -e

# Install ZSH
sudo chsh -s "$(which zsh)" "$(whoami)"

# loop in zshrc
# echo 'source $HOME/.dotfiles/zsh/zshrc' >> $HOME/.zshrc
[ -f ~/.zshenv ] && cp ~/.zshenv ~/.zshenv.backup
cp $HOME/.dotfiles/zsh/zshenv $HOME/.zshenv

[ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.backup
cp $HOME/.dotfiles/zsh/zshrc $HOME/.zshrc

[ -f ~/.aliases ] && cp ~/.aliases ~/.aliases.backup
cp $HOME/.dotfiles/zsh/aliases $HOME/.aliases

# Set up the .zsh_history file
[ -f ~/.zsh_history ] || touch $HOME/.zsh_history

# Add local user completions to .zshrc
if ! grep -q "fpath+=\$HOME/.zsh/completions" ~/.zshrc; then
    sed -i '1s/^/typeset -gaU fpath=($fpath ~\/.zsh\/completions)\n\n/' ~/.zshrc
    echo "Added '$HOME/.zsh/completions' to .zshrc"
fi
