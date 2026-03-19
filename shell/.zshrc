source ~/.aliases

# Source local environment variables if they exist
if [ -f ~/.env ]; then
    source ~/.env
fi

# Zoxide (smart cd)
eval "$(zoxide init zsh --cmd ji)"

# Zsh autosuggestions
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Zsh syntax highlighting (must be last)
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

bindkey -v
bindkey -M viins '^[[1;9D' beginning-of-line  # Alt+Left Arrow
bindkey -M viins '^[[1;9C' end-of-line        # Alt+Right Arrow

export EDITOR="nvim"
export BAT_THEME="Dracula"
export HOMEBREW_NO_AUTO_UPDATE=1

export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

eval "$(pyenv init --path)"

# pnpm
export PNPM_HOME="/Users/husnain/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# OpenCode
OPENCODE_ENABLE_EXA=1
