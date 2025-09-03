#!/bin/bash

# Install claude
curl -fsSL https://claude.ai/install.sh | bash
sudo ln -s "$HOME/.local/bin/claude" "/usr/local/bin/claude"

# Necessary, frustratingly 
# See: https://github.com/anthropics/claude-code/issues/1084
printf "\n\nexport ANTHROPIC_AUTH_TOKEN=\"hello-world\"\n" >> $HOME/.profile

# Set up claude run-once
sudo chmod +x $HOME/.dotfiles/claude/set-perms.sh
sudo su -c "$HOME/.dotfiles/claude/set-perms.sh" root
