#!/usr/bin/env bash

# Utility function to conditionally use sudo if it exists
# Usage: maybe_sudo command [args...]
maybe_sudo() {
    if command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        "$@"
    fi
}

change_shell() {
    # Fixing chsh always asking for a password on alpine linux
    # ref: https://askubuntu.com/questions/812420/chsh-always-asking-a-password-and-get-pam-authentication-failure.
    if [ ! -f "/etc/pam.d/chsh" ] || ! grep -Eq '^auth(.*)pam_rootok\.so$' /etc/pam.d/chsh; then
        echo "auth sufficient pam_rootok.so" >> /etc/pam.d/chsh
    elif [[ -n "$(awk '/^auth(.*)pam_rootok\.so$/ && !/^auth[[:blank:]]+sufficient[[:blank:]]+pam_rootok\.so$/' /etc/pam.d/chsh)" ]]; then
        awk '/^auth(.*)pam_rootok\.so$/ { $2 = "sufficient" } { print }' /etc/pam.d/chsh > /tmp/chsh.tmp && mv /tmp/chsh.tmp /etc/pam.d/chsh
    fi

    maybe_sudo chsh -s "$1" "$2"
}

backup_or_rm_symlink() {
    if [ -L "$1" ]; then
        echo "Removing existing symlink at $1"
        rm "$1"
    elif [ -f "$1" ]; then
        echo "Backing up existing file at $1 to $1.bak"
        mv "$1" "$1.bak"
    fi
}