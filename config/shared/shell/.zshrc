# Managed by the dotfiles repository; edits here affect every linked machine.
# Put personal and machine-specific settings in ~/.config/shell/local.zsh.
# Shared setup loads first, personal overrides last. Startup never installs anything.
_dotfiles_shell="${XDG_CONFIG_HOME:-$HOME/.config}/shell"
source "$_dotfiles_shell/env.zsh"
[[ -r "$_dotfiles_shell/platform.zsh" ]] && source "$_dotfiles_shell/platform.zsh"
[[ -r "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
source "$_dotfiles_shell/aliases.zsh"
source "$_dotfiles_shell/ssh-tint.zsh"
# A direct Ghostty session can advertise xterm-ghostty after ensuring the remote
# account has its terminfo entry. Inside tmux, keep tmux's own terminal type.
if [[ "$TERM" == *ghostty* ]]; then
    source "$_dotfiles_shell/ghostty-ssh-integration.zsh"
fi
source "$_dotfiles_shell/interactive.zsh"
[[ -r "$HOME/.env" ]] && source "$HOME/.env"
[[ -r "$_dotfiles_shell/local.zsh" ]] && source "$_dotfiles_shell/local.zsh"

# Highlighting must follow user keybindings and interactive customization.
if [[ -n "$HOMEBREW_PREFIX" && -r "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
unset _dotfiles_shell
