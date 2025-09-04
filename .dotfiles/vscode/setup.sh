#!/usr/bin/env bash
set -e

# Create the directory if it doesn't exist
mkdir -p /home/vscode/.vscode-server/data/Machine

# Path to the settings file
SETTINGS_FILE="/home/vscode/.vscode-server/data/Machine/settings.json"

function apply_setting() {
    local key="$1"
    local value="$2"
    if [ ! -f "$SETTINGS_FILE" ]; then
        # Create a new settings file with the required setting
        echo '{"$key": "$value"}' > "$SETTINGS_FILE"
    else
        # Add or update the setting in the existing file
        if jq -e "has(\"$key\")" "$SETTINGS_FILE" >/dev/null; then
            # Update the existing setting
            jq --arg v "$value" ".$key = $v" "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        else
            # Add the new setting
            jq --arg k "$key" --arg v "$value" '. + {[$k]: $v}' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        fi
    fi
}

# Check if the settings file exists
apply_setting "terminal.integrated.defaultProfile.linux" "zsh"
