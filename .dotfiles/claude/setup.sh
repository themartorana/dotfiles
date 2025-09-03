#!/bin/bash

# Install claude
curl -fsSL https://claude.ai/install.sh | bash
sudo ln -s "$HOME/.local/bin/claude" "/usr/local/bin/claude"

# Necessary, frustratingly 
# See: https://github.com/anthropics/claude-code/issues/1084
echo "\nexport ANTHROPIC_AUTH_TOKEN=\"hello-world\"" >> $HOME/.zshrc

# Set dark theme
claude config set -g theme dark
claude config set hasTrustDialogAccepted true
