#!/bin/sh
source <(antibody init)
antibody bundle < $HOME/.config/antibody/plugins.txt
