#!/usr/bin/env bash
set -e

# Install FZF
if [ ! -d ~/.fzf ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf || {
        echo "Error: Failed to clone fzf repository"
        exit 1
    }
fi

# Binary only: don't touch rc files (they're tracked symlinks) or add PATH
# entries. Key bindings/completion are loaded in bashrc/zshrc via fzf itself.
~/.fzf/install --bin
mkdir -p ~/.local/bin
ln -sf ~/.fzf/bin/fzf ~/.local/bin/fzf
