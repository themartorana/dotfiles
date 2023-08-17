#!/bin/bash

# Install antibody
if test ! $(which antibody); then
    curl -sfL git.io/antibody | sh -s - -b $HOME/bin
fi