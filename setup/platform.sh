#!/bin/bash

detect_platform() {
    local key value
    ARCH=$(uname -m) || return 1
    DISTRO=unknown
    VERSION_ID=unknown
    case "$(uname -s)" in
        Darwin)
            OS=macos
            DISTRO=macos
            VERSION_ID=$(sw_vers -productVersion) || return 1
            ;;
        Linux)
            OS=linux
            if [ -r /etc/os-release ]; then
                # Parse only the data needed; do not execute distribution metadata.
                while IFS='=' read -r key value; do
                    value=${value#\"}; value=${value%\"}
                    value=${value#\'}; value=${value%\'}
                    case "$key" in
                        ID) DISTRO=$value ;;
                        VERSION_ID) VERSION_ID=$value ;;
                    esac
                done < /etc/os-release
            fi
            ;;
        *) OS=unsupported ;;
    esac
}

validate_package_platform() {
    case "$ARCH" in
        arm64|aarch64|x86_64) ;;
        *) die "Automatic installation does not support architecture $ARCH."; return 1 ;;
    esac
    case "$OS:$DISTRO:$VERSION_ID" in
        macos:macos:14.*|macos:macos:15.*|macos:macos:26.*|macos:macos:27.*) ;;
        linux:ubuntu:22.04|linux:ubuntu:24.04|linux:ubuntu:26.04) ;;
        linux:debian:12|linux:debian:13|linux:fedora:43|linux:fedora:44) ;;
        *) die "Automatic installation is not configured for $OS / $DISTRO $VERSION_ID. Use --only config with existing dependencies."; return 1 ;;
    esac
    if [ "$OS" = linux ] && [ -e /run/ostree-booted ]; then
        die "Immutable/OSTree systems are not supported by the APT/DNF installer. Use --only config."
        return 1
    fi
    if [ "$OS" = macos ] && { [ "$ARCH" = x86_64 ] || [ "${VERSION_ID%%.*}" = 14 ]; }; then
        log "Warning: this Mac is outside Homebrew's current Tier 1 support; package builds may fail."
    fi
    if [ "$OS" = linux ] && [ "$PROFILE" = desktop ]; then
        if ! command -v "$TERMINAL" >/dev/null 2>&1; then
            case "$DISTRO:$VERSION_ID:$TERMINAL" in
                ubuntu:26.04:ghostty) ;;
                *)
                    die "Install $TERMINAL manually and put it on PATH before selecting desktop on $DISTRO $VERSION_ID. See README.md; no third-party repositories are added automatically."
                    return 1
                    ;;
            esac
        fi
    fi
}
