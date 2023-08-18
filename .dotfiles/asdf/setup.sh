#!/bin/bash

# Check to see if asdf is installed
if ! command -v asdf &> /dev/null; then
    # install asdf/nano
    git config --global advice.detachedHead false
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0
    chmod u+x ~/.asdf/asdf.sh
    echo ". \"\$HOME/.asdf/asdf.sh\"" >> ~/.bashrc
    source ~/.bashrc
fi

# Install Go plugin
if [ ! -d "$HOME/.asdf/plugins/golang" ]; then
    asdf plugin-add golang
    asdf install golang latest
    asdf global golang latest
fi