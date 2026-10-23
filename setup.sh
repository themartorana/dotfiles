#!/usr/bin/env bash

# When sourced (`. ~/.dotfiles/setup.sh`, from bash or zsh), re-run in a
# child bash so nothing leaks into the caller's shell: no `set -e`, no
# exported variables, and no `exit` from a module closing the terminal.
_dotfiles_setup=""
if [ -n "${BASH_VERSION:-}" ]; then
    [ "${BASH_SOURCE[0]}" != "$0" ] && _dotfiles_setup="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
    case "${ZSH_EVAL_CONTEXT:-}" in *:file*) _dotfiles_setup="$0" ;; esac
fi
if [ -n "$_dotfiles_setup" ]; then
    bash "$_dotfiles_setup" "$@"
    _dotfiles_rc=$?
    unset _dotfiles_setup
    [ "$_dotfiles_rc" -eq 0 ] && echo "Done. Start a new shell to pick up the changes."
    # eval expands the status before the unset runs
    eval "unset _dotfiles_rc; return $_dotfiles_rc"
fi
unset _dotfiles_setup

set -e

# Everything runs inside main() so bash parses it all up front: a `git pull`
# that rewrites this file mid-run can't change what's executing.
main() {
local relocate=""
while [ $# -gt 0 ]; do
    case "$1" in
        --relocate) relocate=1 ;;
        *) echo "Usage: setup.sh [--relocate]" >&2; exit 2 ;;
    esac
    shift
done

echo "Setting up via dotfiles..."

# The clone setup.sh lives in, wherever that is. Every link points into it.
# CDPATH cleared: a CDPATH match makes cd print the dir, polluting the capture.
DOTFILES="$(CDPATH='' cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
export DOTFILES
source "$DOTFILES/dotfiles/utilities.sh"

# Guard against relinking home to another clone by accident (say, a
# temporary checkout). ~/.profile shows which clone the links use now.
OLD_DOTFILES=""
if [ -L "$HOME/.profile" ]; then
    case "$(readlink "$HOME/.profile")" in
        */dotfiles/localfiles/profile)
            OLD_DOTFILES="$(readlink "$HOME/.profile")"
            OLD_DOTFILES="${OLD_DOTFILES%/dotfiles/localfiles/profile}" ;;
    esac
fi
if [ -d "$OLD_DOTFILES" ]; then
    OLD_DOTFILES="$(CDPATH='' cd -- "$OLD_DOTFILES" && pwd -P)"
fi
if [ -n "$OLD_DOTFILES" ] && [ "$OLD_DOTFILES" != "$DOTFILES" ]; then
    if [ -f "$OLD_DOTFILES/setup.sh" ] && [ -z "$relocate" ]; then
        echo "Error: your dotfiles are linked from $OLD_DOTFILES." >&2
        echo "Run $OLD_DOTFILES/setup.sh instead, or re-run with --relocate" >&2
        echo "to link them from $DOTFILES." >&2
        exit 1
    fi
    echo "Relinking dotfiles from $OLD_DOTFILES to $DOTFILES"
fi

# Bring the clone up to date, then restart with the new setup.sh if the pull
# changed anything. DOTFILES_PULLED stops a second pull. Local changes or
# commits that block the pull are for the user to sort out.
if [ -z "${DOTFILES_PULLED:-}" ]; then
    if [ "$(git -C "$DOTFILES" rev-parse --show-toplevel 2>/dev/null)" = "$DOTFILES" ]; then
        echo "Updating $DOTFILES..."
        local before after
        before="$(git -C "$DOTFILES" rev-parse HEAD)"
        git_update "$DOTFILES"
        after="$(git -C "$DOTFILES" rev-parse HEAD)"
        if [ "$before" != "$after" ]; then
            echo "Updated to ${after:0:7}; restarting setup."
            DOTFILES_PULLED=1 exec bash "$DOTFILES/setup.sh" ${relocate:+--relocate}
        fi
    else
        echo "Warning: $DOTFILES is not a git clone; using it as is"
    fi
fi

