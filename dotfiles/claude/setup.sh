#!/usr/bin/env bash
set -e

echo "Installing Claude Code..."

# Prefer native installer for better performance and no dependencies
if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "linux-gnu"* ]] || [[ -n "$WSL_DISTRO_NAME" ]]; then
    echo "Installing Claude Code via native installer (recommended)..."
    curl -fsSL claude.ai/install.sh | bash
elif command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    echo "Falling back to npm installation..."
    npm install -g @anthropic-ai/claude-code
else
    echo "Warning: Unable to install Claude Code automatically."
    echo "Please install manually using one of these methods:"
    echo "  - curl -fsSL claude.ai/install.sh | bash (macOS/Linux/WSL - recommended)"
    echo "  - npm install -g @anthropic-ai/claude-code (requires Node.js)"
    echo "  - irm https://claude.ai/install.ps1 | iex (Windows PowerShell)"
    exit 1
fi

# Because Claude Code doesn't support direct API key input, we create a helper script
# that reads the API key from an environment variable.
# See: https://github.com/anthropics/claude-code/issues/1084
if [[ -z "${ANTHROPIC_API_KEY}" ]]; then
    echo "Error: ANTHROPIC_API_KEY environment variable is not set."
    echo "Please set it to your Anthropic API key and re-run this script."
    exit 1
else
    echo "ANTHROPIC_API_KEY detected. Setting up API key helper..."
    mkdir -p ~/.claude
    cp ./dotfiles/claude/settings.json ~/.claude/settings.json
    echo "#!/bin/bash\necho \"${ANTHROPIC_API_KEY}\"" > ~/.claude/apiKeyHelper.sh
    chmod ug+x ~/.claude/apiKeyHelper.sh
fi

# Done
echo "Claude Code installation complete!"
echo "Run 'claude' to start using Claude Code."
echo "You'll need to log in on first use with your Claude.ai or Anthropic Console account."