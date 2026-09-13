#!/bin/bash

discover_brew() {
    local candidate prefix expected environment
    BREW=
    candidate=$(command -v brew 2>/dev/null) || candidate=
    if [ -z "$candidate" ]; then
        for prefix in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
            if [ -x "$prefix/bin/brew" ]; then candidate=$prefix/bin/brew; break; fi
        done
    fi
    [ -n "$candidate" ] || return 1
    prefix=$("$candidate" --prefix) || return 2
    case "$OS:$ARCH" in
        macos:arm64) expected=/opt/homebrew ;;
        macos:x86_64) expected=/usr/local ;;
        linux:*) expected=/home/linuxbrew/.linuxbrew ;;
        *) return 2 ;;
    esac
    if [ "$prefix" != "$expected" ]; then
        log "Homebrew at $prefix does not match the expected $expected for $OS/$ARCH. Resolve PATH/prefix before installing."
        return 2
    fi
    BREW=$prefix/bin/brew
    environment=$("$BREW" shellenv) || return 2
    eval "$environment"
    export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_UPGRADE=1
}

native_install() {
    local package status
    local missing=()
    for package in "$@"; do
        case "$package" in
            ''|*[!a-zA-Z0-9.+_-]*) die "Invalid native package name: $package"; return 1 ;;
        esac
        # Fedora commonly supplies curl-minimal instead of the full curl package.
        if [ "$DISTRO" = fedora ] && [ "$package" = curl ] && command -v curl >/dev/null 2>&1; then
            continue
        fi
        case "$DISTRO" in
            ubuntu|debian)
                status=$(dpkg-query -W -f='${Status}' "$package" 2>/dev/null) || status=
                [ "$status" = 'install ok installed' ] || missing+=("$package")
                ;;
            fedora) rpm -q "$package" >/dev/null 2>&1 || missing+=("$package") ;;
        esac
    done
    [ "${#missing[@]}" -gt 0 ] || return 0
    log "Native packages: ${missing[*]}"
    [ "$DRY_RUN" = 0 ] || return 0
    command -v sudo >/dev/null 2>&1 || { die "sudo is required to install native packages."; return 1; }
    case "$DISTRO" in
        ubuntu|debian)
            sudo apt-get update || return 1
            sudo apt-get install -y --no-install-recommends "${missing[@]}" || return 1
            ;;
        fedora) sudo dnf install -y "${missing[@]}" || return 1 ;;
    esac
}

native_manifest() {
    local line
    local packages=()
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in ''|\#*) continue ;; esac
        packages+=("$line")
    done < "$1"
    native_install "${packages[@]}"
}

install_packages() {
    local adapter status installer manifest prefix
    local manifests=("$DOTFILES_DIR/packages/shared.Brewfile")
    validate_package_platform || return 1
    if discover_brew; then status=0; else status=$?; fi
    [ "$status" -ne 2 ] || { die "Existing Homebrew installation is incompatible or broken."; return 1; }
    if [ "$OS" = linux ]; then
        adapter=$DISTRO
        [ "$adapter" != ubuntu ] || adapter=debian
        native_manifest "$DOTFILES_DIR/packages/native/$adapter/bootstrap.txt" || return 1
    elif ! xcode-select -p >/dev/null 2>&1 || ! xcrun --find clang >/dev/null 2>&1; then
        if [ "$DRY_RUN" = 0 ]; then
            die "Install Apple's Command Line Tools with xcode-select --install, then rerun. Full Xcode is optional."
            return 1
        fi
        log "Apple Command Line Tools are required before installation."
    fi
    if [ "$status" -eq 1 ]; then
        log "Install Homebrew using https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
        if [ "$DRY_RUN" = 0 ]; then
            installer=$(mktemp "${TMPDIR:-/tmp}/dotfiles-brew.XXXXXX") || return 1
            if ! curl --fail --location --retry 2 --connect-timeout 15 --max-time 120 \
                https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer"; then
                rm -f "$installer"
                return 1
            fi
            if /bin/bash "$installer"; then status=0; else status=$?; fi
            rm -f "$installer"
            [ "$status" -eq 0 ] || return "$status"
            discover_brew || { die "Homebrew installed but could not be initialized."; return 1; }
        fi
    fi
    [ ! -f "$DOTFILES_DIR/packages/$OS.Brewfile" ] || manifests+=("$DOTFILES_DIR/packages/$OS.Brewfile")
    if [ "$PROFILE" = desktop ]; then
        if [ "$OS" = macos ]; then
            manifests+=("$DOTFILES_DIR/packages/desktop/macos.Brewfile" "$DOTFILES_DIR/packages/desktop/$TERMINAL.macos.Brewfile")
        else
            native_manifest "$DOTFILES_DIR/packages/native/$adapter/desktop.txt" || return 1
            if ! command -v "$TERMINAL" >/dev/null 2>&1; then
                native_install "$TERMINAL" || return 1
            fi
            if [ "$DRY_RUN" = 0 ]; then fc-cache -f || return 1; fi
        fi
    fi
    for manifest in "${manifests[@]}"; do
        log "Homebrew bundle (no upgrades): ${manifest#"$DOTFILES_DIR/"}"
        if [ "$DRY_RUN" = 0 ]; then
            "$BREW" bundle install --no-upgrade --file="$manifest" || return 1
        fi
    done
    if [ "$DRY_RUN" = 0 ]; then
        # Use the declared runtimes in the installer as well as the managed shell,
        # rather than a system Python or macOS's Java launcher stub.
        prefix=$("$BREW" --prefix) || return 1
        export PATH="$prefix/opt/python@3.14/libexec/bin:$prefix/opt/openjdk/bin:$PATH"
        if [ "$OS" = macos ]; then
            export JAVA_HOME="$prefix/opt/openjdk/libexec/openjdk.jdk/Contents/Home"
        else
            export JAVA_HOME="$prefix/opt/openjdk/libexec"
        fi
    fi
}
