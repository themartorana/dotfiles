#!/usr/bin/env bash

# Check to see if asdf is installed
if ! command -v asdf &> /dev/null; then
    if [ ! -d "$HOME/.asdf" ]; then
        # install asdf/nano
        git config --global advice.detachedHead false
        git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0 || {
            echo "Error: Failed to clone asdf repository"
            exit 1
        }
        chmod u+x ~/.asdf/asdf.sh
        echo ". \"\$HOME/.asdf/asdf.sh\"" >> ~/.bashrc
        source "\$HOME/.asdf/asdf.sh"
    fi
fi

# Install Go plugin
if [ ! -d "$HOME/.asdf/plugins/golang" ]; then
    asdf plugin-add golang
    asdf install golang latest
    asdf global golang latest
fi