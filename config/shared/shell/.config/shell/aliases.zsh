alias reload='source "$HOME/.zshrc"'
(( $+commands[nvim] )) && alias vi=nvim
alias gs='git status'
alias gl='git log'
alias gb='git branch'
alias gc='git checkout'
alias gadd='git add -u'
alias gaddll='git add -A'
alias gamend='git commit --amend --no-edit'
alias gamendmsg='git commit --amend -m'
(( $+commands[claude] && $+commands[ai-commit] )) && alias gcai=ai-commit
(( $+commands[terraform] )) && alias tf=terraform

if (( $+commands[nvim] )); then
    alias zconf='nvim "$HOME/.config/shell/local.zsh"'
    alias viconf='(cd "$HOME/.config/nvim" && nvim .)'
    alias tconf='nvim "$HOME/.config/tmux/tmux.conf"'
    if [[ -f "$HOME/.config/ghostty/config.ghostty" ]]; then
        alias gconf='nvim "$HOME/.config/ghostty/config.ghostty"'
    fi
    [[ -f "$HOME/.wezterm.lua" ]] && alias wconf='nvim "$HOME/.wezterm.lua"'
fi
(( $+commands[tmux] )) && alias treload='tmux source-file "$HOME/.config/tmux/tmux.conf"'
(( $+commands[eza] )) && alias ls='eza --icons=auto'
