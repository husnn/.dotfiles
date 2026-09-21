PROMPT='%n@%m %1~ %# '

# Inherited VISUAL/EDITOR containing "vi" makes zsh default to vi editing.
# Choose explicitly; use bindkey -e for emacs editing (Meta-b/f already work).
bindkey -v
# Ghostty sends Meta-b/f for Option+arrows; keep word navigation in insert mode.
bindkey -M viins '^[b' backward-word
bindkey -M viins '^[f' forward-word
# Ghostty sends Ctrl+A/E for Cmd+arrows.
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line

(( $+commands[zoxide] )) && eval "$(zoxide init zsh --cmd ji)"
if [[ -n "$HOMEBREW_PREFIX" && -r "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi
