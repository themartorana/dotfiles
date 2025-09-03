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

echo "Claude Code installation complete!"
echo "Run 'claude' to start using Claude Code."
echo "You'll need to log in on first use with your Claude.ai or Anthropic Console account."