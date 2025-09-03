#!/bin/bash

# Install antidote
git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-~}/.antidote

# Plugins
cp $HOME/.dotfiles/zsh/zsh_plugins.txt $HOME/.zsh_plugins.txt