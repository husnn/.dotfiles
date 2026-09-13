PROMPT='%n@%m %1~ %# '

(( $+commands[zoxide] )) && eval "$(zoxide init zsh --cmd ji)"
if [[ -n "$HOMEBREW_PREFIX" && -r "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi
