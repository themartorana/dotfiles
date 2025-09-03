#!/bin/bash

# Install claude
curl -fsSL https://claude.ai/install.sh | bash
sudo ln -s "$HOME/.local/bin/claude" "/usr/local/bin/claude"

# Necessary, frustratingly 
# See: https://github.com/anthropics/claude-code/issues/1084
printf "\n\nexport ANTHROPIC_AUTH_TOKEN=\"hello-world\"\n" >> $HOME/.zshrc

# Set dark theme
claude config set theme dark
claude config set hasTrustDialogAccepted true
claude config set hasCompletedProjectOnboarding true
