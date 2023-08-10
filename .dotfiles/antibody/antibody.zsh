#!/bin/sh
source <(antibody init)
antibody bundle < $HOME/.dotfiles/antibody/plugins.txt
