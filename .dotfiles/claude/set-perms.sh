#!/bin/bash

# Set dark theme
sudo -u vscode zsh -c 'claude config set -g theme dark'
sudo -u vscode zsh -c 'claude config set hasTrustDialogAccepted true'
sudo -u vscode zsh -c 'claude config set hasCompletedProjectOnboarding true'

# Remove self
# Remove the line from /etc/rc.local
sudo sed -i '\|/root/claude-runonce.sh >> /var/log/claude-runonce.log 2>&1|d' /etc/rc.local

# Remove this script file
rm -f "$0"
