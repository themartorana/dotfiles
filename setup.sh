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
    bash "$_dotfiles_setup"
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
echo "Setting up via dotfiles..."

# Resolve paths from the script's location, not the caller's cwd.
# CDPATH cleared: a CDPATH match makes cd print the dir, polluting the capture.
DOTFILES_SRC="$(CDPATH='' cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$HOME/.dotfiles"
source "$DOTFILES_SRC/dotfiles/utilities.sh"

# Bring the source clone up to date, then restart with the new setup.sh if
# the pull changed anything. DOTFILES_PULLED stops a second pull.
if [ -z "${DOTFILES_PULLED:-}" ] && [ -d "$DOTFILES_SRC/.git" ]; then
    echo "Updating $DOTFILES_SRC..."
    local before after
    before="$(git -C "$DOTFILES_SRC" rev-parse HEAD 2>/dev/null || true)"
    git_update "$DOTFILES_SRC"
    after="$(git -C "$DOTFILES_SRC" rev-parse HEAD 2>/dev/null || true)"
    if [ "$before" != "$after" ]; then
        echo "Updated to ${after:0:7}; restarting setup."
        DOTFILES_PULLED=1 exec bash "$DOTFILES_SRC/setup.sh"
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

# Devcontainers and Codespaces clone dotfiles elsewhere; mirror that clone
# into ~/.dotfiles (which the symlinks point into), dropping deleted files.
if [ "$DOTFILES_SRC" = "$DOTFILES" ]; then
    echo "Running from ~/.dotfiles, skipping copy step"
else
    echo "Mirroring $DOTFILES_SRC to ~/.dotfiles..."
    rm -rf "$DOTFILES.new"
    cp -R "$DOTFILES_SRC/." "$DOTFILES.new"
    # Local edits in the old copy (e.g. through the ~/.zshrc symlink) would
    # be lost; keep the old copy instead of deleting it.
    if [ -d "$DOTFILES/.git" ] && [ -n "$(git -C "$DOTFILES" status --porcelain 2>/dev/null)" ]; then
        local bak="$DOTFILES.bak.$(date +%Y%m%d%H%M%S)"
        echo "Warning: ~/.dotfiles had uncommitted changes; moved it to $bak"
        mv "$DOTFILES" "$bak"
    else
        rm -rf "$DOTFILES"
    fi
    mv "$DOTFILES.new" "$DOTFILES"
fi
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
}

# Remove links this setup made before but no longer makes (still pointing
# where we left them), and any link into ~/.dotfiles whose target is gone.
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
            "$DOTFILES"/*) rm "$dst"; echo "Removed broken link $dst" ;;
        esac
    done
    mv "$DOTFILES_LINKS_NEW" "$LINKS_MANIFEST"
}

main "$@"
