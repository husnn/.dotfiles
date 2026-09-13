# Cross-platform dotfiles migration

Status: implementation delivered; clean-machine and desktop validation remain outstanding. See README.md for the implemented command contract.

### Implementation record

The migration now includes the public Bash installer, split package manifests, APT/DNF bootstrap, NVM-preserving runtime setup, shared/platform Stow packages, legacy-link migration with recovery records, portable shell paths, conditional Xcode integration, TPM bootstrap, read-only diagnostics, and usage/recovery documentation.

The user's implementation direction supersedes the original test-suite proposals below: keep complexity low, orchestrate independent implementation/review agents, write no unit tests, and use a consolidated validation pass rather than repeated per-feature manual testing. No `tests/` directory was added. The optional syntax-only GitHub workflow was subsequently removed at the user's request to avoid runner usage; there is no CI workflow.

Resolved implementation choices:

- Keep helpers at actual responsibility boundaries; no empty platform manifests, profile framework, separate migration engine, or duplicate agent-link implementation.
- Use NVM v0.40.7, initially Node 24; preserve compatible existing defaults. Keep pnpm managed by Homebrew, as in the original setup, with no npm installation or per-NVM-version policy. Report editor/tool versions without introducing new editor version gates.
- Preserve JetBrains Mono. Nerd Font coverage remains a visual validation item.
- macOS terminal installation uses casks. Ubuntu 26.04 Ghostty uses APT; other configured Linux desktop targets require a separately installed terminal on PATH. Third-party providers are not silently added.
- OS shell packages are omitted because the current aliases contain no genuine macOS-only commands. Personal customization has a template and an untracked local file.
- Preserve Neovim's existing first-launch installation. The custom provisioning script and parser-list extraction were removed; Tree-sitter configuration was restored unchanged. Keep Xcode and clipboard platform guards. A subsequent dependency audit switched Avante's build hook to its upstream prebuilt-library script so Rust/Cargo is not required by default. Bootstrap TPM only, then let the user install tmux plugins with prefix + I; no tmux server is started by setup.
- Remove speculative CMake, pkg-config, Rust, and patch requirements. Keep unzip as a system/native dependency for Mason archives rather than installing a duplicate through Homebrew. Retain compiler/make, XZ extraction, and documented bootstrap/desktop requirements. No previously installed packages are uninstalled by these declaration changes.
- Keep state as data, journal exact link changes and backups, commit the successful selection with link ownership, and block unresolved interrupted link transactions. Recovery can leave empty directories; native/package/runtime changes are not rolled back.
- Remove obsolete installation scripts and the root Brewfile; `install.sh` is the only setup entry point. Do not automatically copy a secret environment file or change the login shell.

The historical stages and acceptance criteria below remain useful design context, not claims that fresh installs or GUI checks have passed. Exact configured releases and verification limits are recorded in README.md.

The user's final scope decision supersedes the original editor-provisioning proposals below: the installer manages system dependencies and configuration, while application plugin managers retain ownership of first-launch setup. Successful setup does not certify plugin downloads or builds. The existing shared/platform/desktop Brewfile selection is retained, including terminal-specific manifests.

This plan records the architecture agreed in the migration discussion, proposes the remaining details, and defines the work needed to support macOS, Ubuntu/Debian, and Fedora. It should remain the implementation reference until the new README and tested installer replace its operational guidance.

## 1. The migration story

Today, this repository describes a personal Mac development environment. Most of its configurations are portable, but its installer, shell initialization, and a few integrations assume macOS or a particular home directory. Running the installer elsewhere can partially succeed without producing a usable environment.

The intended result is one repository that describes the same development environment on each supported system. Shared tools use Homebrew; the host's package manager supplies Linux bootstrap prerequisites and desktop integration. Configuration remains editable in the repository and linked with GNU Stow. Small platform additions express real differences without duplicating entire configurations.

A new user chooses a profile on the first run. A desktop installation includes a terminal emulator, fonts, and clipboard integration; a core installation provides the shell and development environment without GUI packages. Subsequent runs remember the successful selection. Installation reports what it selected, what it changed, and whether the resulting environment passed verification.

The migration must also work for the existing Mac. Moving directories must not leave its shell or editor following broken symlinks. Existing personal files and runtime preferences survive, and a failed migration has a documented recovery path.

## 2. Decisions and scope

### Confirmed direction

