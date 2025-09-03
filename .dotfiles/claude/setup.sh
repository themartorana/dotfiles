#!/bin/bash

# Install claude
curl -fsSL https://claude.ai/install.sh | bash
sudo ln -s "$HOME/.local/bin/claude" "/usr/local/bin/claude"

# Necessary, frustratingly 
# See: https://github.com/anthropics/claude-code/issues/1084
printf "\nexport ANTHROPIC_AUTH_TOKEN=\"hello-world\" \n" >> $HOME/.profile
export ANTHROPIC_AUTH_TOKEN="hello-world"

# Check perms
echo "source \$HOME/.dotfiles/claude/set-perms.sh" >> $HOME/.zshrc
