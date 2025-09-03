#!/bin/bash

# Install claude
curl -fsSL https://claude.ai/install.sh | bash
sudo ln -s "$HOME/.local/bin/claude" "/usr/local/bin/claude"

# Necessary, frustratingly 
# See: https://github.com/anthropics/claude-code/issues/1084
printf "\n\nexport ANTHROPIC_AUTH_TOKEN=\"hello-world\"\n" >> $HOME/.profile

# Set up claude run-once
sudo cp $HOME/.dotfiles/claude/claude-runonce.sh /root/claude-runonce.sh
sudo echo "/root/claude-runonce.sh" >> /etc/rc.local
