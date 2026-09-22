#!/bin/bash
# Public entry point. Keep bootstrap compatible with macOS Bash 3.2.
set -Eeo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROFILE=''
TERMINAL=''
DRY_RUN=0
CHECK=0
CONFIG_ONLY=0
BACKUP_AND_REPLACE=0
STAGE=arguments
LOCKED=0
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"

log() { printf '%s\n' "$*"; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
    printf '%s\n' \
        'Usage: ./install.sh [--profile core|desktop] [options]' \
        '' \
        '  --profile core|desktop   Required initially; reuse successful selection later' \
        '  --terminal ghostty|wezterm  Desktop terminal (default: ghostty)' \
        '  --only config           Link configuration; do not install packages or plugins' \
        '  --dry-run               Inspect selection and conflicts without changing anything' \
        '  --check                 Read-only checks; do not initialize editor plugins' \
        '  --backup-and-replace    Back up existing conflicting files, then replace with links' \
        '                          Applies to all conflicts; settings are not merged' \
        '  -h, --help              Show this help' \
        '' \
        'Core contains development tools but no GUI packages or terminal configuration.' \
        'Desktop includes core, a terminal, fonts, and Linux clipboard utilities.'
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --profile|--terminal|--only)
            [ "$#" -ge 2 ] || die "$1 requires a value"
            case "$1" in
                --profile) PROFILE=$2 ;;
                --terminal) TERMINAL=$2 ;;
                --only) [ "$2" = config ] || die '--only accepts config'; CONFIG_ONLY=1 ;;
            esac
            shift 2 ;;
        --dry-run) DRY_RUN=1; shift ;;
        --check) CHECK=1; shift ;;
        --backup-and-replace) BACKUP_AND_REPLACE=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown argument: $1 (see --help)" ;;
    esac
done
[ "$CHECK" -eq 0 ] || { [ "$DRY_RUN" -eq 0 ] && [ "$CONFIG_ONLY" -eq 0 ] && [ "$BACKUP_AND_REPLACE" -eq 0 ]; } || die '--check cannot be combined with mutation/planning options'

