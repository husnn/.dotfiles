#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🏠 Dotfiles Installation with GNU Stow${NC}"
echo "=================================="

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

# Install Homebrew packages first (includes stow)
if [ -f "Brewfile" ]; then
    echo -e "${BLUE}Installing Homebrew packages...${NC}"
    if [ -f "scripts/brew-install.sh" ]; then
        chmod +x scripts/brew-install.sh
        ./scripts/brew-install.sh
        echo ""
    else
        echo -e "${YELLOW}⚠️  scripts/brew-install.sh not found, skipping package installation${NC}"
        echo ""
    fi
fi

# Check if stow is installed
if ! command -v stow &> /dev/null; then
    echo -e "${YELLOW}GNU Stow not found. Installing...${NC}"
    if command -v brew &> /dev/null; then
        brew install stow
    elif command -v apt &> /dev/null; then
        sudo apt update && sudo apt install stow
    elif command -v yum &> /dev/null; then
        sudo yum install stow
    elif command -v pacman &> /dev/null; then
        sudo pacman -S stow
    else
        echo -e "${RED}❌ Could not install stow automatically. Please install it manually:${NC}"
        echo "  macOS: brew install stow"
        echo "  Ubuntu/Debian: sudo apt install stow"
        echo "  CentOS/RHEL: sudo yum install stow"
        echo "  Arch: sudo pacman -S stow"
        exit 1
    fi
fi

echo -e "${GREEN}✓ GNU Stow is available${NC}"

# Function to stow a package
stow_package() {
    local package="$1"
    local description="$2"
    
    if [ -d "$package" ]; then
        echo -e "${BLUE}Installing $description...${NC}"
        if stow --no-folding "$package" 2>/dev/null; then
            echo -e "${GREEN}✓ $description installed${NC}"
        else
            echo -e "${YELLOW}⚠️  $description: conflicts detected, use 'stow --adopt $package' to resolve${NC}"
        fi
    else
        echo -e "${RED}❌ Package directory '$package' not found${NC}"
    fi
}

# Function to install TPM and plugins
install_tmux_plugins() {
    local tpm_dir="$HOME/.config/tmux/plugins/tpm"
    
    echo -e "${BLUE}Setting up Tmux Plugin Manager...${NC}"

    if [ ! -d "$tpm_dir" ]; then
        echo -e "${BLUE}Installing TPM...${NC}"
        mkdir -p "$(dirname "$tpm_dir")"
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
        echo -e "${GREEN}✓ TPM installed${NC}"
    else
        echo -e "${GREEN}✓ TPM already installed${NC}"
    fi
    
    # Install plugins if tmux is running
    if pgrep -x "tmux" > /dev/null; then
        echo -e "${BLUE}Installing tmux plugins...${NC}"
        "$tpm_dir/bin/install_plugins"
        echo -e "${GREEN}✓ Tmux plugins installed${NC}"
    else
        echo -e "${YELLOW}⚠️  Start tmux and press prefix + I to install plugins${NC}"
    fi
}

echo ""
echo -e "${BLUE}Installing dotfiles packages...${NC}"

# Install each package
stow_package "nvim" "Neovim configuration (~/.config/nvim)"
stow_package "tmux" "Tmux configuration (~/.config/tmux)"
stow_package "shell" "Shell configuration (.zshrc, .aliases)"
stow_package "wezterm" "WezTerm configuration (.wezterm.lua)"

# Install tmux plugins
if [ -d "tmux" ]; then
    echo ""
    install_tmux_plugins
fi

# Setup environment variables
if [ -f "shell/.env.example" ] && [ ! -f "$HOME/.env" ]; then
    echo ""
    echo -e "${BLUE}Setting up environment variables...${NC}"
    cp "shell/.env.example" "$HOME/.env"
    echo -e "${GREEN}✓ Created ~/.env from template${NC}"
    echo -e "${YELLOW}⚠️  Please edit ~/.env and add your actual environment variables${NC}"
    echo -e "${YELLOW}Note: ~/.env is a local file, not managed by stow${NC}"
fi

echo ""
echo -e "${GREEN}✅ Dotfiles installation complete!${NC}"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "  • Restart your terminal or run: source ~/.zshrc"
echo "  • If you see conflicts, run: stow --adopt <package-name> then git diff to review changes"
echo ""
echo -e "${BLUE}💡 Useful commands:${NC}"
echo "  • Remove all: stow -D nvim tmux shell wezterm"
echo "  • Reinstall: ./install.sh"
echo "  • Install specific package: stow <package-name>"
