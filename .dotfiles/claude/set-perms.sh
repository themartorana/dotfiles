#!/usr/bin/env bash
if [ "$(claude config get hasTrustDialogAccepted)" = "false" ]; then
    echo "Setting Claude theme to 'dark'..."
    claude config set -g theme dark

    echo "Setting Claude trust dialog accepted to 'true'..."
    claude config set hasTrustDialogAccepted true

    echo "Setting Claude completed project onboarding to 'true'..."
    claude config set hasCompletedProjectOnboarding true
fi
