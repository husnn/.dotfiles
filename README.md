# Dotfiles

One shared shell, Neovim, and tmux environment for macOS and Linux. Homebrew owns development tools; APT/DNF supplies Linux bootstrap and desktop dependencies. GNU Stow links configuration without copying it.

## Install

Clone anywhere, enter the checkout, and choose a profile explicitly:

```sh
./install.sh --profile core --dry-run
./install.sh --profile core
# Or, on a desktop:
./install.sh --profile desktop
```

Run as your normal user, not with `sudo`. The installer requests elevation only for system prerequisites. macOS needs Apple's Command Line Tools (`xcode-select --install`); full Xcode is optional. Linux needs working `sudo` access for missing native packages. Network access is required for a full installation.

`core` includes CLI development tools, languages, shell, Neovim, tmux, and shared agent links. It installs **no terminal application, desktop font, or graphical clipboard provider**. It is a development-server profile, not a minimal production-server setup. `desktop` adds Ghostty, JetBrains Mono, and Linux X11/Wayland clipboard utilities. WezTerm is opt-in with `--terminal wezterm`.

Subsequent runs reuse the last successful selection:

```sh
./install.sh                          # Fill missing dependencies; no blanket upgrades
./install.sh --only config            # Relink only; no package/runtime/plugin installs
./install.sh --check                  # Read-only dependency and link diagnostics
./install.sh --profile core           # Remove owned desktop links, not installed apps
```

`--dry-run` makes no installation, backup, link, or state changes. Stow simulation is reported as deferred when Stow is absent or legacy links/conflicts must first be resolved. `--check` does not launch configured Neovim or tmux and never installs missing plugins. Configuration-only success means links are valid, not that application dependencies are installed.

### First launch

Open Neovim normally and let the existing Lazy, Mason, and Tree-sitter setup install its plugins and tools, just as before. The installer never starts an editor session or orchestrates its plugin managers; diagnostics only query the executable version. Missing first-launch downloads do not make `--check` fail; setup success means dependencies and configuration are in place, not that every editor plugin has finished installing.

Full setup installs Tmux Plugin Manager (TPM), without starting a tmux server. Start tmux and press **Ctrl-Space, then Shift-I** (`prefix + I`) to install its declared plugins. Configuration-only setup does not install TPM. Existing plugin directories and the Neovim lockfile are preserved.

## Platform coverage

These are **configured installation targets, not a claim of completed clean-machine validation**:

| System | Recognized releases | Desktop terminal route |
| --- | --- | --- |
| macOS | 14, 15, 26, 27 | Homebrew casks |
| Ubuntu | 22.04, 24.04 | Install the selected terminal yourself first |
| Ubuntu | 26.04 | Ghostty via APT; WezTerm is a manual prerequisite |
| Debian | 12, 13 | Install the selected terminal yourself first |
| Fedora | 43, 44 | Install the selected terminal yourself first |

