#!/bin/bash

# Configuration file for dotfiles installation
# This file contains all configurable settings

# Version
INSTALLER_VERSION="2.0.0"

# Paths
export DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export INSTALL_DIR="$DOTFILES_DIR/install"
export LOG_DIR="$HOME/.dotfiles-install-logs"
export LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"
export BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# Basic packages to install
export BASIC_PACKAGES=(
    "git"
    "curl"
    "wget"
    "tmux"
    "zsh"
)

# Development tools
export DEV_PACKAGES=(
    "build-essential|build-essential|base-devel|build-essential"  # debian|redhat|arch|macos
    "cmake"
    "python3"
    "python3-pip"
)

# Optional packages (will not fail if not available)
export OPTIONAL_PACKAGES=(
    "autojump"
    "htop"
    "tree"
    "jq"
    "ripgrep|ripgrep|ripgrep|ripgrep"
    "fd-find|fd-find|fd|fd"
    "bat|bat|bat|bat"
    "fzf"
)

# URLs for external tools
export URLS=(
    "OH_MY_ZSH|https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
    "OH_MY_BASH|https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh"
    "NVM|https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh"
    "RUSTUP|https://sh.rustup.rs"
    "UV|https://astral.sh/uv/install.sh"
    "POWERLEVEL10K|https://github.com/romkatv/powerlevel10k.git"
)

# Zsh plugins
export ZSH_PLUGINS=(
    "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions"
    "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting.git"
)

# Dotfiles to symlink
export DOTFILES_TO_LINK=(
    ".zshrc"
    ".bashrc"
    ".tmux.conf.local"
    ".p10k.zsh"
    "aliases.sh"
    ".gitconfig"
)

# Installation options
export PARALLEL_JOBS="${PARALLEL_JOBS:-4}"  # Number of parallel installation jobs
export RETRY_COUNT="${RETRY_COUNT:-3}"    # Number of retries for failed operations
export RETRY_DELAY="${RETRY_DELAY:-2}"    # Delay in seconds between retries
export FORCE_INSTALL="${FORCE_INSTALL:-false}"  # Force reinstall even if already installed
export VERBOSE="${VERBOSE:-false}"    # Verbose output
export DRY_RUN="${DRY_RUN:-false}"    # Dry run mode (don't actually install)
export SKIP_CONFIRMATION="${SKIP_CONFIRMATION:-false}"  # Skip confirmation prompts

# Mirror configuration
export SKIP_MIRROR_CHANGE="${SKIP_MIRROR_CHANGE:-false}"  # Skip APT mirror configuration
export AUTO_MIRROR="${AUTO_MIRROR:-false}"  # Automatically select best mirror without prompting
export FASTEST_MIRROR="${FASTEST_MIRROR:-false}"  # Test and use fastest mirror (takes time)
export MIRROR_LOCATION="${MIRROR_LOCATION:-}"  # Force specific mirror location (kr, jp, cn, us)
export SKIP_CODEX_SYNC_STACK="${SKIP_CODEX_SYNC_STACK:-false}"  # Skip codex/omx sync setup
export SKIP_DOTFILES_AUTO_UPDATE="${SKIP_DOTFILES_AUTO_UPDATE:-false}"  # Skip dotfiles auto update timer

# Codex/OMX + skill sync defaults
export AGENTIC_RESEARCHER_REPO="${AGENTIC_RESEARCHER_REPO:-$HOME/projects/agentic-researcher}"
export SKILL_SYNC_CHANNEL="${SKILL_SYNC_CHANNEL:-stable}"
export SKILL_SYNC_CANARY_PERCENT="${SKILL_SYNC_CANARY_PERCENT:-10}"
export SKILL_SYNC_INSTALL_ROOT="${SKILL_SYNC_INSTALL_ROOT:-$HOME/.codex/skills}"
export SKILL_SYNC_SKILL_NAME="${SKILL_SYNC_SKILL_NAME:-agentic-researcher}"
export SKILL_SYNC_MIN_CHECK_INTERVAL_MINUTES="${SKILL_SYNC_MIN_CHECK_INTERVAL_MINUTES:-15}"
export DOTFILES_AUTO_UPDATE_REMOTE="${DOTFILES_AUTO_UPDATE_REMOTE:-origin}"
export DOTFILES_AUTO_UPDATE_BRANCH="${DOTFILES_AUTO_UPDATE_BRANCH:-main}"

# Colors (exported from utils.sh)
export COLOR_ENABLED="${COLOR_ENABLED:-true}"  # Set to false to disable colored output
