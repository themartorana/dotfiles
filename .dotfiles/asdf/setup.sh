#!/bin/sh

# Check to see if asdf is installed
if ! command -v asdf &> /dev/null
then
    # install asdf/nano
    git config --global advice.detachedHead false
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0
    chmod u+x ~/.asdf/asdf.sh
    chmod u+x ~/.asdf/asdf.zsh
    chmod u+x ~/.asdf/asdf.bash
    echo ". \"\$HOME/.asdf/asdf.sh\"" >> ~/.bashrc
    echo ". \"\$HOME/.asdf/completions/asdf.bash\"" >> ~/.bashrc
    echo ". \"\$HOME/.asdf/asdf.sh\"" >> ~/.zshrc
    echo ". \"\$HOME/.asdf/completions/asdf.zsh\"" >> ~/.zshrc
    source ~/.bashrc
fi