| Decision                           | Outcome                                                                                |
| ---------------------------------- | -------------------------------------------------------------------------------------- |
| Initial operating systems          | macOS, Ubuntu, Debian, and Fedora                                                      |
| Shared development package manager | Homebrew on macOS and Linux wherever practical                                         |
| Linux native package managers      | APT for Ubuntu/Debian; DNF for Fedora                                                  |
| Package declarations               | Shared declarations plus platform-specific declarations; separate files are preferred  |
| Configuration manager              | Retain GNU Stow                                                                        |
| Configuration composition          | Shared configuration, selected platform additions, then optional personal settings     |
| Server behavior                    | Core profile installs no Ghostty, desktop fonts, or GUI clipboard dependencies         |
| First-run profile                  | Explicit selection; do not default to desktop or infer intent from a graphical session |
| Neovim                             | One shared configuration with conditional Xcode integration                            |
| Personal configuration             | Keep personal settings separate from shared and platform settings                      |
| Hardcoded paths                    | Discover package locations and use user-relative or configurable paths                 |

### Proposed implementation defaults

These are concrete recommendations for implementation, not additional user requirements. Change them if validation reveals a better fit, and record material changes here.

- Use a small Bash installer, compatible with macOS's system Bash 3.2, rather than adding an application framework or requiring a newer interpreter to bootstrap.
- Use `core` and `desktop` as the two profiles. Core still includes the existing development languages and tools; it is not a minimal production-server image.
- Use Ghostty as the default desktop terminal. Retain WezTerm configuration as an explicit alternative.
- Keep NVM for development Node/npm. Keep pnpm as a shared Homebrew dependency, independent of NVM selection.
- Preserve the existing `agents/` directory and its linking model.
- Support standard home/config locations in the first release. Detect non-default XDG config locations or `ZDOTDIR` and give a clear limitation before linking shell/app configuration; do not silently populate an unused path. Supporting arbitrary destinations is a separate extension.
- Keep installation and updates separate. Re-running install fills gaps and validates compatibility; it does not intentionally upgrade all installed tools.
- Treat unsupported OS/distro releases as unsupported for automatic package installation. Configuration-only operation can remain available when its prerequisites and targets are valid.

### Boundaries

Arch, WSL-specific integration, Alpine/musl, NixOS, immutable Linux distributions, and native Windows are outside the initial automated support matrix. No placeholder adapters are needed for them.

The repository manages a user development environment. It does not manage desktop environments, display servers, system services, full Xcode installation, user accounts, or project-specific runtime environments.

“Supported” means a named OS release and architecture passed the relevant checks. It does not mean every machine called Linux will work. List exact tested releases and architectures in the README before claiming release support.

## 3. Current behavior to account for

| Current area                                                            | Migration requirement                                                              |
| ----------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| `install.sh` invokes Brew unconditionally                               | Detect and validate the platform before choosing installation actions              |
| `scripts/brew-install` handles only the Apple Silicon shell environment | Initialize a discovered Brew installation on Intel macOS, Apple Silicon, and Linux |
| Brew failures can be followed by success messages                       | Propagate required failures and report the actual result                           |
| Stow uses its implicit target                                           | Always specify source directory and home target explicitly                         |
| Stow conflicts are hidden and `--adopt` is suggested                    | Show exact conflicts; use explicit backup/replacement when requested               |
| `Brewfile` mixes shared tools, Mole, and desktop casks                  | Split by platform and profile                                                      |
| `.zshrc` uses `/Users/<username>/Library/pnpm` and `/opt/homebrew`      | Replace user- and architecture-specific assumptions                                |
| Python setup looks up `python`, while Brew declares `python@3.14`       | Derive paths from the actual declared formula                                      |
| Shell and `newscript` assume `~/.dotfiles`                              | Resolve the checkout location independently of its directory name                  |
| `xcodebuild.nvim` is unconditional                                      | Gate plugin enablement and its keymaps                                             |
| Ghostty mixes shared settings and Mac settings                          | Split shared content from platform additions                                       |
| NVM setup selects latest LTS and resets the default on every run        | Preserve existing defaults; distinguish initial selection from upgrades            |
| TPM provisioning depends on a running tmux process                      | Bootstrap TPM only; install plugins explicitly with prefix + I                     |
| Aliases reference tools absent from the Brewfile                        | Distinguish required commands from optional integrations                           |
| Config directories will move                                            | Migrate existing links, including stale links from an already-updated checkout     |

## 4. Repository structure

