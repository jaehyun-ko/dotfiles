#!/bin/bash

# Intelligent Dotfiles Installation Script
# This script detects the OS and installs required packages

# Note: We don't use 'set -e' to ensure the script continues even if some components fail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            OS="debian"
            PKG_MANAGER="apt"
            PKG_UPDATE="sudo apt update"
            PKG_INSTALL="sudo apt install -y"
        elif [ -f /etc/redhat-release ]; then
            OS="redhat"
            PKG_MANAGER="yum"
            PKG_UPDATE="sudo yum update -y"
            PKG_INSTALL="sudo yum install -y"
        elif [ -f /etc/arch-release ]; then
            OS="arch"
            PKG_MANAGER="pacman"
            PKG_UPDATE="sudo pacman -Sy"
            PKG_INSTALL="sudo pacman -S --noconfirm"
        else
            OS="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        PKG_MANAGER="brew"
        PKG_UPDATE="brew update"
        PKG_INSTALL="brew install"
    else
        OS="unknown"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install basic packages
install_basic_packages() {
    print_info "Installing basic packages..."
    
    # Update package manager
    print_info "Updating package manager..."
    $PKG_UPDATE || print_warning "Failed to update package manager"
    
    # Basic packages for all systems
    local packages=(
        "git"
        "curl"
        "wget"
        "tmux"
        "zsh"
    )
    
    for pkg in "${packages[@]}"; do
        if command_exists "$pkg"; then
            print_status "$pkg is already installed"
        else
            print_info "Installing $pkg..."
            $PKG_INSTALL "$pkg" || print_error "Failed to install $pkg"
        fi
    done
}

# Install Oh My Zsh
install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_status "Oh My Zsh is already installed"
    else
        print_info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
}

# Install Powerlevel10k
install_powerlevel10k() {
    if [ -d "$HOME/powerlevel10k" ]; then
        print_status "Powerlevel10k is already installed"
    else
        print_info "Installing Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
    fi
}

# Install zsh plugins
install_zsh_plugins() {
    print_info "Installing zsh plugins..."
    
    # zsh-autosuggestions
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    else
        print_status "zsh-autosuggestions is already installed"
    fi
    
    # zsh-syntax-highlighting
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    else
        print_status "zsh-syntax-highlighting is already installed"
    fi
    
    # autojump
    if ! command_exists autojump; then
        print_info "Installing autojump..."
        if [[ "$OS" == "debian" ]]; then
            $PKG_INSTALL autojump
        elif [[ "$OS" == "macos" ]]; then
            $PKG_INSTALL autojump
        else
            print_warning "Please install autojump manually for your system"
        fi
    else
        print_status "autojump is already installed"
    fi
}

# Install NVM
install_nvm() {
    if [ -d "$HOME/.nvm" ]; then
        print_status "NVM is already installed"
    else
        print_info "Installing NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    fi
    
    # Source NVM and install/use latest Node.js
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    print_info "Installing latest Node.js via NVM..."
    nvm install node || print_warning "Failed to install Node.js"
    nvm use node || print_warning "Failed to set default Node.js version"
}

# Install Oh My Bash
install_oh_my_bash() {
    if [ -d "$HOME/.oh-my-bash" ]; then
        print_status "Oh My Bash is already installed"
    else
        print_info "Installing Oh My Bash..."
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended
    fi
}

# Install Oh My Tmux
install_oh_my_tmux() {
    if [ -f "$HOME/.tmux.conf" ]; then
        print_status "Oh My Tmux is already installed"
    else
        print_info "Installing Oh My Tmux..."
        cd
        git clone https://github.com/gpakosz/.tmux.git
        ln -s -f .tmux/.tmux.conf
    fi
}

# Install Rust and Cargo
install_rust() {
    if command_exists cargo; then
        print_status "Rust/Cargo is already installed"
    else
        print_info "Installing Rust and Cargo..."
        # Install in non-interactive mode and source the env file
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
        # Source cargo environment for current session
        if [ -f "$HOME/.cargo/env" ]; then
            source "$HOME/.cargo/env"
        fi
    fi
}

# Create symlinks for dotfiles
create_symlinks() {
    print_info "Creating symlinks for dotfiles..."
    
    # Get the directory of this script
    DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # List of files to symlink
    local dotfiles=(
        ".zshrc"
        ".bashrc"
        ".gitconfig"
        ".tmux.conf.local"
        ".p10k.zsh"
    )
    
    for file in "${dotfiles[@]}"; do
        if [ -f "$DOTFILES_DIR/$file" ]; then
            # Backup existing file
            if [ -f "$HOME/$file" ] && [ ! -L "$HOME/$file" ]; then
                print_warning "Backing up existing $file to $file.backup"
                mv "$HOME/$file" "$HOME/$file.backup"
            fi
            
            # Create symlink
            ln -sf "$DOTFILES_DIR/$file" "$HOME/$file"
            print_status "Created symlink for $file"
        else
            print_warning "$file not found in dotfiles directory"
        fi
    done
}

# Main installation function
main() {
    echo "========================================"
    echo "    Intelligent Dotfiles Installer      "
    echo "========================================"
    echo
    
    # Detect OS
    detect_os
    print_info "Detected OS: $OS"
    print_info "Package Manager: $PKG_MANAGER"
    echo
    
    # Check if running with necessary permissions
    if [[ "$OS" != "macos" ]] && [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        print_warning "This script may need sudo privileges to install packages."
        print_info "Please enter your password when prompted."
        echo
    fi
    
    # Install components (continue even if some fail)
    install_basic_packages || print_warning "Some basic packages failed to install"
    install_oh_my_zsh || print_warning "Oh My Zsh installation had issues"
    install_powerlevel10k || print_warning "Powerlevel10k installation had issues"
    install_zsh_plugins || print_warning "Some zsh plugins failed to install"
    install_nvm || print_warning "NVM installation had issues"
    install_oh_my_bash || print_warning "Oh My Bash installation had issues"
    install_oh_my_tmux || print_warning "Oh My Tmux installation had issues"
    install_rust || print_warning "Rust installation had issues"
    
    # Create symlinks - this should always run
    create_symlinks
    
    echo
    print_status "Installation complete!"
    print_info "Please restart your terminal or run 'source ~/.zshrc' to apply changes."
    print_info "You may need to run 'p10k configure' to set up Powerlevel10k."
    
    # Change default shell to zsh if not already
    if [ "$SHELL" != "$(which zsh)" ]; then
        print_info "Changing default shell to zsh..."
        chsh -s "$(which zsh)" || print_warning "Failed to change default shell. You may need to run: chsh -s $(which zsh)"
    else
        print_status "Default shell is already zsh"
    fi
}

# Run main function
main "$@"