# Tools install to ~/.local/bin; make them visible to the rest of setup.
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# Setup never uses elevated permissions. Shadow sudo with a stub that
# fails immediately (and logs), so a headless run errors instead of hanging
# on a prompt or silently elevating. Removed on exit, including on failure.
local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
SETUP_LOG="$state_dir/setup.log"
SUDO_SHIM="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/sudo-shim"
mkdir -p "$SUDO_SHIM" "$state_dir"
cat > "$SUDO_SHIM/sudo" <<SHIM
#!/bin/sh
msg="setup.sh: blocked sudo \$*"
echo "\$msg" >&2
echo "\$(date -u +%Y-%m-%dT%H:%M:%SZ) \$msg (cwd: \$PWD)" >> "$SETUP_LOG"
exit 1
SHIM
chmod +x "$SUDO_SHIM/sudo"
export PATH="$SUDO_SHIM:$PATH"

# Every link() call appends to this; it replaces the manifest on success.
LINKS_MANIFEST="$state_dir/links"
DOTFILES_LINKS_NEW="$(mktemp "$state_dir/links.XXXXXX")"
trap 'rm -rf "$SUDO_SHIM" "$DOTFILES_LINKS_NEW"' EXIT

# Make directories
mkdir -p ~/bin ~/code ~/.config ~/.local/bin

# Left over from the old run-once setup
rm -f "$DOTFILES/initial-setup-done"

# Shell-agnostic files
link "$DOTFILES/dotfiles/localfiles/profile" "$HOME/.profile"
seed_local "$DOTFILES/dotfiles/localfiles/profile.local" "$HOME/.profile.local"
link "$DOTFILES/dotfiles/localfiles/aliases" "$HOME/.aliases"
seed_local "$DOTFILES/dotfiles/localfiles/aliases.local" "$HOME/.aliases.local"
link "$DOTFILES/dotfiles/localfiles/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

# Both shells are always configured, whatever $SHELL is.
echo_section "Setting up zsh..."
source "$DOTFILES/dotfiles/zsh/setup.sh"

echo_section "Setting up bash..."
source "$DOTFILES/dotfiles/bash/setup.sh"

# Setup Starship.rs
echo_section "Setting up Starship..."
source "$DOTFILES/dotfiles/starship/setup.sh"

# Install ASDF - not by default
# echo_section "Setting up ASDF..."
# source "$DOTFILES/dotfiles/asdf/setup.sh"

# Install FZF
echo_section "Setting up FZF..."
source "$DOTFILES/dotfiles/fzf/setup.sh"

# # VSCode settings
# echo_section "Setting up VSCode extensions..."
# source "$DOTFILES/dotfiles/vscode/setup.sh"

echo_section "Removing stale links..."
prune_links

# Older setups copied the clone into ~/.dotfiles. Point out a copy that's
# no longer linked; it may hold edits, so it's never deleted.
if [ -d "$HOME/.dotfiles" ] \
    && [ "$(CDPATH='' cd -- "$HOME/.dotfiles" && pwd -P)" != "$DOTFILES" ]; then
    echo
    echo "Note: ~/.dotfiles is no longer used (links now point into $DOTFILES)."
    echo "Delete it once you've checked it holds nothing you need."
fi
}

# Remove links this setup made before but no longer makes (still pointing
# where we left them), and any link into the clone (or the one we relinked
# from) whose target is gone.
prune_links() {
    local dst src target
    if [ -f "$LINKS_MANIFEST" ]; then
        while IFS="$(printf '\t')" read -r dst src; do
            [ -n "$dst" ] || continue
            # Still linked this run (possibly to a new source): keep it.
            awk -F '\t' -v d="$dst" '$1 == d { found = 1 } END { exit !found }' \
                "$DOTFILES_LINKS_NEW" && continue
            if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
                rm "$dst"
                echo "Removed stale link $dst"
            fi
        done < "$LINKS_MANIFEST"
    fi
    for dst in "$HOME"/.[!.]* "$HOME"/.config/* "$HOME"/.claude/* "$HOME"/.local/bin/*; do
        [ -L "$dst" ] && [ ! -e "$dst" ] || continue
        target="$(readlink "$dst")"
        case "$target" in
            "$DOTFILES"/*|"${OLD_DOTFILES:-$DOTFILES}"/*)
                rm "$dst"; echo "Removed broken link $dst" ;;
        esac
    done
    mv "$DOTFILES_LINKS_NEW" "$LINKS_MANIFEST"
}

main "$@"
