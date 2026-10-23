# AGENTS.md

Personal dotfiles for bash and zsh. They set up `PATH`, the shells, the prompt (starship), fzf, and aliases. A single, unprivileged `setup.sh` installs everything onto:

- macOS laptops and servers
- Linux servers and virtual machines
- sandboxes
- devcontainers and Codespaces (the original target)

Each machine adds its own settings through untracked `*.local` files.

## Layout

```
setup.sh                 entry point; sources the per-module setup scripts
dotfiles/
  utilities.sh           link, seed_local, git_update, echo_section (shared by setup scripts)
  localfiles/            shell-agnostic files: profile, aliases, CLAUDE.md
  zsh/                   zshenv, zprofile, zshrc, zsh_plugins.txt (antidote)
  bash/                  bash_profile, bashrc
  starship/              starship.toml (prompt config)
  fzf/                   setup.sh only; installs the fzf binary
  vscode/                deprecated (see Modules)
  asdf/                  dormant, not wired into setup.sh; leave alone
.devcontainer/           bare Ubuntu devcontainer; does not run setup
```

## The link + `.local` pattern

Every module follows this pattern:

- **Tracked file → symlink.** `~/.zshrc` → `~/.dotfiles/dotfiles/zsh/zshrc`. Made with `link <src> <dst>`, which does nothing if the link is already right. It replaces a wrong symlink, and moves a real file or directory to `*.bak` (`*.bak.<timestamp>` if that exists). Each call is recorded in a link manifest so later runs can remove links the repo no longer makes (see step 10 below).
- **`*.local` partner → copied once, untracked.** The repo copy (for example `dotfiles/zsh/zshrc.local`) is a template that holds only comments. Setup copies it to `~/.zshrc.local` with `seed_local`, only if that file doesn't exist yet. It is never overwritten or tracked. Each tracked file sources its `.local` partner, usually last.
- Machine-specific settings, secrets and extra `PATH` entries go in `~/.*.local`, never in tracked files. Because the files are symlinked, editing `~/.zshrc` edits the tracked file in `~/.dotfiles`.

| Home path | Source in repo | `.local` partner |
|---|---|---|
| `~/.profile` | `localfiles/profile` | `~/.profile.local` |
| `~/.aliases` | `localfiles/aliases` | `~/.aliases.local` |
| `~/.claude/CLAUDE.md` | `localfiles/CLAUDE.md` | — |
| `~/.config/starship.toml` | `starship/starship.toml` | — |
| `~/.zshenv` | `zsh/zshenv` | `~/.zshenv.local` |
| `~/.zprofile` | `zsh/zprofile` | `~/.zprofile.local` |
| `~/.zshrc` | `zsh/zshrc` | `~/.zshrc.local` |
| `~/.zsh_plugins.txt` | `zsh/zsh_plugins.txt` | — |
| `~/.bash_profile` | `bash/bash_profile` | `~/.bash_profile.local` |
| `~/.bashrc` | `bash/bashrc` | `~/.bashrc.local` |

`localfiles/CLAUDE.md` holds the owner's **global** agent instructions, linked to `~/.claude/CLAUDE.md`. It is not guidance for working in this repo. Edit it only when asked to change those global instructions.

## How `setup.sh` runs

Install: `git clone https://github.com/themartorana/dotfiles.git ~/.dotfiles`, then run `setup.sh`. You can source it (`. ~/.dotfiles/setup.sh`, as the README shows) or run it as a program (`~/.dotfiles/setup.sh`, which is what devcontainer and Codespaces dotfiles support does). The current directory doesn't matter.

**Setup is replayable.** Every run brings the machine up to date: it pulls the repo, re-links, updates the tools and removes stale links. A second run with nothing new changes nothing. There is no run-once check; any leftover `~/.dotfiles/initial-setup-done` from the old design is deleted.

In order, the script does this:

1. **If sourced, re-runs itself in a child `bash` and returns its exit code.** This works from bash or zsh. Nothing leaks into the caller's shell, but the caller also doesn't pick up the new `PATH`, so start a new shell afterwards. Everything below therefore always runs in its own bash process, inside a `main` function. Bash parses the whole function before running it, so a pull that rewrites `setup.sh` can't corrupt the run in progress.
2. **Finds its own location** (`DOTFILES_SRC`, from `BASH_SOURCE`) and loads `utilities.sh` from there.
3. **Pulls the repo.** If `DOTFILES_SRC` is a git clone, it runs `git pull --ff-only` there. If `HEAD` moved, it `exec`s the new `setup.sh` with `DOTFILES_PULLED=1`, which skips this step. A failed pull (offline, diverged, no upstream, detached `HEAD`) prints a warning and setup continues with the files it has.
4. **Puts `~/.local/bin` first in `PATH`.** Every tool setup installs goes there.
5. **Blocks sudo.** It writes a fake `sudo` to `${XDG_CACHE_HOME:-~/.cache}/dotfiles/sudo-shim` and puts it first in `PATH`. Any `sudo` call exits 1 and is logged to `${XDG_STATE_HOME:-~/.local/state}/dotfiles/setup.log`. An EXIT `trap` removes the fake, including when setup fails.
6. **Creates `~/bin`, `~/code`, `~/.config` and `~/.local/bin`.**
7. **Copy vs. in place.** If `DOTFILES_SRC` isn't `~/.dotfiles`, it **mirrors** the clone into `~/.dotfiles`: it copies the clone, `.git` included, to `~/.dotfiles.new`, then swaps it in, so files deleted upstream disappear. If the old `~/.dotfiles` had uncommitted changes (for example edits made through `~/.zshrc`), it's moved to `~/.dotfiles.bak.<timestamp>` instead of being deleted. Devcontainers and Codespaces clone dotfiles elsewhere, which is why this step exists. All symlinks point into `~/.dotfiles`.
8. **Links** `profile`, `aliases` and `CLAUDE.md` and seeds their `.local` files.
9. **Sources module setup scripts in this order:** `zsh` → `bash` → `starship` → `fzf`. Both shells are always configured, whatever `$SHELL` is. Setup never runs `chsh`.
10. **Removes stale links** (`prune_links`):
    - **Manifest.** Every `link` call appends `dst<TAB>src` to a new manifest. Entries in the previous manifest, `${XDG_STATE_HOME:-~/.local/state}/dotfiles/links`, that this run didn't link are removed, but only if they still point at the recorded source.
    - **Broken links.** Symlinks in `~`, `~/.config`, `~/.claude` and `~/.local/bin` that point into `~/.dotfiles` at a file that no longer exists are removed. This catches links made before the manifest existed.
    - The new manifest then replaces the old one. A run that fails earlier doesn't prune anything and keeps the old manifest.

Module scripts are **sourced** into setup's bash process, not executed. Each one must be safe to run again on every replay. Their `set -e`, exported variables (for example `ZDOTDIR`) and any `exit` affect, or end, the whole setup run, never the user's shell. A module that fails should `exit 1` with a message.

## Shell load order and `.profile`

`localfiles/profile` is the **only** place that sets `PATH` (and the XDG variables), for both shells:

- **zsh:** `.zshenv` sources `.profile`. `.zprofile` sources it **again**, because on macOS `/etc/zprofile` runs `path_helper` in between and moves system paths ahead of ours. Then `.zshrc` runs: history, completion, antidote plugins, starship, fzf, `~/.aliases`, `~/.zshrc.local`.
- **bash:** `.bash_profile` sources `.profile`, then `.bashrc` if the shell is interactive. `.bashrc` sources `.profile` too (for non-login interactive shells), then sets up history, starship, fzf, `~/.aliases`, `~/.bashrc.local`.

Since `.profile` and `.profile.local` are loaded many times, by every kind of shell, they must be:

- **POSIX sh:** no `[[ ]]`, no arrays
- **silent:** no output
- **idempotent:** safe to load repeatedly

Add `PATH` entries with `path_prepend` and `path_append`. They remove an existing copy before adding, so entries never duplicate. Both functions exist only while `.profile` and `.profile.local` are being loaded; they are unset afterwards.

`PATH` precedence, highest first: `~/bin`, `~/.local/bin`, `~/.cargo/bin`, `/opt/homebrew/bin`, `/opt/homebrew/sbin`, the system paths, then `~/.ec2/bin`. The Homebrew entries are harmless on Linux.

XDG variables are set *after* `.profile.local` loads, using `${VAR:-default}`. A value set in `.profile.local` therefore wins.

`~/.aliases` is sourced by both shells' rc files, so it must work in both bash and zsh.

## Modules

