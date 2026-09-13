# Read-only diagnostics. Never source the user's shell or launch configured apps.
check_links() {
    local index failed=0
    for ((index=0; index<${#LINK_TARGETS[@]}; index++)); do
        if ! link_ancestors_safe "${LINK_TARGETS[index]}"; then failed=1; continue; fi
        if ! link_points_to "${LINK_TARGETS[index]}" "${LINK_SOURCES[index]}" || [ ! -e "${LINK_TARGETS[index]}" ]; then
            log "Missing or incorrect link: ${LINK_TARGETS[index]}"
            failed=1
        fi
    done
    [ "$failed" -eq 0 ] && log 'Configuration links: OK'
    return "$failed"
}

doctor() (
    local failed=0 executable location version major prefix
    if discover_brew; then
        log "Homebrew: $BREW"
        prefix=$HOMEBREW_PREFIX
        PATH="$prefix/opt/python@3.14/libexec/bin:$prefix/opt/openjdk/bin:$PATH"
        export PATH
    else
        log 'Missing or incompatible Homebrew installation.'
        failed=1
    fi
    # Loading NVM with --no-use and selecting an installed default changes only
    # this diagnostic subshell. It does not download or modify saved defaults.
    export NVM_DIR=${NVM_DIR:-$HOME/.nvm}
    export NVM_SYMLINK_CURRENT=false
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        if . "$NVM_DIR/nvm.sh" --no-use && nvm use --silent default >/dev/null 2>&1; then :; else
            log 'NVM: no usable installed default'; failed=1
        fi
    else
        log 'NVM: missing'; failed=1
    fi
    for executable in git nvim tmux stow zsh go tree-sitter python3 uv java eza zoxide bat fzf rg node npm pnpm cc make curl tar unzip; do
        if location=$(command -v "$executable" 2>/dev/null); then
            log "$executable: $location"
        else
            log "Missing required command: $executable"; failed=1
        fi
    done
    if command -v nvim >/dev/null 2>&1; then
        version=$(nvim --version)
        version=${version%%$'\n'*}
        log "$version"
    fi
    if command -v node >/dev/null 2>&1; then
        major=$(node -p 'process.versions.node.split(".")[0]')
        if [ "$major" -lt 22 ]; then log 'Node 22+ is required; select an NVM default explicitly'; failed=1; fi
    fi
    if command -v tree-sitter >/dev/null 2>&1; then
        version=$(tree-sitter --version)
        log "$version"
    fi
    check_links || failed=1
    log 'Neovim plugins and tools are managed on first launch; their installation is not checked here.'
    if [ ! -x "$HOME/.config/tmux/plugins/tpm/tpm" ]; then
        log 'TPM is not installed yet; run full setup before using prefix + I in tmux.'
    fi
    if [ "$OS" = macos ]; then
        log 'Xcode is optional; the editor enables it only when xcodebuild -version succeeds.'
        if command -v xcode-select >/dev/null 2>&1; then xcode-select -p || true; fi
    fi
    if [ "$PROFILE" = desktop ]; then
        if command -v "$TERMINAL" >/dev/null 2>&1; then
            log "$TERMINAL: $(command -v "$TERMINAL")"
        elif [ "$OS" = macos ] && { { [ -d /Applications/Ghostty.app ] && [ "$TERMINAL" = ghostty ]; } || { [ -d /Applications/WezTerm.app ] && [ "$TERMINAL" = wezterm ]; }; }; then
            log "$TERMINAL: installed in /Applications"
        else
            log "Desktop terminal missing: $TERMINAL"; failed=1
        fi
        if [ "$OS" = linux ]; then
            for executable in xclip wl-copy fc-match; do
                if ! command -v "$executable" >/dev/null 2>&1; then log "Missing desktop command: $executable"; failed=1; fi
            done
            if command -v fc-match >/dev/null 2>&1; then
                version=$(fc-match -f '%{family}' 'JetBrains Mono')
                case "$version" in *'JetBrains Mono'*) log "Font: $version" ;; *) log "JetBrains Mono unavailable (font fallback: $version)"; failed=1 ;; esac
            fi
        fi
        log 'GUI rendering and clipboard round trips require a real desktop session; not exercised by --check.'
    fi
    log 'Optional Terraform/AI commands and credentials are not required. No packages were installed by doctor.'
    return "$failed"
)
