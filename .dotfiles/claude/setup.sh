#!/bin/bash

# Install claude
curl -fsSL https://claude.ai/install.sh | bash
sudo ln -s "$HOME/.local/bin/claude" "/usr/local/bin/claude"

# Necessary, frustratingly 
# See: https://github.com/anthropics/claude-code/issues/1084
printf "\n\nexport ANTHROPIC_AUTH_TOKEN=\"hello-world\"\n" >> $HOME/.profile

# Set dark theme
zsh -c 'claude config set -g theme dark'
zsh -c 'claude config set hasTrustDialogAccepted true'
zsh -c 'claude config set hasCompletedProjectOnboarding true'

bash -c 'claude config ls'