- **zsh:**
  - Clones [antidote](https://github.com/mattmc3/antidote) to `${ZDOTDIR:-$HOME}/.antidote`. `zshrc` loads it from `$HOME/.antidote`.
  - On every run, if `zsh` is installed: `antidote bundle` clones any missing plugins, then `antidote update` updates the plugins and antidote. Without `zsh`, it only pulls antidote. A failed update prints a warning and setup continues.
  - Plugins are listed in `zsh_plugins.txt`: zsh-async, zsh-completions, zsh-autosuggestions, fast-syntax-highlighting, history-substring-search.
  - Completions also come from `~/.zsh/completions` and `/opt/homebrew/share/zsh/site-functions`.
- **bash:** links files only. Creates `~/.bash_history` if missing.
- **starship:**
  - Installs to `~/.local/bin` with the official installer if `starship` isn't on `PATH`. The installer is downloaded to a temp file before it runs (not `curl | sh`), so a failed download counts as a failure.
  - If the `starship` on `PATH` is `~/.local/bin/starship`, it compares the installed version with the latest GitHub release and re-runs the installer when they differ. A `starship` installed anywhere else (for example by Homebrew) is left to its own updater.
  - Links `~/.config/starship.toml` to the tracked `starship/starship.toml`. On machines set up before this change, the old generated file is renamed to `.bak`. Edit the prompt in the tracked file.
  - That file is the Pure preset (`starship preset pure-preset` from starship 1.27.0) with our changes on top. Top-level keys such as `scan_timeout` must come before any `[table]`.
  - Our changes are listed in the file's header. Line 1 is `🌐 user@machine ~/path  branch*`, with `🌐` only in SSH sessions. The colours come from Everforest Dark Medium (the `[palettes.everforest]` table): `user@machine` blue, path aqua, git all purple; the rest are Pure's colours in their Everforest versions (hex, so they need a truecolor terminal). The directory is the full `~` path, like Pure itself. Everything is bold. The branch symbol needs a Nerd Font. The machine is the first of: `$MACHINE_NAME` (exported from `~/.profile.local`), `$TAILNET_HOSTNAME`, the short hostname. Sandboxes and containers often have meaningless hostnames, which is why the overrides exist.
  - `TAILNET_HOSTNAME` is the first label of the machine's tailnet MagicDNS name. `bashrc` and `zshrc` set it before `starship init` (keep the two blocks in step). They run `tailscale status` + `jq` once per shell, skip the lookup if the variable is inherited, and unset it when `MACHINE_NAME` is set. Without tailscale, jq or a running, logged-in tailscale (`BackendState` `Running`), it stays unset.
  - Its `git_status` and `jj_status` symbols are zero-width spaces (U+200B), invisible in most editors. Keep them: an empty string would hide the `*` dirty marker.
- **fzf:**
  - Clones `~/.fzf`, or updates it with `git_update` (`git pull --ff-only`, warning on failure) if it exists. Runs `install --bin` (binary only, rc files untouched) and links `~/.fzf/bin/fzf` into `~/.local/bin`.
  - The rc files load key bindings with `fzf --bash` / `fzf --zsh`, which needs fzf ≥ 0.48. They fall back to the legacy `~/.fzf.{bash,zsh}`.
- **vscode:** **deprecated in favour of VS Code Settings Sync. Do not extend it.**
  - Its setup is commented out in `setup.sh`.
  - Both rc files still source `~/.vscode-extensions-installer` and call `install_extensions` *if that file exists*. It only exists on machines where the old setup created the link.
  - The installer runs only in VS Code terminals (`VSCODE_IPC_HOOK_CLI` set). It marks itself done with `~/.vscode-extensions-installed`.
- **asdf:** not wired in. Ignore it.

## Dependencies

Installed by setup (no root needed): antidote, starship, fzf.

Assumed present, never installed:

| Tool | Needed by |
|---|---|
| `bash`, `git`, `curl` | setup itself |
| `zsh` | the zsh config; it's configured even if zsh isn't installed |
| `ag` (the_silver_searcher) | `FZF_DEFAULT_COMMAND`, so fzf's Ctrl-T / Alt-C file lists |
| `jq`, `tailscale` | `tnsearch`, `tnssh`, `tninfo` in `aliases`; the tailnet machine name in the prompt (optional) |
| Homebrew at `/opt/homebrew` | only on Apple Silicon macOS |

## Rules for changes

- **Never use elevated permissions.** Setup has to work as an unprivileged user on any of the machines listed at the top. Install tools into `~/.local/bin` (or clone into `~/.<tool>` and link the binary there). Any `sudo` call makes setup fail on purpose.
- **Make setup scripts replayable.** Every run of `setup.sh` re-runs every module, so a second run must change nothing unless something is out of date:
  - Clone if missing, otherwise update with `git_update`.
  - Link with `link` only, never a bare `ln -s`, so the manifest knows about it and stale links get pruned.
  - Seed `.local` files with `seed_local`.
  - Updates that fail because of the network should warn and continue. Only a failed first install should `exit 1`.
- **Leave linked rc files alone at install time.** Tool installers that append to `~/.bashrc` or `~/.zshrc` would be writing into tracked files. Use binary-only install modes and add the integration lines to the tracked rc files by hand.
- **Keep both shells in step.** Most shell features exist in both `bashrc` and `zshrc` (for example the FZF block, starship, aliases sourcing). Change both.
- **Set `PATH` only in `localfiles/profile`.** Respect its POSIX, silent and idempotent rules.
- **Shared files must work on macOS and Linux.** Watch for BSD vs. GNU differences (`ls`, `sed -i`, `grep`, `date`).
- **Adding a module:**
  1. Create `dotfiles/<name>/setup.sh` that starts with `#!/usr/bin/env bash`, `set -e`, and sources `$HOME/.dotfiles/dotfiles/utilities.sh` if it needs it.
  2. Add an `echo_section` + `source ~/.dotfiles/dotfiles/<name>/setup.sh` pair inside the run-once block in the root `setup.sh`.
  3. Machines already set up pick it up the next time they run `setup.sh`.
- **Commit messages** follow Conventional Commits (`feat:`, `fix(starship):`, `refactor:` …).
- There are no tests or CI.