```text
.
├── install.sh                     # Public entry point and argument handling
├── README.md                      # Setup, supported systems, daily workflows
├── MIGRATION.md                   # This plan
├── AGENTS.md
├── packages/
│   ├── shared.Brewfile
│   ├── macos.Brewfile
│   ├── linux.Brewfile             # Only if Linux-only Brew dependencies exist
│   ├── desktop/
│   │   ├── macos.Brewfile
│   │   └── linux.Brewfile         # Only if suitable Brew packages exist
│   ├── native/
│   │   ├── debian/
│   │   │   ├── bootstrap.txt
│   │   │   └── desktop.txt
│   │   └── fedora/
│   │       ├── bootstrap.txt
│   │       └── desktop.txt
│   └── runtimes.conf             # Validated version selections, not arbitrary shell code
├── setup/
│   ├── platform.sh               # OS, architecture, distro/release detection
│   ├── packages.sh               # Homebrew and native package orchestration
│   ├── profiles.sh               # Explicit package/config selections
│   ├── links.sh                  # Preflight, Stow, owned-link reconciliation
│   ├── migrate.sh                # Legacy layout migration and recovery
│   ├── runtimes.sh               # NVM and Node/npm
│   ├── tmux.sh                   # TPM bootstrap only
│   ├── agents.sh                 # Existing agent link behavior
│   └── doctor.sh                 # Read-only environment checks
├── config/
│   ├── shared/
│   │   ├── shell/
│   │   ├── nvim/
│   │   ├── tmux/
│   │   ├── ghostty/
│   │   └── wezterm/
│   ├── macos/
│   │   ├── shell/
│   │   └── ghostty/
│   └── linux/
│       └── shell/                # Only where Linux-specific content is needed
├── scripts/                      # User commands such as ai-commit and newscript
├── agents/                       # Preserve current skill/instruction paths
├── templates/                    # Examples for untracked personal configuration
├── tests/
└── .github/workflows/            # Automated checks when implemented
```

Each application directory inside a `config` layer is a Stow package and retains the target-relative tree, such as `nvim/.config/nvim/init.lua`. Only selected layers are passed to Stow; never stow the repository root.

Create files because they contain necessary behavior, not to fill the tree. Split a helper further only when its size or responsibilities justify it. Distro-specific Ghostty installation may require a narrowly scoped helper in addition to a package-name list.

Daily commands stay in `scripts/`. Installation internals move to `setup/` and do not appear as accidental user commands on PATH. Existing `brew-install`, `nvm-install`, and `agents-install` command names may have temporary forwarding wrappers; they must use the new implementation rather than retaining duplicate logic.

## 5. Package architecture

### Ownership

| Category                        | Owner                                   | Notes                                                                                |
| ------------------------------- | --------------------------------------- | ------------------------------------------------------------------------------------ |
| Shared CLI applications         | Homebrew                                | Git, Neovim, tmux, Stow, eza, zoxide, bat, fzf, ripgrep                              |
| Shared development dependencies | Homebrew                                | Go, tree-sitter CLI, Python, uv, OpenJDK; validate minimum versions                  |
| Zsh plugins                     | Homebrew                                | Locate scripts through the discovered prefix                                         |
| Linux bootstrap                 | APT/DNF                                 | Compiler/build tools, Git, curl, certificates, process/file utilities, zsh as needed |
| macOS bootstrap                 | System tools / Apple command-line tools | Detect prerequisites and report installation steps when unavailable                  |
| Node and npm                    | NVM                                     | Do not replace the user's existing default on routine install                        |
| pnpm                            | Homebrew                                | Shared formula; no per-NVM-version installation                                      |
| Editor plugins                  | Lazy                                    | Preserve `lazy-lock.json`                                                            |
| Language servers and formatters | Mason where configured                  | Install after required runtimes are available                                        |
| macOS-only tools                | macOS Brewfile                          | Mole; no Linux substitute is necessary                                               |
| Desktop applications and fonts  | Platform desktop provider               | macOS casks; verified Linux package routes                                           |
| Agent CLIs / Terraform aliases  | Optional integrations initially         | Presence of an alias does not authorize installing every referenced tool             |

Some native bootstrap tools and Brew tools necessarily overlap, particularly Git. The system copy bootstraps Brew; the Brew copy becomes the intended interactive development command. Report executable provenance in doctor output when an unexpected executable shadows the intended one.

Transitive package dependencies can introduce additional runtimes; Homebrew pnpm may bring its own Node dependency. The guarantee is intentional ownership, not that only one Node or Python binary exists anywhere on disk. NVM manages development Node/npm; Homebrew manages pnpm.

### Manifest selection

For core: select `shared.Brewfile` plus the current OS Brewfile when present. For desktop: add the selected terminal/font desktop declarations and native desktop requirements. Invoke Bundle with explicit `--file` paths; no dependence on the current working directory or a global Brewfile.

Use plain lists for native package names and keep behavior in adapter functions. Ignore blank/comment lines, validate names, and pass arguments as an array. Do not execute list content with `eval` or unrestricted shell sourcing.

Ubuntu and Debian share the APT implementation, but `ID` and `VERSION_ID` from `/etc/os-release` remain distinct inputs. Add release-specific declarations only where verified package differences require them. Do not assume package-manager presence proves distro support or select whichever manager appears first on PATH.

### Bootstrap and Brew discovery

