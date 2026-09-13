# Bootstrap TPM only. Install its plugins from tmux with prefix + I.
install_tmux() {
    local destination="$HOME/.config/tmux/plugins/tpm"
    if [ -x "$destination/tpm" ]; then return 0; fi
    if [ -e "$destination" ] || [ -L "$destination" ]; then
        die "Incomplete TPM installation at $destination; repair it before rerunning setup."
    fi
    log 'Installing Tmux Plugin Manager; start tmux and press Ctrl-Space then Shift-I to install plugins.'
    mkdir -p "${destination%/*}"
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$destination" || return 1
    [ -x "$destination/tpm" ] || die 'TPM installation did not produce its executable.'
}
