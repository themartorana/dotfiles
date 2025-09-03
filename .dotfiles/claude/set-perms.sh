#!/usr/bin/env bash
set -euo pipefail

claude_config_safe() {
    local timeout_duration=10
    timeout "${timeout_duration}" claude "$@" 2>/dev/null || {
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            echo "Warning: claude command timed out after ${timeout_duration} seconds" >&2
        else
            echo "Warning: claude command failed with exit code $exit_code" >&2
        fi
        return $exit_code
    }
}

if command -v claude >/dev/null 2>&1; then
    if trust_status=$(claude_config_safe config get hasTrustDialogAccepted 2>/dev/null) && [ "$trust_status" = "false" ]; then
        echo "Setting Claude theme to 'dark'..."
        claude_config_safe config set -g theme dark || echo "Warning: Failed to set theme" >&2

        echo "Setting Claude trust dialog accepted to 'true'..."
        claude_config_safe config set hasTrustDialogAccepted true || echo "Warning: Failed to set trust dialog" >&2

        echo "Setting Claude completed project onboarding to 'true'..."
        claude_config_safe config set hasCompletedProjectOnboarding true || echo "Warning: Failed to set project onboarding" >&2
    fi
else
    echo "Warning: claude command not found" >&2
fi