1. Validate OS, architecture, distro release, profile, target locations, and available privileges.
2. Inspect an existing `brew` command and its reported prefix/platform. Detect a mismatched installation rather than installing a second copy blindly.
3. If absent, install native prerequisites and use Homebrew's documented installer.
4. Initialize Brew in the current installer process; do not assume a new shell is needed to continue.
5. Establish persistent shell initialization through managed configuration without appending duplicate lines on every run.

Known prefixes are discovery candidates: `/opt/homebrew`, `/usr/local`, and `/home/linuxbrew/.linuxbrew`. They must not become hardcoded Java/Python/plugin paths. Existing nonstandard prefixes require validation against the support policy.

Run the installer as the user. Elevate only native/bootstrap operations that require it. Do not run Brew, Stow, editor provisioning, or writes to the user's configuration as root.

### Versions, updates, and package removal

Homebrew is a rolling package manager, and Brewfiles do not lock arbitrary versions, including pnpm. Consistent installation does not promise byte-identical environments. Use supported versioned formulae where meaningful, retain plugin locks, and record initial NVM/Node selections explicitly.

For first installation, choose tested stable runtime versions during implementation and record them. For an existing NVM environment, preserve the default unless the user explicitly requests a change. If a required minimum is not met, report it and provide the specific update action; do not silently switch unrelated defaults.

Use Bundle's no-upgrade behavior for routine installation. A future explicit update command should scope updates to selected dependencies and state that their versions can change. Do not run automatic cleanup: when manifests are split, cleanup against one file could remove dependencies declared in another, as well as unrelated user packages.

Removing a profile or configuration package does not uninstall applications. Package removal is a separate, explicitly selected operation outside the first migration.

## 6. Profiles and command behavior

| Selection              | Behavior                                                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `--profile core`       | Development tools, shell, Neovim, tmux, scripts, agent links; no GUI dependencies                                        |
| `--profile desktop`    | Core plus the selected terminal, fonts, and desktop clipboard providers                                                  |
| `--terminal ghostty`   | Proposed desktop default                                                                                                 |
| `--terminal wezterm`   | Optional alternative after its installation route is validated                                                           |
| `--dry-run`            | Report selection, actions, and known conflicts without downloads, installs, links, or state writes                       |
| `--only config`        | Require existing Stow; link/reconcile selected configuration without installing packages/plugins                         |
| `--check`              | Run read-only verification; never bootstrap missing dependencies                                                         |
| `--backup-and-replace` | Back up all conflicting destinations, then replace with links; print backup locations and do not merge existing settings |

These command names are proposed API contracts. Implement only documented flags, reject unknown flags and contradictory combinations, and describe the effects of each in `--help`.

On a first run without a stored selection, require `--profile` and print the two choices. Do not infer a profile from `$DISPLAY`, `$WAYLAND_DISPLAY`, SSH, or the OS. Later runs reuse the last successfully applied selection; an explicit selection changes it.

A dry run on a machine without Stow can inspect the planned target map and report that Stow's own simulation is unavailable. It must not bootstrap Stow just to claim a complete preflight. Read-only commands must also avoid app/plugin initialization paths that auto-install dependencies.

Store non-secret state under `${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/`. Record schema version, checkout location, successfully selected profile/terminal, managed links, and migration/recovery metadata. Parse state as data. State establishes intent, but every destructive link operation still verifies the current filesystem target.

Keep an in-progress journal separately from the last successful selection. Write state atomically, prevent concurrent installer runs, and release the lock after success or failure. Stale locks need a clear diagnostic and a verified recovery procedure.

## 7. Stow composition and ownership

### One owner for each destination

The installer builds a complete source-to-destination map for all selected shared and OS packages before changing links. Duplicate destination files are a planning error, even if both sources happen to have identical content. Stow does not merge files and platform layers do not overwrite shared files.

Use explicit paths and `--no-folding`:

```sh
stow --dir="$DOTFILES_DIR/config/shared" --target="$HOME" --no-folding shell nvim tmux
stow --dir="$DOTFILES_DIR/config/macos" --target="$HOME" --no-folding shell
```

The second command is an example for a Mac with a platform shell package. Package selection must come from an explicit allowlist/profile mapping, not arbitrary directory discovery.

For Ghostty, shared owns `.config/ghostty/config.ghostty`; macOS owns `.config/ghostty/platform.conf` and its icon. Shared configuration includes:

```ini
config-file = ?platform.conf
config-file = ?local.conf
```

On Linux, omit `platform.conf` when no platform additions are needed. `local.conf` is untracked and owned by the user. Includes express precedence; Stow only supplies links.

### Conflict and reconciliation behavior

