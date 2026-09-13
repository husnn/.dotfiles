#!/bin/bash

read_runtime_versions() {
    local key value
    NVM_VERSION= NODE_VERSION=
    while IFS='=' read -r key value || [ -n "$key" ]; do
        case "$key" in ''|\#*) continue ;; esac
        case "$value" in ''|*[!v0-9.]*) die "Invalid runtime version for $key."; return 1 ;; esac
        case "$key" in
            nvm) NVM_VERSION=$value ;;
            node) NODE_VERSION=$value ;;
            *) die "Unknown runtime selection: $key"; return 1 ;;
        esac
    done < "$DOTFILES_DIR/packages/runtimes.conf"
    [ -n "$NVM_VERSION" ] && [ -n "$NODE_VERSION" ]
}

install_runtimes() {
    local selected major
    read_runtime_versions || return 1
    export NVM_DIR=${NVM_DIR:-$HOME/.nvm}
    case "$NVM_DIR" in /*) ;; *) die "NVM_DIR must be absolute."; return 1 ;; esac
    log "Runtimes: preserve NVM/default; initially use NVM $NVM_VERSION, Node $NODE_VERSION. pnpm is managed by Homebrew."
    [ "$DRY_RUN" = 0 ] || return 0
    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        if [ -e "$NVM_DIR" ] || [ -L "$NVM_DIR" ]; then
            die "$NVM_DIR exists without nvm.sh; repair it or choose another NVM_DIR."
            return 1
        fi
        git clone --depth 1 --branch "$NVM_VERSION" https://github.com/nvm-sh/nvm.git "$NVM_DIR" || return 1
    fi
    # NVM is upstream shell code and does not support callers using nounset.
    . "$NVM_DIR/nvm.sh" --no-use || return 1
    if [ -e "$NVM_DIR/alias/default" ] || [ -L "$NVM_DIR/alias/default" ]; then
        selected=$(nvm version default) || {
            die "Existing NVM default does not resolve to an installed Node. Repair it explicitly with nvm install / nvm alias default."
            return 1
        }
        case "$selected" in
            v*) nvm use --silent default || return 1 ;;
            *) die "NVM default must select a managed Node version, not system Node."; return 1 ;;
        esac
    else
        selected=$(nvm version "$NODE_VERSION") || selected=N/A
        if [ "$selected" = N/A ]; then nvm install "$NODE_VERSION" || return 1; fi
        nvm use --silent "$NODE_VERSION" || return 1
        nvm alias default "$(nvm current)" || return 1
    fi
    major=$(node -p 'process.versions.node.split(".")[0]') || return 1
    if [ "$major" -lt 22 ]; then
        die "NVM default uses Node $major; Node 22+ is required. Select a supported Node explicitly; your default was not changed."
        return 1
    fi
}
