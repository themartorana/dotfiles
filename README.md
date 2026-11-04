# dotfiles

Personal shell configuration for **bash** and **zsh**: `PATH`, both shells, a [starship](https://starship.rs) prompt, [fzf](https://github.com/junegunn/fzf) and shared aliases. One unprivileged `setup.sh` installs it on:

- macOS laptops and servers
- Linux servers and virtual machines
- sandboxes
- devcontainers and GitHub Codespaces

## Philosophy

- **Local only, no sudo.** Everything installs into your home directory, mostly `~/.local/bin`. While setup runs, `sudo` is replaced by a stub that fails and logs the attempt to `~/.local/state/dotfiles/setup.log`. It works without admin rights and never changes the system for other users.
- **Link, don't copy.** Tracked config files are symlinked from the clone into `~`, so editing `~/.zshrc` edits the repo.
- **Machine-specific stuff stays out of the repo.** Each config file loads an untracked `.local` partner (`~/.zshrc.local`, `~/.profile.local`, …) last. Secrets, extra `PATH` entries and per-machine settings go there.
- **Replayable.** One command for a fresh install and for updates. A run with nothing new changes nothing. There is no "already set up" check.
- **Never destructive.** Existing files are moved to `*.bak`, never overwritten. `.local` files are never touched after creation. Failed updates (offline, etc.) warn and keep what you have; only a failed *first* install stops setup.
- **Both shells, always.** bash and zsh are both fully configured, whatever `$SHELL` is. Setup never runs `chsh`.
- **One source of `PATH`.** `PATH` and the XDG variables are set only in `~/.profile`, which is POSIX sh, silent and idempotent. Nesting shells never duplicates entries.
- **Installers don't touch rc files.** Tools are installed binary-only; their shell integration lives in the tracked rc files.

## Install

```sh
git clone https://github.com/themartorana/dotfiles.git ~/.dotfiles
~/.dotfiles/setup.sh
```

Then **open a new shell**.

- **Run or source it.** `~/.dotfiles/setup.sh` and `. ~/.dotfiles/setup.sh` (from bash or zsh) do the same thing. When sourced, it re-runs itself in a child bash, so nothing leaks into your current shell, and you still need a new shell. The working directory doesn't matter.
- **Clone anywhere.** `~/.dotfiles` is just the convention. Links point into whichever clone ran `setup.sh`, so don't move it afterwards.
- **`--relocate`.** After moving the clone, or to switch to a different clone, run `setup.sh --relocate` from the new location. Without it, setup refuses to relink from a second clone while the original still exists (so a temp checkout or worktree can't take over `~`).
- **Devcontainers and Codespaces.** Set your editor's "dotfiles repository" to this repo; it clones and runs `setup.sh` for you.
- **Updating.** Just run `setup.sh` again.

### What a run does

1. Pulls the clone (`git pull --ff-only`) and restarts itself if `HEAD` moved. A failed pull warns and continues with the current files.
2. Blocks `sudo` for the duration of the run.
3. Creates `~/bin`, `~/code`, `~/.config`, `~/.local/bin`.
4. Links shared files, then runs the modules in order: **zsh** → **bash** → **starship** → **fzf**.
5. Removes stale links: ones recorded in the previous run that the repo no longer makes, and broken symlinks pointing into the clone.

### Requirements

Installed by setup: antidote, starship, fzf.

Assumed present:

| Tool | Needed for |
|---|---|
| `bash`, `git`, `curl` | setup itself |
| `zsh` | the zsh config (configured even if missing) |
| `ag` | fzf file lists (Ctrl-T / Alt-C) |
| `jq`, `tailscale` | tailnet aliases and prompt machine name (optional) |
| Homebrew at `/opt/homebrew` | Apple Silicon macOS only |

The prompt's branch symbol needs a [Nerd Font](https://www.nerdfonts.com); colours need a truecolor terminal.

## Where files go

**Symlinked** from the clone (`<clone>` = wherever you cloned, usually `~/.dotfiles`). The `.local` partner is **copied once** from a comment-only template, then never tracked or overwritten:

| Home path | Source in repo | `.local` partner |
|---|---|---|
| `~/.profile` | `dotfiles/localfiles/profile` | `~/.profile.local` |
| `~/.aliases` | `dotfiles/localfiles/aliases` | `~/.aliases.local` |
| `~/.claude/CLAUDE.md` | `dotfiles/localfiles/CLAUDE.md` | — |
| `~/.config/starship.toml` | `dotfiles/starship/starship.toml` | — |
| `~/.zshenv` | `dotfiles/zsh/zshenv` | `~/.zshenv.local` |
| `~/.zprofile` | `dotfiles/zsh/zprofile` | `~/.zprofile.local` |
| `~/.zshrc` | `dotfiles/zsh/zshrc` | `~/.zshrc.local` |
| `~/.zsh_plugins.txt` | `dotfiles/zsh/zsh_plugins.txt` | — |
| `~/.bash_profile` | `dotfiles/bash/bash_profile` | `~/.bash_profile.local` |
| `~/.bashrc` | `dotfiles/bash/bashrc` | `~/.bashrc.local` |

**Installed / cloned:**

| Path | What |
|---|---|
| `~/.antidote` | antidote (zsh plugin manager) |
| `~/.cache/antidote` | zsh plugin clones (`ANTIDOTE_HOME`, set in `zshenv`) |
| `~/.fzf` | fzf clone; binary linked to `~/.local/bin/fzf` |
| `~/.local/bin/starship` | starship, unless already installed elsewhere (e.g. Homebrew) |

**Setup state:**

| Path | What |
|---|---|
| `~/.local/state/dotfiles/links` | manifest of links made, used to prune stale ones |
| `~/.local/state/dotfiles/setup.log` | blocked `sudo` attempts |
| `~/.cache/dotfiles/sudo-shim` | the `sudo` stub (removed when setup exits) |

(`XDG_STATE_HOME` / `XDG_CACHE_HOME` are respected.)

## Shell load order

- **zsh:** `.zshenv` → `.profile`; `.zprofile` → `.profile` again (macOS `path_helper` reorders `PATH` in between); `.zshrc` → history, completion, antidote plugins, starship, fzf, `~/.aliases`, `~/.zshrc.local`.
- **bash:** `.bash_profile` → `.profile`, then `.bashrc` if interactive; `.bashrc` → `.profile`, history, starship, fzf, `~/.aliases`, `~/.bashrc.local`.

`PATH` precedence: `~/bin`, `~/.local/bin`, `~/.cargo/bin`, `/opt/homebrew/bin`, `/opt/homebrew/sbin`, system paths, `~/.ec2/bin`.

## Customising a machine

Use the `.local` files, never the tracked ones:

- `~/.profile.local`: extra `PATH` entries (use `path_prepend` / `path_append`), env vars, XDG overrides. Must be POSIX sh and silent.
- `~/.zshrc.local`, `~/.bashrc.local`: shell-specific settings.
- `~/.aliases.local`: per-machine aliases (bash and zsh).
- Secrets and tokens.
- `EDITOR`: defaults to the first of `nvim`, `vim`, `vi`; override in `~/.profile.local`.

**Prompt machine name:** the first of `$MACHINE_NAME` (set in `~/.profile.local`), the Tailscale MagicDNS name, or the short hostname. Useful for sandboxes and containers with random hostnames.

## What you get

- **zsh plugins** via [antidote](https://github.com/mattmc3/antidote): autosuggestions, fast-syntax-highlighting, zsh-completions, history substring search.
- **starship prompt:** Pure preset with Everforest colours. Line 1 is `🌐 user@machine ~/path  branch*`; 🌐 only over SSH.
- **fzf:** history (Ctrl-R), files (Ctrl-T), directories (Alt-C).
- **Shared aliases**, including Tailscale helpers (`tnsearch`, `tnssh`, `tninfo`).

## Repository layout

```
setup.sh        entry point
dotfiles/
  utilities.sh  helpers shared by setup scripts (link, seed_local, git_update)
  localfiles/   profile, aliases, global CLAUDE.md
  zsh/          zsh config and plugin list
  bash/         bash config
  starship/     prompt config
  fzf/          fzf installer
  vscode/       deprecated (use VS Code Settings Sync)
  asdf/         unused
```

## License

See [LICENSE](LICENSE).