- Validate destination ancestors as well as leaf files; a symlinked parent can redirect writes outside the intended directory.
- Treat an existing verified link to the selected source as already satisfied.
- Report unmanaged files, directories, and links as conflicts, with source and target paths visible.
- Do not hide Stow errors, automatically run `--adopt`, or overwrite a real configuration file.
- When backup is selected, move only the resolved conflicting targets, preserve relative paths, and record restoration information in a unique backup directory under the state root.
- Reject overlapping/broad backup targets; do not move all of `.config` to solve one application's conflict.
- Simulate selected Stow operations after prerequisites are available and before link mutation. The combined destination map also catches cross-layer collisions that independent simulations could miss.
- On profile changes, remove only verified links for deselected packages. Retain personal files, plugin data, and installed applications.
- Revalidate the target immediately before changing it; filesystem state can change after preflight.
- If a later link step fails, undo link changes from the current attempt where verified, retain recovery records, and report any remaining partial state.

Ensure ignore rules still exclude `.DS_Store` after introducing multiple Stow directories. Do not assume the root `.stow-local-ignore` automatically applies to the new directory layout. Test the selected ignore mechanism against every layer.

### Migrating the existing layout

Maintain an explicit mapping from legacy package roots (`shell`, `nvim`, `tmux`, `ghostty`, `wezterm`) to new roots. Capture existing managed links and any conflicts before the directory move during local development.

The installer must also support a user who has already pulled the new layout: their old symlinks may now be dangling and the old Stow source directories may no longer exist. In that case, use the reviewed legacy mapping and the literal/resolved link target to establish ownership. Do not require running `stow -D` against a directory that has already disappeared.

Remove/recreate only links proven to target legacy paths in this checkout or a verified prior checkout. Ambiguous links are conflicts. Preserve executable modes, hidden files, the Neovim lockfile, local overrides, and environment files. Agent links remain unchanged when their sources have not moved.

Recovery restores the previous recorded links and any explicitly backed-up files. If restoring legacy links requires the previous repository layout, document the corresponding revision and restore that layout before recreating links. This is a configuration migration rollback, not a rollback of native/Brew package installations.

## 8. Shell, aliases, and paths

### Loading structure

The shared shell package contains a short `.zshrc` and `.config/shell/{env,aliases,interactive}.zsh`. The selected OS package supplies `.config/shell/platform.zsh` when necessary. After successful setup, the installer creates an empty, untracked `.config/shell/local.zsh` when absent and never overwrites or removes it.

Define the startup order explicitly:

1. Establish user configuration paths and the managed checkout location.
2. Discover/initialize Brew and shared base PATH entries.
3. Apply platform environment defaults and derive declared runtime/formula paths.
4. Initialize NVM without changing its saved default.
5. Load aliases and interactive integrations, checking prerequisites.
6. Load existing `~/.env` for backward compatibility, then optional personal overrides.
7. Initialize syntax highlighting after interactive customization.

Avoid unnecessary subprocesses during startup: discover Brew once, reuse its prefix, and resolve additional formula prefixes only when needed. Do not put interactive initialization in `.zshenv`. Test login and non-login interactive shells so behavior does not depend on one particular terminal launching mode.

Use quoted paths and zsh's unique PATH array behavior or equivalent deduplication. Missing optional integrations should not emit startup errors; doctor distinguishes optional absences from broken required dependencies. Sourcing configuration never installs packages or downloads plugins.

### Existing settings

| Setting                          | Destination/behavior                                                                           |
| -------------------------------- | ---------------------------------------------------------------------------------------------- |
| Git/Neovim/tmux aliases          | Shared alias file                                                                              |
| Ghostty configuration alias      | Only available when its integration is selected and usable                                     |
| macOS commands such as `open`    | macOS platform file if introduced                                                              |
| Terraform and AI CLI helpers     | Optional aliases/functions with actionable missing-command errors                              |
| Personal machine preferences     | Installer-created, untracked `local.zsh` that remains user-owned                               |
| `~/.dotfiles/scripts`            | Managed checkout pointer, updated on successful relink                                         |
| `/opt/homebrew/opt/openjdk`      | Selected formula prefix; expose appropriate PATH and `JAVA_HOME`                               |
| `brew --prefix python`           | Match the actual declared Python formula and validate interpreter resolution                   |
| `/Users/<username>/Library/pnpm` | Remove obsolete global path; only configure `PNPM_HOME` if the chosen installation requires it |
| `NVM_DIR`                        | Honor an existing value; otherwise use `$HOME/.nvm`                                            |
| Zsh plugins                      | Read from discovered Brew installation; quote and check files                                  |
| `OPENCODE_ENABLE_EXA`            | Audit whether an exported variable is intended; preserve behavior only when meaningful         |

