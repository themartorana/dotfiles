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
  utilities.sh           backup_or_rm_symlink, echo_section (shared by setup scripts)
  localfiles/            shell-agnostic files: profile, aliases, CLAUDE.md
  zsh/                   zshenv, zprofile, zshrc, zsh_plugins.txt (antidote)
  bash/                  bash_profile, bashrc
  starship/              setup.sh only; generates ~/.config/starship.toml
  fzf/                   setup.sh only; installs the fzf binary
  vscode/                deprecated (see Modules)
  asdf/                  dormant, not wired into setup.sh; leave alone
.devcontainer/           bare Ubuntu devcontainer; does not run setup
```

## The link + `.local` pattern

Every module follows this pattern:

- **Tracked file → symlink.** `~/.zshrc` → `~/.dotfiles/dotfiles/zsh/zshrc`. Before linking, `backup_or_rm_symlink` removes any existing symlink and renames any regular file to `*.bak`.
- **`*.local` partner → copied once, untracked.** The repo copy (for example `dotfiles/zsh/zshrc.local`) is a template that holds only comments. Setup copies it to `~/.zshrc.local` only if that file doesn't exist yet. It is never overwritten or tracked. Each tracked file sources its `.local` partner, usually last.
- Machine-specific settings, secrets and extra `PATH` entries go in `~/.*.local`, never in tracked files. Because the files are symlinked, editing `~/.zshrc` edits the tracked file in `~/.dotfiles`.

| Home path | Source in repo | `.local` partner |
|---|---|---|
| `~/.profile` | `localfiles/profile` | `~/.profile.local` |
| `~/.aliases` | `localfiles/aliases` | `~/.aliases.local` |
| `~/.claude/CLAUDE.md` | `localfiles/CLAUDE.md` | — |
| `~/.zshenv` | `zsh/zshenv` | `~/.zshenv.local` |
| `~/.zprofile` | `zsh/zprofile` | `~/.zprofile.local` |
| `~/.zshrc` | `zsh/zshrc` | `~/.zshrc.local` |
| `~/.zsh_plugins.txt` | `zsh/zsh_plugins.txt` | — |
| `~/.bash_profile` | `bash/bash_profile` | `~/.bash_profile.local` |
| `~/.bashrc` | `bash/bashrc` | `~/.bashrc.local` |

`localfiles/CLAUDE.md` holds the owner's **global** agent instructions, linked to `~/.claude/CLAUDE.md`. It is not guidance for working in this repo. Edit it only when asked to change those global instructions.

## How `setup.sh` runs

Install: `git clone https://github.com/themartorana/dotfiles.git ~/.dotfiles`, then run `setup.sh`. You can source it (`. ~/.dotfiles/setup.sh`, as the README shows) or run it as a program (`~/.dotfiles/setup.sh`, which is what devcontainer and Codespaces dotfiles support does). The current directory doesn't matter.

In order, the script does this:

1. **If sourced, re-runs itself in a child `bash` and returns its exit code.** This works from bash or zsh. Nothing leaks into the caller's shell, but the caller also doesn't pick up the new `PATH`, so start a new shell afterwards. Everything below therefore always runs in its own bash process.
2. **Finds its own location** (`DOTFILES_SRC`, from `BASH_SOURCE`) and loads `utilities.sh` from there.
3. **Puts `~/.local/bin` first in `PATH`.** Every tool setup installs goes there.
4. **Blocks sudo.** It writes a fake `sudo` to `${XDG_CACHE_HOME:-~/.cache}/dotfiles/sudo-shim` and puts it first in `PATH`. Any `sudo` call exits 1 and is logged to `${XDG_STATE_HOME:-~/.local/state}/dotfiles/setup.log`. An EXIT `trap` removes the fake, including when setup fails.
5. **Run-once check.** Everything below is skipped if `~/.dotfiles/initial-setup-done` exists (that file is gitignored). Re-running setup on a machine that's already set up does nothing. To re-apply, delete that file, or run the individual `dotfiles/<module>/setup.sh` again.
6. **Creates `~/bin`, `~/code`, `~/.config` and `~/.local/bin`.**
7. **Copy vs. in place.** If `DOTFILES_SRC` isn't `~/.dotfiles`, it runs `cp -rv "$DOTFILES_SRC/." ~/.dotfiles`. That's a one-time **copy**, `.git` included, not a link back to the clone. Devcontainers and Codespaces clone dotfiles elsewhere, which is why this step exists. All symlinks point into `~/.dotfiles`.
8. **Links** `profile`, `aliases` and `CLAUDE.md` and seeds their `.local` files.
9. **Sources module setup scripts in this order:** `zsh` → `bash` → `starship` → `fzf`. Both shells are always configured, whatever `$SHELL` is. Setup never runs `chsh`. A comment in `setup.sh` still mentions choosing by `$SHELL`; it's out of date.
10. Creates the check file from step 5. A failure before this point leaves no check file, so the next run tries again.

