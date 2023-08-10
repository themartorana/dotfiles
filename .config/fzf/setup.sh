#!/bin/sh

# Install fzf
if test ! $(which fzf); then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ln -s ~/.fzf/bin/fzf ~/bin/fzf
fi