# Paths also appear in line-oriented recovery records: reject ambiguous values.
for directory in "$HOME" "$DOTFILES_DIR" "$STATE_DIR" "${XDG_DATA_HOME:-$HOME/.local/share}"; do
    case "$directory" in /*) ;; *) die "Expected an absolute path: $directory" ;; esac
    case "$directory" in
        *$'\t'*|*$'\n'*|*$'\r'*) die 'Paths must not contain tabs or newlines' ;;
    esac
done
[ "$HOME" != / ] || die 'HOME cannot be /'
[ "${XDG_CONFIG_HOME:-$HOME/.config}" = "$HOME/.config" ] || die 'Custom XDG_CONFIG_HOME is not supported; configuration targets ~/.config'
[ "${ZDOTDIR:-$HOME}" = "$HOME" ] || die 'Custom ZDOTDIR is not supported; shell configuration targets ~/.zshrc'

SAVED_PROFILE=''
SAVED_TERMINAL=''
if [ -f "$STATE_DIR/selection" ]; then
    schema=''
    while IFS='=' read -r key value; do
        case "$key" in
            schema) schema=$value ;;
            profile) SAVED_PROFILE=$value ;;
            terminal) SAVED_TERMINAL=$value ;;
            '') ;;
            *) die "Unknown state field '$key' in $STATE_DIR/selection" ;;
        esac
    done < "$STATE_DIR/selection"
    [ "$schema" = 1 ] || die 'Unsupported selection state schema'
    case "$SAVED_PROFILE:$SAVED_TERMINAL" in
        core:none|desktop:ghostty|desktop:wezterm) ;;
        *) die "Invalid saved selection in $STATE_DIR/selection" ;;
    esac
fi
PROFILE=${PROFILE:-$SAVED_PROFILE}
case "$PROFILE" in
    core)
        [ -z "$TERMINAL" ] || die '--terminal requires --profile desktop'
        TERMINAL=none ;;
    desktop)
        if [ -z "$TERMINAL" ]; then
            if [ "$SAVED_PROFILE" = desktop ]; then TERMINAL=$SAVED_TERMINAL; else TERMINAL=ghostty; fi
        fi
        case "$TERMINAL" in ghostty|wezterm) ;; *) die 'Choose --terminal ghostty or wezterm' ;; esac ;;
    '') die 'Choose --profile core or --profile desktop on the first run (see --help)' ;;
    *) die 'Choose --profile core or --profile desktop' ;;
esac

for helper in platform packages runtimes links tmux doctor; do
    # shellcheck disable=SC1090
    source "$DOTFILES_DIR/setup/$helper.sh"
done

cleanup() {
    local status=$?
    trap - EXIT
    if [ "$status" -ne 0 ] && [ "$LOCKED" -eq 1 ]; then
        printf 'Stopped during %s. Last successful selection was not changed.\n' "$STAGE" >&2
        rollback_links || printf 'Automatic link recovery incomplete; inspect the recovery directory.\n' >&2
    fi
    if [ "$LOCKED" -eq 1 ]; then
        rm -f "$STATE_DIR/lock/pid"
        rmdir "$STATE_DIR/lock" || true
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

STAGE=preflight
detect_platform
log "Platform: $DISTRO $VERSION_ID ($ARCH)"
log "Selection: $PROFILE; terminal: $TERMINAL"
plan_links

if [ "$CHECK" -eq 1 ]; then
    doctor
    exit 0
fi
preflight_links
if [ "$CONFIG_ONLY" -eq 0 ]; then validate_package_platform; fi
if [ "$DRY_RUN" -eq 1 ]; then
    if [ "$CONFIG_ONLY" -eq 0 ]; then
        install_packages
        install_runtimes
        log 'Plan: bootstrap TPM if missing; editor and tmux plugins remain first-launch actions.'
    fi
    if [ ! -e "$HOME/.config/shell/local.zsh" ] && [ ! -L "$HOME/.config/shell/local.zsh" ]; then
        log 'Plan: create empty personal shell overrides at ~/.config/shell/local.zsh.'
    fi
    log 'Plan: reconcile repository-managed agent skills.'
    log 'Dry run: no packages, runtimes, plugins, links, backups, or state were changed.'
    exit 0
fi

[ "$(id -u)" -ne 0 ] || die 'Run as your normal user, not root or sudo; only system packages need elevation'
# Refuse redirected state writes, including symlinked ancestors.
directory=$STATE_DIR
while [ "$directory" != / ]; do
    [ ! -L "$directory" ] || die "State path contains a symlink: $directory"
    directory=$(dirname "$directory")
done
for state_file in selection selection.new links.tsv; do
    [ ! -L "$STATE_DIR/$state_file" ] || die "State file cannot be a symlink: $STATE_DIR/$state_file"
done
umask 077
mkdir -p "$STATE_DIR"
if ! mkdir "$STATE_DIR/lock" 2>/dev/null; then
    die "Installer lock exists: $STATE_DIR/lock. Check its pid and running installers before removing a stale lock."
fi
LOCKED=1
printf '%s\n' "$$" > "$STATE_DIR/lock/pid"

if [ "$CONFIG_ONLY" -eq 0 ]; then
    STAGE=packages
    install_packages
    STAGE=runtimes
    install_runtimes
else
    if discover_brew; then :; else
        brew_status=$?
        [ "$brew_status" -eq 1 ] || die 'Existing Homebrew installation is incompatible or broken'
    fi
fi
command -v stow >/dev/null 2>&1 || die 'GNU Stow is required for configuration linking'
STAGE=links
apply_links
if [ "$CONFIG_ONLY" -eq 0 ]; then
    STAGE=tmux
    install_tmux
fi
STAGE=verification
if [ "$CONFIG_ONLY" -eq 1 ]; then check_links; else doctor; fi
STAGE=state
printf 'schema=1\nprofile=%s\nterminal=%s\n' "$PROFILE" "$TERMINAL" > "$STATE_DIR/selection.new"
commit_links
STAGE=skills
"$DOTFILES_DIR/scripts/sync-skills"
local_shell_config="$HOME/.config/shell/local.zsh"
if [ ! -e "$local_shell_config" ] && [ ! -L "$local_shell_config" ]; then
    if touch "$local_shell_config"; then
        log "Created personal shell overrides: $local_shell_config"
    else
        printf 'Warning: could not create personal shell overrides: %s\n' "$local_shell_config" >&2
    fi
fi
unset local_shell_config
log "Completed $PROFILE setup. Restart your shell; personal overrides belong in ~/.config/shell/local.zsh."
log 'Open Neovim to let its existing plugin managers finish first-launch setup.'
log 'In tmux, press Ctrl-Space then Shift-I to install plugins (TPM must be installed).'