Provide a stable managed checkout symlink, for example `${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/repo`, so the shell and user scripts need not parse installer state or know the clone's name. Validate conflicts at that pointer too. Moving the checkout requires rerunning configuration linking; it is not automatically location-independent after an arbitrary filesystem move.

Update `newscript` to use this location and validate names so they cannot escape the scripts directory. Handle editor invocation deliberately: a single executable and an editor command with arguments are different contracts, and must not be conflated through unsafe evaluation.

Do not automatically change the user's login shell. Install/check zsh where needed, document how to select it, and keep shell registration/account changes explicit.

## 9. Neovim and tmux

### Xcode integration

Retain one shared `xcodebuild.lua`. Use an enablement predicate that checks macOS and the presence of `xcodebuild`. Since setup and keymaps live in the plugin's `config` callback, disabled platforms receive neither setup nor dead shortcuts.

The executable can be a system stub or point at Command Line Tools without a full Xcode installation. Doctor must check the selected developer directory and whether Xcode's build tooling is usable. Refine the enablement check if integration testing shows the plugin errors with the executable-only guard; avoid a costly subprocess on every startup if the plugin can remain safely inactive until invoked.

Full Xcode is an optional capability independent of core/desktop. Linux excludes the plugin; macOS without Xcode retains a working editor and receives optional setup guidance. Do not install Xcode automatically.

### Editor dependency readiness

- Retain existing plugin selections and `lazy-lock.json` during the platform migration.
- Validate the Neovim API version required by the actual configuration, plus the parser/compiler and tree-sitter CLI requirements of the locked plugins.
- Provide compiler, make, archive/download utilities, and required language runtimes before plugin builds or Mason installs.
- Audit each native-build plugin, including Telescope's fzf extension and Avante, for dependencies on both platforms.
- Keep first-launch plugin/tool installation inside Neovim's existing configuration. Do not launch a headless editor from the installer or duplicate plugin-manager logic.
- Keep credentials out of installer state and logs. Missing AI provider credentials disable availability of that optional feature, not the editor itself.
- Classify missing optional features separately from required build/provisioning failures.

### Clipboard and terminal behavior

Keep tmux keybindings, themes, and navigation shared. Desktop setup supplies verified X11/Wayland clipboard providers; where both sessions are supported, install both lightweight providers rather than binding configuration permanently to the session observed at installation.

Core installs no GUI clipboard dependencies. Standard editor/tmux operations must work without a graphical clipboard. Document remote clipboard behavior separately and use terminal clipboard support only where validated; do not promise local clipboard access over arbitrary SSH sessions.

Bootstrap TPM without starting or modifying a tmux session. The user installs declared plugins with prefix + I after starting tmux; ordinary configuration tolerates TPM being absent after a configuration-only setup.

## 10. Desktop integration

Ghostty's macOS cask is not a general Linux installation strategy. For each supported Ubuntu, Debian, and Fedora release, verify package availability, architecture, minimum compatible version, provider, and update mechanism.

Prefer a suitable native distro package. If unavailable, select a specific maintained upstream/community route and document the trust and update implications. Do not silently add arbitrary PPAs/COPRs or fall back to compiling Ghostty from source. An unavailable required desktop package should produce an actionable failure and leave core/profile state accurately reported.

Install the declared font on desktop systems and refresh the Linux font cache when needed. Verify the configured family and weights. The existing icon-heavy eza/Neovim/tmux setup may require Nerd Font coverage beyond ordinary JetBrains Mono; decide whether to use a Nerd Font variant consistently or provide explicit symbol fallback. This is an appearance decision requiring a desktop check.

Keep macOS `.icns` assets in the macOS Ghostty package. Load shared settings, then platform settings, then personal settings through Ghostty's supported include mechanism. Validate using the installed version's configuration checker where available, followed by a real launch test.

Keep WezTerm opt-in. If its installer route is not part of the first supported release, retain its configuration and clearly document manual application installation rather than accepting a flag that cannot fulfill its promise.

## 11. Installer reliability and developer experience

Use explicit stage boundaries:

```text
Resolve selection and platform
  → Validate target paths, ownership, and known conflicts
  → Install native prerequisites and initialize Brew
  → Install selected package manifests
  → Prepare required runtimes
  → Simulate and apply configuration links / legacy migration
  → Bootstrap TPM (Neovim retains its first-launch setup)
  → Verify required capabilities
  → Commit successful selection and report
```

Use strict shell options where appropriate, but explicitly handle failures in commands, functions, pipelines, and conditional contexts. `set -e` alone does not establish correct failure behavior. Report the failing stage, relevant command/output, and the rerun or recovery action.