Recognized architectures are x86-64 and ARM64. Intel macOS and macOS 14 have reduced upstream Homebrew support. Actual package availability and OS support can change; see [Homebrew support tiers](https://docs.brew.sh/Support-Tiers). Other distributions and immutable/OSTree systems are not automated targets. `--only config` can work elsewhere with suitable installed dependencies.

For Linux terminal prerequisites, choose a provider from [Ghostty's installation guide](https://ghostty.org/docs/install/binary) or [WezTerm's Linux instructions](https://wezterm.org/install/linux.html), then make `ghostty` or `wezterm` available on PATH. Community repositories/binaries have their own trust and update policy. This installer never adds a PPA/COPR, downloads an unreviewed terminal binary, or silently builds a terminal from source. A missing manual prerequisite stops desktop setup before package changes; core remains available.

JetBrains Mono preserves the existing appearance. Full Nerd Font symbol coverage and real GUI/clipboard behavior require visual validation; they are not guaranteed by a successful command-line check. SSH does not automatically change the chosen profile, and a desktop installation over SSH does not prove a graphical session works.

## Layout and ownership

```text
install.sh          public command, selection, locking, stage orchestration
setup/              packages, runtimes, links, TPM bootstrap, and doctor
packages/           shared + macOS Brewfiles; desktop and APT/DNF lists
config/shared/      application Stow packages
config/macos/       small Mac additions (Ghostty icon/settings)
scripts/            everyday commands on PATH
tools/              private support projects used by scripts
agents/             shared agent instructions and repository-managed skills
templates/          personal configuration examples
docs/               configuration explanations and troubleshooting notes
```

Every destination has one owner. OS packages add distinct include files; they never overwrite shared files. Stow always receives an explicit directory, home target, and `--no-folding`. `.DS_Store` is explicitly ignored. No empty Linux/platform directories are needed when there are no differences.

The installer requires standard `~/.config` and `~/.zshrc` destinations. Custom `XDG_CONFIG_HOME`, `ZDOTDIR`, symlinked destination ancestors, and paths containing tabs/newlines are rejected rather than silently linking the wrong location. Absolute normalized `XDG_DATA_HOME` and `XDG_STATE_HOME` are supported. The checkout pointer lives at `${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/repo`; relink after moving the checkout.

Homebrew owns shared CLI tools, pnpm, Python 3.14, Java, Go, and zsh plugins. NVM owns your development Node/npm versions. The initial choices are in `packages/runtimes.conf`: NVM v0.40.7 and Node 24. Existing NVM defaults are preserved; an unusable or too-old default fails with instructions instead of being silently replaced. pnpm is declared in the shared Brewfile, independently of NVM; switching Node versions does not require reinstalling it. The installer never installs pnpm through npm or applies an NVM-specific pnpm version policy. Homebrew may supply a separate Node dependency for pnpm; existing installations are not removed.

The shell also exposes tools installed with `pnpm add -g` by appending pnpm's global executable directory to PATH, keeping Homebrew and NVM commands ahead of it. This follows pnpm v11+ conventions: `$PNPM_HOME/bin` when set, otherwise `$XDG_DATA_HOME/pnpm/bin` when set, or the platform default (`~/Library/pnpm/bin` on macOS and `~/.local/share/pnpm/bin` on Linux). Shell configuration is managed here; running `pnpm setup` is unnecessary.

Core excludes explicit desktop selections, not every graphics-related transitive library: OpenJDK, for example, can depend on X11/font libraries on Linux. Nothing in core starts a GUI.

Telescope's native extension and parser compilation use a C compiler and make, supplied by Apple's Command Line Tools or Linux build prerequisites. Mason uses `unzip` for downloaded archives: macOS supplies it, while Linux bootstrap explicitly installs it. Linux also supplies XZ extraction for runtime archives. CMake, pkg-config, and Rust/Cargo are not declared requirements.

Avante's first-launch build hook uses its [upstream prebuilt-library script](https://github.com/avante-corp/avante.nvim#installation), rather than compiling with Cargo. That script downloads release artifacts; their availability/version selection follows upstream and is separate from the plugin Git lockfile. No automatic source-build fallback or Rust installation is attempted. All other plugin installation remains the existing first-launch workflow, with the Xcode/headless guards described below.

Diagnostics report Neovim and tree-sitter CLI versions without imposing new editor version gates. Homebrew manifests are rolling dependency declarations, not complete version locks. Routine install does not upgrade existing formulae; explicitly upgrade a tool if its plugin reports an incompatible version. There is no cleanup/uninstall/update-all command. Removing a dependency declaration never uninstalls a previously installed package.

## Personal configuration

Shell loading order is shared environment → optional platform environment → NVM → shared aliases/integrations → existing `~/.env` → `~/.config/shell/local.zsh` → syntax highlighting. Shell startup never installs anything. Existing `~/.env` is untouched; copy `templates/.env.example` yourself if needed, and keep credentials out of Git.

After a successful configuration run, the installer copies `templates/local.zsh.example` to `~/.config/shell/local.zsh` if that file does not already exist. This regular file is personal: Stow does not link it, the installer never overwrites or removes it, and it is not recorded in `links.tsv`. Put personal app shortcuts and machine-specific paths there. Optional command aliases are enabled only when their dependencies exist. `EDITOR` is a single executable or wrapper path, not a shell command containing flags. `newscript` validates its name and finds this checkout through the managed pointer.

### Mutagen sessions

Run `mutagen-create` to select a host and create an interactive synchronization session. Configure host entries in your personal `~/.config/shell/local.zsh`. For example, with `builder=user@build.example.com`, select that entry with `mutagen-create 1`, `mutagen-create builder`, or `mutagen-create user@build.example.com`. You can also supply any SSH alias or `user@hostname` directly. Without a configured list, the command prompts for an SSH host without a default.

The local path defaults to the current directory. The script uses the filesystem's canonical path, preserving actual directory capitalization and resolving directory symlinks. The remote default preserves the project path but replaces your local home directory with `~`, which refers to the remote user's home. For example, `/home/developer/Projects/demo` defaults to `user@build.example.com:~/Projects/demo` when your local home is `/home/developer`. Paths outside your home retain their absolute path. Press Enter at the remote path prompt to retain that path, or enter a different path. The session name then defaults to the lowercase remote directory name. Mutagen requires session names to start with a letter and contain only letters, numbers, or hyphens. If the default is invalid, enter a different session name. Creation requires a final confirmation.

Override the reusable SSH host list in `~/.config/shell/local.zsh`:

```zsh
export REMOTE_SSH_HOSTS='builder=user@build.example.com staging=staging-host'
```

Host numbers follow the list order. Use `--local PATH`, `--remote PATH`, or `--name NAME` for per-command overrides. An absolute remote path requires permission to create and access that path on the remote host. Relative overrides are relative to the remote user's home. Use `--dry-run` to print the command without creating a session. The wrapper disables global Mutagen configuration and defaults to `two-way-safe`. It ignores VCS directories and `.git` files, including worktree pointers to machine-local metadata. When the local machine is macOS, it also ignores `.DS_Store`. Mutagen must already be installed.

Add project-specific ignores with `-i PATTERN...` or `--ignore PATTERN...`, for example: `mutagen-create 1 -i node_modules .venv '*.log'`. Each flag accepts multiple patterns until the next option, and either flag can be repeated. Put the host before the ignore list. Quote wildcard patterns so your shell does not expand them into local filenames. Quote paths containing spaces to keep each path as one pattern. Custom patterns supplement the built-in ignores and apply to both endpoints.

Use `-n NAME` as shorthand for `--name NAME`. Select a synchronization mode with `-m MODE` or `--mode MODE`. The default is `two-way-safe`. Supported modes are `two-way-safe`, `two-way-resolved`, `one-way-safe`, and `one-way-replica`. For one-way modes, the local endpoint is the source and the remote endpoint is the destination. For example: `mutagen-create 1 -i node_modules .venv -n demo -m one-way-safe --dry-run`.

Symlink mode defaults to `portable`, which rejects absolute links and links that escape the synced directory. It does not rewrite machine-specific targets. Extra Mutagen arguments are forwarded after defaults, so explicit scalar and boolean values override them. For example: `mutagen-create 1 --symlink-mode=posix-raw --watch-mode force-poll --dry-run`. Put the host before extra arguments, or omit it to select a host at the prompt. Use `--` to forward the remaining arguments without wrapper parsing. Repeated ignore patterns remain additive. Use `--no-ignore-vcs` to override VCS-directory ignoring, but the explicit `.git` ignore remains.

After creation, the wrapper checks the new session for up to 10 seconds and shows its detailed status. Creation does not guarantee successful synchronization. Reported errors or conflicts produce a nonzero exit status, but the session remains active. The error output includes flush and monitor commands for that session. After fixing the cause, flush requests an immediate sync cycle. Mutagen may retry automatically, and flush does not fix errors or conflicts. If synchronization is still pending, the wrapper says so and prints a monitoring command. The wrapper does not create remote parent directories. A successful initial check does not rule out later errors.

Repository agent skills are linked individually into `~/.agents/skills`, which remains a real directory so machine-local skills can coexist without entering the checkout. Use `newskill <name>` to scaffold and link a repository skill, or run `sync-skills` after adding, removing, or pulling skills. Synchronization never replaces a local skill with the same name.

Ghostty reads shared settings, optional `platform.conf`, then your untracked `~/.config/ghostty/local.conf`. Its shell integration prepares interactive SSH sessions by installing the `xterm-ghostty` terminfo entry in the remote user's account when needed, with an `xterm-256color` fallback when that is unavailable. This wraps interactive `ssh` calls and can leave a small `~/.terminfo` entry on remote hosts. WezTerm retains the shared configuration. Xcode integration loads only on macOS when `xcodebuild -version` succeeds; Linux and Macs without full Xcode get no Xcode plugin setup or dead keymaps. AI credentials and optional Terraform/agent CLIs are not installation requirements.

The installer does not change your login shell, install Xcode, or manage desktop sessions. Select zsh as your login shell yourself if desired. Core clipboard behavior depends on the host terminal/session; remote clipboard forwarding is not promised.

## Existing checkout migration and recovery

The old `shell/`, `nvim/`, `tmux/`, `ghostty/`, and `wezterm/` packages moved under `config/`. Old links can therefore be dangling immediately after updating the checkout. Run from the checkout using Bash before restarting your terminal:

```sh
/bin/bash ./install.sh --profile desktop --only config --dry-run
/bin/bash ./install.sh --profile desktop --only config
```

Use `core` instead if you do not want desktop configuration. The installer recognizes old no-folding links even when their original source directories have disappeared, retires the old managed `.aliases`, and preserves personal files. Earlier folded directory links or symlinked parents require manual reconciliation; they are never traversed blindly. Existing agent sources stay under `agents/`; their links join the same conflict/rollback mechanism. Old `scripts/brew-install`, `nvm-install`, and `agents-install` commands have been removed; use the public installer.

An unmanaged conflict stops setup and leaves that destination untouched. To back up and replace **all conflicting destinations**, rerun with `--backup-and-replace`. Existing settings are not merged into the repository configuration. Preview first with `--backup-and-replace --dry-run` added to your installation command.

The installer prints each original destination and its exact backup location, then the created links and their sources. Backups contain the original files/directories, not just their contents; keep the recovery directory if you may need to restore them. There is no automatic `--adopt`. Profile changes remove only links still verified as owned; personal files and installed packages remain.

State lives in `${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles`. `selection` records the last successful profile, `links.tsv` records owned destinations, and each `recovery.*` directory contains a status, journal, metadata snapshots, and readable recovery instructions. Explicit backups are retained there. Ordinary failures attempt to roll back this run's link changes and preserve the previous selection; package/runtime downloads and installations are not rolled back. Newly created empty directories can remain.

For a killed/interrupted installer, check the PID in `lock/pid` and confirm no installer is running before removing that exact stale lock directory. An `in-progress` recovery record blocks new mutations. Follow its `README.txt`: verify and remove only the recorded newly created links, restore prior links/backups only into absent destinations, restore metadata snapshots, then mark the record `rolled-back`. Never execute the journal or blindly overwrite newer files. Old-link recovery may require restoring the old repository layout (pre-migration revision `313a5cb`); merely recreating its symlinks cannot restore moved source files.

## Maintenance and validation

- Add a shared tool in `packages/shared.Brewfile`; update required diagnostics when appropriate.
- Add a platform tool in the matching Brewfile or native list. Keep package names separate from installation behavior.
- Edit shared application configuration first; add a small platform include only for an actual difference.
- Add a release/distro only after checking prerequisites, terminal/font providers, and documenting real validation coverage.

The repository intentionally has no unit-test suite or GitHub Actions workflow. Syntax checks can be run locally when making changes. Implementation review and successful installation output do not replace clean-machine, recovery, or desktop validation across platforms. See `MIGRATION.md` for the original architectural story and implementation status; this README describes the actual command contract.
