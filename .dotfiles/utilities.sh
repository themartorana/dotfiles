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
