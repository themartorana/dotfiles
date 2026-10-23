#!/usr/bin/env bash
set -e

source "$HOME/.dotfiles/dotfiles/utilities.sh"

# Install FZF
if [ ! -d ~/.fzf ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf || {
        echo "Error: Failed to clone fzf repository"
        exit 1
    }
else
    # Shell integration needs fzf >= 0.48 (`fzf --bash` / `fzf --zsh`)
    git_update ~/.fzf
fi

# Binary only: don't touch rc files (they're tracked symlinks) or add PATH
# entries. Key bindings/completion are loaded in bashrc/zshrc via fzf itself.
~/.fzf/install --bin
link ~/.fzf/bin/fzf ~/.local/bin/fzf
