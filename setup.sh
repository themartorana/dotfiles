#!/usr/bin/env bash
set -e

echo "Setting up via dotfiles..."

source "./dotfiles/utilities.sh"

# Tools install to ~/.local/bin; make them visible to the rest of setup.
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# Setup never uses elevated permissions. Shadow sudo with a stub that
# fails immediately (and logs), so a headless run errors instead of hanging
# on a prompt or silently elevating. Fixed path, no trap: never touches the
# caller's EXIT handler when this script is sourced.
SETUP_LOG="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/setup.log"
SUDO_SHIM="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/sudo-shim"
mkdir -p "$SUDO_SHIM" "$(dirname "$SETUP_LOG")"
cat > "$SUDO_SHIM/sudo" <<SHIM
#!/bin/sh
msg="setup.sh: blocked sudo \$*"
echo "\$msg" >&2
echo "\$(date -u +%Y-%m-%dT%H:%M:%SZ) \$msg (cwd: \$PWD)" >> "$SETUP_LOG"
exit 1
SHIM
chmod +x "$SUDO_SHIM/sudo"
export PATH="$SUDO_SHIM:$PATH"

CHECKFILE="$HOME/.dotfiles/initial-setup-done"
if [ ! -f "$CHECKFILE" ]; then
    # Make directories
    mkdir -p ~/bin
    mkdir -p ~/code
    mkdir -p ~/.config
    mkdir -p ~/.local/bin

    # Check to see if we're already in ~/.dotfiles or a subdirectory
    if [[ "$PWD" == "$HOME/.dotfiles"* ]]; then
        echo "Already in ~/.dotfiles, skipping copy step"
    else
        echo "Copying dotfiles to ~/.dotfiles..."
        # Copy dotfiles, including hidden files
        mkdir -p ~/.dotfiles
        cp -rv . ~/.dotfiles
    fi

    # Copy .profile 
    backup_or_rm_symlink "$HOME/.profile"
    ln -s "$HOME/.dotfiles/dotfiles/localfiles/profile" "$HOME/.profile"
    [ ! -f ~/.profile.local ] && cp ~/.dotfiles/dotfiles/localfiles/profile.local ~/.profile.local

    # copy .aliases
    backup_or_rm_symlink "$HOME/.aliases"
    ln -s ~/.dotfiles/dotfiles/localfiles/aliases ~/.aliases
    [ ! -f ~/.aliases.local ] && cp ~/.dotfiles/dotfiles/localfiles/aliases.local ~/.aliases.local

    # link ~/.claude/CLAUDE.md
    mkdir -p ~/.claude
    backup_or_rm_symlink "$HOME/.claude/CLAUDE.md"
    ln -s ~/.dotfiles/dotfiles/localfiles/CLAUDE.md ~/.claude/CLAUDE.md

    # Use your $SHELL to determine which setup script to run,
    # and if it's neither bash or zsh, default to bash and 
    # inform the user.
    echo_section "Setting up zsh..."
    source ~/.dotfiles/dotfiles/zsh/setup.sh

    echo_section "Setting up bash..."
    source ~/.dotfiles/dotfiles/bash/setup.sh

    # Setup Starship.rs
    echo_section "Setting up Starship..."
    source ~/.dotfiles/dotfiles/starship/setup.sh

    # Install ASDF - not by default
    # echo_section "Setting up ASDF..."
    # source ~/.dotfiles/dotfiles/asdf/setup.sh 

    # Install FZF
    echo_section "Setting up FZF..."
    source ~/.dotfiles/dotfiles/fzf/setup.sh

    # # VSCode settings
    # echo_section "Setting up VSCode extensions..."
    # source ~/.dotfiles/dotfiles/vscode/setup.sh

    # Make sure we don't do it again
    touch "$CHECKFILE"
fi

# Remove the sudo stub (matters when this script is sourced rather than run).
PATH="${PATH#"$SUDO_SHIM:"}"
rm -rf "$SUDO_SHIM"
unset SUDO_SHIM SETUP_LOG
