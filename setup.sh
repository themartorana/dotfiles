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
    if [ "$_dotfiles_rc" -eq 0 ]; then
        case " $* " in
            *" --ls "*) ;;
            *) echo "Done. Start a new shell to pick up the changes." ;;
        esac
    fi
    # eval expands the status before the unset runs
    eval "unset _dotfiles_rc; return $_dotfiles_rc"
fi
unset _dotfiles_setup

set -e

# Everything runs inside main() so bash parses it all up front: a `git pull`
# that rewrites this file mid-run can't change what's executing.
main() {
# Modules in the order they run: "name|description". Each is
# dotfiles/<name>/setup.sh. asdf (dormant) and vscode (deprecated) are left
# out on purpose.
local MODULES=(
    "localfiles|profile, aliases and CLAUDE.md"
    "zsh|zsh config and antidote plugins"
    "bash|bash config"
    "starship|starship prompt binary and config"
    "fzf|fzf binary"
)

# Kept whole so a restart after a pull gets the same options.
local args=("$@") relocate="" list="" only=""
while [ $# -gt 0 ]; do
    case "$1" in
        --relocate) relocate=1 ;;
        --ls) list=1 ;;
        --only)
            [ $# -ge 2 ] || usage
            only="$only,$2"; shift ;;
        --only=*) only="$only,${1#--only=}" ;;
        *) usage ;;
    esac
    shift
done

local _mod
if [ -n "$list" ]; then
    for _mod in "${MODULES[@]}"; do
        printf '%-12s %s\n' "${_mod%%|*}" "${_mod#*|}"
    done
    exit 0
fi

# SELECTED is " name name " (space-padded for matching), or empty for a
# full run.
SELECTED=""
if [ -n "$only" ]; then
    local _names=" " _want
    for _mod in "${MODULES[@]}"; do _names="$_names${_mod%%|*} "; done
    IFS=, read -r -a _want <<< "$only"
    for _mod in "${_want[@]}"; do
        [ -n "$_mod" ] || continue
        # Module names are [a-z0-9_-]; anything else (spaces too) can't match.
        case "$_mod" in *[!a-z0-9_-]*) _names="" ;; esac
        case "$_names" in
            *" $_mod "*) SELECTED="${SELECTED:- }$_mod " ;;
            *)
                echo "Error: unknown module '$_mod'. Run setup.sh --ls." >&2
                exit 2 ;;
        esac
    done
    [ -n "$SELECTED" ] || usage
    if [ -n "$relocate" ]; then
        echo "Error: --relocate relinks every module; drop --only." >&2
        exit 2
    fi
fi

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
    # A partial relink would leave home linked from two clones.
    if [ -n "$SELECTED" ]; then
        echo "Error: your dotfiles are linked from $OLD_DOTFILES." >&2
        echo "Relinking them needs a full run; drop --only." >&2
        exit 1
    fi
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
            DOTFILES_PULLED=1 exec bash "$DOTFILES/setup.sh" "${args[@]}"
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

# One link manifest per module in links.d/<module>. Each module's link()
# calls go to its own file in LINKS_NEW_DIR, which replaces the old files of
# the modules that ran once setup succeeds. links is the old single manifest.
LINKS_DIR="$state_dir/links.d"
if [ -L "$LINKS_DIR" ]; then
    echo "Error: $LINKS_DIR is a symlink; refusing to manage it." >&2
    exit 1
fi
LEGACY_MANIFEST="$state_dir/links"
LINKS_NEW_DIR="$(mktemp -d "$state_dir/links.new.XXXXXX")"
trap 'rm -rf "$SUDO_SHIM" "$LINKS_NEW_DIR"' EXIT

# Make directories
mkdir -p ~/bin ~/code ~/.config ~/.local/bin

# Left over from the old run-once setup
rm -f "$DOTFILES/initial-setup-done"

# Run every module, or only the --only ones, always in MODULES order. Both
# shells are configured on a full run, whatever $SHELL is. Modules are
# sourced, so they share this shell: loop variables are _-prefixed to stay
# clear of theirs.
local _name
for _mod in "${MODULES[@]}"; do
    _name="${_mod%%|*}"
    if [ -n "$SELECTED" ]; then
        case "$SELECTED" in *" $_name "*) ;; *) continue ;; esac
    fi
    echo_section "Setting up $_name..."
    DOTFILES_LINKS_NEW="$LINKS_NEW_DIR/$_name"
    : > "$DOTFILES_LINKS_NEW"
    source "$DOTFILES/dotfiles/$_name/setup.sh"
done
unset DOTFILES_LINKS_NEW

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

usage() {
    echo "Usage: setup.sh [--relocate] [--only MODULE[,MODULE...]] [--ls]" >&2
    exit 2
}

# Remove links this setup made before but no longer makes (still pointing
# where we left them), and any link into the clone (or the one we relinked
# from) whose target is gone. A partial (--only) run checks and replaces only
# the manifests of the modules it ran.
prune_links() {
    local f dst src target seen=()
    mkdir -p "$LINKS_DIR"
    # Migrate the old single manifest. Only a full run prunes it. Appended,
    # so a second copy (say, written by an older clone) loses nothing.
    if [ -f "$LEGACY_MANIFEST" ]; then
        cat "$LEGACY_MANIFEST" >> "$LINKS_DIR/_legacy"
        rm "$LEGACY_MANIFEST"
    fi
    # Links still wanted: everything linked this run, plus (on a partial run)
    # the old manifests of everything that didn't run. A link that moved to
    # another module is kept either way.
    seen=("$LINKS_NEW_DIR"/*)
    if [ -n "$SELECTED" ]; then
        for f in "$LINKS_DIR"/*; do
            [ -f "$f" ] || continue
            case "$SELECTED" in *" ${f##*/} "*) ;; *) seen+=("$f") ;; esac
        done
    fi
    for f in "$LINKS_DIR"/*; do
        [ -f "$f" ] || continue
        if [ -n "$SELECTED" ]; then
            case "$SELECTED" in *" ${f##*/} "*) ;; *) continue ;; esac
        fi
        # Old entries that aren't still wanted, in one pass.
        while IFS="$(printf '\t')" read -r dst src; do
            [ -n "$dst" ] || continue
            # Only ever touch this $HOME: a run with a different HOME but a
            # shared XDG_STATE_HOME must not prune the real home's links.
            case "$dst" in "$HOME"/*) ;; *) continue ;; esac
            if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
                rm "$dst"
                echo "Removed stale link $dst"
            fi
        done < <(awk -F '\t' -v old="$f" \
            'FILENAME != old { seen[$1] = 1; next } !($1 in seen)' \
            "${seen[@]}" "$f")
    done
    for dst in "$HOME"/.[!.]* "$HOME"/.config/* "$HOME"/.claude/* "$HOME"/.local/bin/*; do
        [ -L "$dst" ] && [ ! -e "$dst" ] || continue
        target="$(readlink "$dst")"
        case "$target" in
            "$DOTFILES"/*|"${OLD_DOTFILES:-$DOTFILES}"/*)
                rm "$dst"; echo "Removed broken link $dst" ;;
        esac
    done
    # A full run drops manifests of modules that no longer exist (and
    # _legacy); a partial run only overwrites the ones it ran. Only manifests
    # that aren't being replaced are removed, so a failed mv keeps the old.
    if [ -z "$SELECTED" ]; then
        for f in "$LINKS_DIR"/*; do
            [ -e "$LINKS_NEW_DIR/${f##*/}" ] || rm -f "$f"
        done
    fi
    mv "$LINKS_NEW_DIR"/* "$LINKS_DIR"/
}

main "$@"
