#!/usr/bin/env bash
set -e

# Install FZF
if [ ! -d ~/.fzf ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf || {
        echo "Error: Failed to clone fzf repository"
        exit 1
    }
fi
~/.fzf/install --all
