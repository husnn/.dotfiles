export DOTFILES_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/repo"
export EDITOR="${EDITOR:-nvim}"
export BAT_THEME="${BAT_THEME:-Dracula}"
export HOMEBREW_NO_AUTO_UPDATE=1
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

# Known locations are discovery candidates, never application-specific paths.
if (( ! $+commands[brew] )); then
    for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
        if [[ -x "$_brew" ]]; then
            eval "$("$_brew" shellenv)"
            break
        fi
    done
elif [[ -z "$HOMEBREW_PREFIX" ]]; then
    eval "$(brew shellenv)"
fi

typeset -U path PATH
path=("$DOTFILES_DIR/scripts" "$HOME/.local/bin" "${GOPATH:-$HOME/go}/bin" $path)
if [[ -n "$HOMEBREW_PREFIX" ]]; then
    [[ -d "$HOMEBREW_PREFIX/opt/python@3.14/libexec/bin" ]] && path=("$HOMEBREW_PREFIX/opt/python@3.14/libexec/bin" $path)
    if [[ -d "$HOMEBREW_PREFIX/opt/openjdk/bin" ]]; then
        path=("$HOMEBREW_PREFIX/opt/openjdk/bin" $path)
        if [[ "$OSTYPE" == darwin* ]]; then
            export JAVA_HOME="${JAVA_HOME:-$HOMEBREW_PREFIX/opt/openjdk/libexec/openjdk.jdk/Contents/Home}"
        else
            export JAVA_HOME="${JAVA_HOME:-$HOMEBREW_PREFIX/opt/openjdk/libexec}"
        fi
    fi
fi
unset _brew
