#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🍺 Installing Homebrew packages${NC}"
echo "================================"

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}Homebrew not found. Installing...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo -e "${GREEN}✓ Homebrew is already installed${NC}"
    echo -e "${BLUE}Updating Homebrew...${NC}"
    brew update
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Check if Brewfile exists
if [ -f "$DOTFILES_DIR/Brewfile" ]; then
    echo -e "${BLUE}Installing packages from Brewfile...${NC}"
    cd "$DOTFILES_DIR"
    
    # Ensure brew bundle is available
    if ! brew bundle --help &> /dev/null; then
        echo -e "${YELLOW}brew bundle not found, installing homebrew/bundle tap...${NC}"
        brew tap homebrew/bundle
    fi
    
    # Install packages from Brewfile
    brew bundle --verbose
    echo -e "${GREEN}✅ All packages installed!${NC}"
else
    echo -e "${RED}❌ Brewfile not found at $DOTFILES_DIR/Brewfile${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}📝 Notes:${NC}"
echo -e "${YELLOW}  • You may need to restart your terminal for some changes to take effect${NC}"
