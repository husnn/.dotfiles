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

# Previously used with WezTerm; kept here in case they're needed again.
# bindkey -v
# bindkey -M viins '^[[1;9D' beginning-of-line  # Alt+Left Arrow
# bindkey -M viins '^[[1;9C' end-of-line        # Alt+Right Arrow

export EDITOR="nvim"
export BAT_THEME="Dracula"
export HOMEBREW_NO_AUTO_UPDATE=1

export PATH="$HOME/.dotfiles/scripts:$HOME/.local/bin:$HOME/go/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# pnpm
export PNPM_HOME="/Users/husnain/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Python
export PATH="$(brew --prefix python)/libexec/bin:$PATH"

# Java
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# OpenCode
OPENCODE_ENABLE_EXA=1
