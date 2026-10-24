#!/usr/bin/env bash
set -e

# The clone this script lives in (also set by setup.sh when it sources us)
DOTFILES="$(CDPATH='' cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
source "$DOTFILES/dotfiles/utilities.sh"

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
# When the version changes, the installer deletes the old binary before it
# downloads the new one. Keep a copy so a failed update leaves fzf working;
# only a failed first install stops setup.
fzf_backup=""
if [ -x ~/.fzf/bin/fzf ]; then
    fzf_backup="$(mktemp)"
    cp -p ~/.fzf/bin/fzf "$fzf_backup"
fi
if ! ~/.fzf/install --bin; then
    if [ -z "$fzf_backup" ]; then
        echo "Error: Failed to install the fzf binary"
        exit 1
    fi
    echo "Warning: fzf update failed; keeping the previous binary"
    mkdir -p ~/.fzf/bin
    cp -p "$fzf_backup" ~/.fzf/bin/fzf
fi
[ -z "$fzf_backup" ] || rm -f "$fzf_backup"
link ~/.fzf/bin/fzf ~/.local/bin/fzf
