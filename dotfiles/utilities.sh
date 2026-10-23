#!/usr/bin/env bash

# link SRC DST: make DST a symlink to SRC. Does nothing if it already is.
# A wrong symlink is replaced; a real file or directory is moved to DST.bak
# (or DST.bak.<timestamp> if that exists). Records DST in the link manifest
# so a later run can remove it if the repo stops linking it.
link() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        :
    else
        if [ -L "$dst" ]; then
            rm "$dst"
        elif [ -e "$dst" ]; then
            local bak="$dst.bak"
            [ -e "$bak" ] || [ -L "$bak" ] && bak="$dst.bak.$(date +%Y%m%d%H%M%S)"
            echo "Backing up $dst to $bak"
            mv "$dst" "$bak"
        fi
        ln -s "$src" "$dst"
        echo "Linked $dst -> $src"
    fi
    # Set by setup.sh; unset when a module script runs on its own.
    if [ -n "${DOTFILES_LINKS_NEW:-}" ]; then
        printf '%s\t%s\n' "$dst" "$src" >> "$DOTFILES_LINKS_NEW"
    fi
}

# seed_local SRC DST: copy the .local template SRC to DST once. Never
# overwrites, so machine-specific edits survive every replay.
seed_local() {
    if [ ! -e "$2" ]; then
        cp "$1" "$2"
        echo "Created $2"
    fi
}

# git_update DIR: fast-forward a clone. A failure (offline, diverged, no
# upstream) only warns: replays must still work without a network.
git_update() {
    GIT_TERMINAL_PROMPT=0 git -C "$1" pull --ff-only --quiet \
        || echo "Warning: could not update $1"
}

echo_section() {
    echo
    echo "=== $1 ==="
    echo
}