Keep logs useful without dumping environment variables, tokens, or credential files. Respect noninteractive operation: fail clearly when a prerequisite requires interaction instead of hanging. Use `printf` for portable output, quote all filesystem paths, preserve executable modes in Git, and avoid GNU-only flags without a tested fallback.

Do not automatically retry arbitrary mutations. Retry bounded transient downloads only when safe; the whole installer should be restartable based on actual state. A failed run must not overwrite the last successful profile with a new profile that never completed.

Document four ordinary contribution workflows in the README:

1. Add a shared CLI tool: update the shared Brewfile and dependency checks if necessary.
2. Add an OS-only tool: update the matching platform declaration and support notes.
3. Change configuration: edit its shared package; add a small platform include only when needed.
4. Add a distro/release: implement/verify prerequisites and desktop packages, then extend the tested support matrix.

Doctor should report OS/release/architecture, selected profile, Brew location, required executable paths/versions, link integrity, runtime resolution, first-launch guidance, optional Xcode availability, and desktop capability checks. Plugin readiness is not an installation gate. State clearly when a GUI/clipboard test cannot run in the current session; absence of a desktop session over SSH is not proof that desktop installation failed.

## 12. Implementation sequence and stories

### Stage 1: Establish selection and truthful results

Story: As an existing Mac user, I can run the installer and trust its result while the current configuration layout remains usable.

- Extract platform detection and stage helpers; define Bash compatibility.
- Add profile parsing and first-run selection requirements.
- Stop on required Brew/runtime failures; preserve useful output.
- Define state schema, in-progress journal, and read-only planning/check behavior.
- Add focused tests for selection, failure propagation, and unsupported platforms.

Acceptance: invalid selections fail before mutation; core never selects desktop dependencies; simulated package failures cannot produce a success result.

### Stage 2: Separate declarations and support Linux bootstrap

Story: As an Ubuntu, Debian, or Fedora user, I can install the shared CLI environment through the same Brew manifests as macOS.

- Split the Brewfile and move setup internals out of everyday scripts.
- Implement APT/DNF prerequisites and Brew discovery/initialization.
- Verify formula names and native dependencies on selected release/architecture targets.
- Establish runtime version policy; preserve existing NVM defaults and resolve pnpm ownership.
- Keep current macOS behavior covered while adding Linux cases.

Acceptance: supported clean machines reach the required CLI toolchain; a repeat run preserves runtime defaults and does not request a blanket upgrade.

### Stage 3: Migrate links and shell configuration

Story: As a current user, I can adopt the new layout without losing personal configuration or leaving broken links.

- Build destination-map validation and Stow simulation/reconciliation.
- Implement legacy ownership mapping, backups, journal, and recovery before moving directories.
- Move application packages into shared/platform directories.
- Add the checkout pointer and update runtime script paths.
- Split shell loading and replace all hardcoded user/package prefixes.
- Preserve `~/.env`, agent sources, plugin locks, and executable modes.

Acceptance: both pre-move and already-pulled legacy layouts migrate; unmanaged conflicts remain untouched unless explicit backup was requested; repeated linking is a no-op; paths containing spaces work.

### Stage 4: Complete platform capabilities

Story: As a desktop user, I receive a usable terminal/editor environment; as a core user, I receive no GUI dependencies or broken Mac integrations.

- Select and implement Ghostty/font routes for each supported distro release.
- Split Ghostty settings and validate fonts and icon coverage.
- Gate Xcode integration and verify full-Xcode readiness separately.
- Preserve editor first-launch setup and provide TPM bootstrap with prefix + I instructions.
- Validate desktop and remote clipboard behavior.
- Finish optional alias/helper handling and personal override templates.

Acceptance: Linux Neovim starts without Xcode setup/keymaps; macOS without Xcode remains usable; desktop rendering and clipboard checks pass in real sessions; core works without a display server.

### Stage 5: Publish support and maintenance workflows

Story: As a maintainer, I can add a tool, update a supported environment, or diagnose a failed installation using documented commands and checks.

- Complete README usage, exact support matrix, ownership rules, local overrides, and recovery instructions.
- Add automated checks and clean-machine integration coverage.
- Verify profile changes and configuration-only installs.
- Remove obsolete wrappers only after documenting replacement commands.
- Audit documentation against actual CLI behavior and mark this plan's stages complete with evidence.

Acceptance: a reader can install, rerun, inspect, and recover using only repository documentation; every claimed platform has recorded validation results.

## 13. Verification strategy

### Automated checks

