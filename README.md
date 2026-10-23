# dotfiles
```
$ git clone https://github.com/themartorana/dotfiles.git ~/.dotfiles
$ . ~/.dotfiles/setup.sh
```

Sourcing or running `setup.sh` (`~/.dotfiles/setup.sh`) both work, from any directory; it always runs in its own bash process, so start a new shell afterwards.

Run `setup.sh` again at any time to bring a machine up to date. It pulls this repo, re-links everything, updates antidote (and its plugins), starship and fzf, and removes links to files that are gone. Your `~/.*.local` files are never touched.

Setup never uses sudo; tools install to `~/.local/bin`, and any attempt to use sudo makes setup fail.
