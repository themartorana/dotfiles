#!/usr/bin/env bash

backup_or_rm_symlink() {
    if [ -L "$1" ]; then
        echo "Removing existing symlink at $1"
        rm "$1"
    elif [ -f "$1" ]; then
        echo "Backing up existing file at $1 to $1.bak"
        mv "$1" "$1.bak"
    fi
}

echo_section() {
    echo
    echo "=== $1 ==="
    echo
}