- Bash syntax and ShellCheck; zsh syntax for shell configuration.
- Platform/profile selection using fixtures for Ubuntu, Debian, Fedora, macOS architectures, unsupported systems, and absent release metadata.
- Real Stow tests in disposable directories: shared/platform composition, duplicate targets, existing files, symlinked ancestors, stale links, spaces, repeated runs, deselection, backup, and interrupted migration recovery.
- Package command tests using controlled command shims: selected manifests, correct native adapter, missing Brew, failure propagation, no downloads/writes during dry run, and no upgrades/cleanup during ordinary installation.
- Shell startup checks with missing optional tools, existing local overrides, login/non-login shells, and repeated sourcing without PATH growth.
- Core integration runs on Ubuntu, Debian, and Fedora environments plus macOS. Containers cover CLI behavior but not full desktop integration or every bootstrap privilege path.
- Neovim/tmux provisioning and startup tests with bounded completion checks; ensure read-only doctor does not trigger auto-install hooks.

### Real machine/session checks

- Fresh macOS and supported Linux desktop installations.
- Both Wayland and X11 where claimed by the distro support matrix.
- Ghostty launch, font weights, symbols, keybindings, shell startup, and clipboard round trips.
- macOS with and without full Xcode selected.
- Core installation over SSH or without graphical session variables.
- Desktop installation initiated over SSH, with GUI verification recorded as deferred until tested locally.
- Existing Mac migration, including conflicts and a checkout updated before migration.

Start with the architectures actually available for testing. Do not claim Linux ARM64 or Intel macOS coverage merely because the installer recognizes the architecture. Record narrower coverage and expand it when verified.

### Completion criteria

- Every supported target can complete a clean install of its advertised profile.
- No macOS-specific path or command runs on Linux without an explicit platform guard.
- Core excludes desktop packages and configuration links.
- Required failures produce nonzero exit status and a useful stage report.
- Reruns preserve personal configuration, runtime defaults, and unrelated packages.
- Legacy migration and recovery work with real Stow, not only mocked commands.
- Shared/platform destination ownership is unambiguous.
- Documentation identifies untested or deferred capabilities honestly.

## 14. Remaining decisions and validation gates

These items must be resolved before their implementation stage is considered complete. They do not block drafting the architecture or implementing independent stages.

| Decision                            | Recommended direction                                                                     | Resolution gate                                   |
| ----------------------------------- | ----------------------------------------------------------------------------------------- | ------------------------------------------------- |
| Exact OS releases and architectures | Select currently maintained releases actually available for testing                       | Stage 2, then published in Stage 5                |
| Ghostty provider per Linux release  | Suitable native package first; explicitly documented community provider when necessary    | Stage 4; verify availability and update ownership |
| Font family and symbols             | Prefer consistent glyph coverage; compare JetBrains Mono with its Nerd Font variant       | Stage 4 desktop review                            |
| Runtime versions                    | Record initial NVM/Node selections; preserve existing defaults; pnpm follows Homebrew     | Resolved                                          |
| Node switching and pnpm             | pnpm remains managed by Homebrew, independent of NVM selection                            | Resolved                                          |
| Minimum Neovim/build-tool versions  | Derive from the actual locked configuration and native-build dependencies                 | Stages 2 and 4                                    |
| Xcode guard strength                | macOS plus executable initially; refine if setup is unsafe with only the system stub      | Stage 4                                           |
| WezTerm automated installation      | Implement only after its Linux providers are validated; otherwise document manual install | Stage 4                                           |
| Non-default XDG/ZDOTDIR             | First release detects and explains unsupported target layouts before linking              | Stage 3                                           |
| Optional command dependencies       | Terraform/agent CLIs remain optional unless explicitly added to the environment scope     | Stages 2 and 4                                    |
| Update command scope                | Define a separate explicit operation after install semantics are stable                   | Stage 5 or follow-up                              |
| State and migration schema          | Versioned data with verified ownership and an interruption journal                        | Stages 1 and 3                                    |

## 15. Reference material

These sources informed the design. Recheck provider availability and version requirements when implementing; upstream packaging can change.

- [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux): bootstrap requirements, recommended prefix, and shell initialization.
- [Homebrew support tiers](https://docs.brew.sh/Support-Tiers): OS, architecture, prefix, and support limitations.
- [Homebrew Bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile): explicit manifests, no-upgrade behavior, cleanup semantics, and absence of a Brewfile version lock.
- [Ghostty installation](https://ghostty.org/docs/install/binary): macOS distribution and Linux distro/community packages.
- [Ghostty configuration includes](https://ghostty.org/docs/config/reference#config-file): optional files and include precedence.
- [NVM](https://github.com/nvm-sh/nvm): user-scoped Node version management.
- [tmux-yank](https://github.com/tmux-plugins/tmux-yank): platform clipboard providers.

The source files referenced in the current-state inventory are the repository's `install.sh`, `Brewfile`, `scripts/`, `shell/`, `ghostty/`, `tmux/`, and `nvim/` as inspected when this plan was written. Implementation should preserve unrelated changes made after that inspection.
