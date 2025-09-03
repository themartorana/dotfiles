#!/bin/bash

# Set dark theme
sudo -u vscode zsh -c 'claude config set -g theme dark'
sudo -u vscode zsh -c 'claude config set hasTrustDialogAccepted true'
sudo -u vscode zsh -c 'claude config set hasCompletedProjectOnboarding true'

# Remove self
sed -i '/claude-runonce.sh/d' /etc/rc.local
