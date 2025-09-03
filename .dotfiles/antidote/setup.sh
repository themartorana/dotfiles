#!/usr/bin/env bash

# Install antidote
git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-~}/.antidote
ln -s ~/.antidote/antidote ~/bin

# Plugins
cp $HOME/.dotfiles/antidote/zsh_plugins.txt $HOME/.zsh_plugins.txt
