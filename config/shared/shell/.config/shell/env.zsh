export DOTFILES_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/repo"
export EDITOR="${EDITOR:-nvim}"
export BAT_THEME="${BAT_THEME:-Dracula}"
export HOMEBREW_NO_AUTO_UPDATE=1
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
# Keep pip from modifying a shared interpreter accidentally. Project packages
# belong in a virtual environment; standalone tools belong in uv tool/uvx.
export PIP_REQUIRE_VIRTUALENV=true

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
    # Do not rely on the inherited PATH already containing Homebrew first.
    # Homebrew exposes Python as python3/pip3 from its standard bin directory.
    [[ -d "$HOMEBREW_PREFIX/bin" ]] && path=("$HOMEBREW_PREFIX/bin" $path)
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
