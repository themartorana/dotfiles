# dotfiles
```
$ git clone https://github.com/themartorana/dotfiles.git ~/.dotfiles
$ . ~/.dotfiles/setup.sh
```

Sourcing or running `setup.sh` (`~/.dotfiles/setup.sh`) both work, from any directory; it always runs in its own bash process, so start a new shell afterwards.

Setup never uses sudo; tools install to `~/.local/bin`, and any attempt to use sudo makes setup fail.