Module scripts are **sourced** into setup's bash process, not executed. Their `set -e`, exported variables (for example `ZDOTDIR`) and any `exit` affect, or end, the whole setup run, never the user's shell. A module that fails should `exit 1` with a message.

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
  - Plugins are listed in `zsh_plugins.txt`: zsh-async, zsh-completions, zsh-autosuggestions, fast-syntax-highlighting, history-substring-search.
  - Completions also come from `~/.zsh/completions` and `/opt/homebrew/share/zsh/site-functions`.
- **bash:** links files only. Creates `~/.bash_history` if missing.
- **starship:**
  - Installs to `~/.local/bin` with `curl … | sh`, skipped if `starship` is already on `PATH`.
  - Always regenerates `~/.config/starship.toml` from `starship preset pure-preset`, adding `scan_timeout = 500` above it. That key is top-level, so it must come before any `[table]`.
  - The toml isn't tracked. Change the prompt by editing `starship/setup.sh`.
- **fzf:**
  - Clones `~/.fzf`, or `git pull --ff-only` if it exists. Runs `install --bin` (binary only, rc files untouched) and links `~/.fzf/bin/fzf` into `~/.local/bin`.
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
| `jq`, `tailscale` | `tnsearch`, `tnssh`, `tninfo` in `aliases` |
| Homebrew at `/opt/homebrew` | only on Apple Silicon macOS |

## Rules for changes

- **Never use elevated permissions.** Setup has to work as an unprivileged user on any of the machines listed at the top. Install tools into `~/.local/bin` (or clone into `~/.<tool>` and link the binary there). Any `sudo` call makes setup fail on purpose.
- **Make setup scripts idempotent.** Check before cloning or installing. Use `backup_or_rm_symlink` before `ln -s`. Seed `.local` files with `[ ! -f ~/.x.local ] && cp …`.
- **Leave linked rc files alone at install time.** Tool installers that append to `~/.bashrc` or `~/.zshrc` would be writing into tracked files. Use binary-only install modes and add the integration lines to the tracked rc files by hand.
- **Keep both shells in step.** Most shell features exist in both `bashrc` and `zshrc` (for example the FZF block, starship, aliases sourcing). Change both.
- **Set `PATH` only in `localfiles/profile`.** Respect its POSIX, silent and idempotent rules.
- **Shared files must work on macOS and Linux.** Watch for BSD vs. GNU differences (`ls`, `sed -i`, `grep`, `date`).
- **Adding a module:**
  1. Create `dotfiles/<name>/setup.sh` that starts with `#!/usr/bin/env bash`, `set -e`, and sources `$HOME/.dotfiles/dotfiles/utilities.sh` if it needs it.
  2. Add an `echo_section` + `source ~/.dotfiles/dotfiles/<name>/setup.sh` pair inside the run-once block in the root `setup.sh`.
  3. Remember that machines already set up won't run it until their check file is deleted.
- **Commit messages** follow Conventional Commits (`feat:`, `fix(starship):`, `refactor:` …).
- There are no tests or CI.
