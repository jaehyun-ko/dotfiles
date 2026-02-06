#!/bin/bash

# Individual component installers

# Install Oh My Zsh
install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ] && [[ "$FORCE_INSTALL" != "true" ]]; then
        print_status "Oh My Zsh is already installed"
        return 0
    fi
    
    print_info "Installing Oh My Zsh..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_debug "[DRY RUN] Would install Oh My Zsh"
        return 0
    fi
    
    # Backup existing .zshrc
    backup_file "$HOME/.zshrc"
    
    # Install Oh My Zsh
    local oh_my_zsh_url=$(echo "${URLS[@]}" | tr ' ' '\n' | grep "^OH_MY_ZSH" | cut -d'|' -f2)
    sh -c "$(curl -fsSL $oh_my_zsh_url)" "" --unattended || {
        print_error "Failed to install Oh My Zsh"
        return 1
    }
    
    print_status "Oh My Zsh installed successfully"
}

# Install Powerlevel10k
install_powerlevel10k() {
    if [ -d "$HOME/powerlevel10k" ] && [[ "$FORCE_INSTALL" != "true" ]]; then
        print_status "Powerlevel10k is already installed"
        return 0
    fi
    
    print_info "Installing Powerlevel10k..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_debug "[DRY RUN] Would install Powerlevel10k"
        return 0
    fi
    
    local p10k_url=$(echo "${URLS[@]}" | tr ' ' '\n' | grep "^POWERLEVEL10K" | cut -d'|' -f2)
    clone_repository "$p10k_url" "$HOME/powerlevel10k" 1
    
    print_status "Powerlevel10k installed successfully"
}

# Install zsh plugins
install_zsh_plugins() {
    print_info "Installing zsh plugins..."
    
    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    
    for plugin_spec in "${ZSH_PLUGINS[@]}"; do
        local plugin_name=$(echo "$plugin_spec" | cut -d'|' -f1)
        local plugin_url=$(echo "$plugin_spec" | cut -d'|' -f2)
        local plugin_dir="$zsh_custom/plugins/$plugin_name"
        
        if [ -d "$plugin_dir" ] && [[ "$FORCE_INSTALL" != "true" ]]; then
            print_status "$plugin_name is already installed"
            continue
        fi
        
        if [[ "$DRY_RUN" == "true" ]]; then
            print_debug "[DRY RUN] Would install $plugin_name"
            continue
        fi
        
        clone_repository "$plugin_url" "$plugin_dir" 1 || {
            print_warning "Failed to install $plugin_name"
        }
    done
    
    # Install autojump separately as it's a system package
    install_package "autojump" false
    
    print_status "Zsh plugins installed"
}

# Install NVM and Node.js
install_nvm() {
    if [ -d "$HOME/.nvm" ] && [[ "$FORCE_INSTALL" != "true" ]]; then
        print_status "NVM is already installed"
    else
        print_info "Installing NVM..."
        
        if [[ "$DRY_RUN" == "true" ]]; then
            print_debug "[DRY RUN] Would install NVM"
            return 0
        fi
        
        local nvm_url=$(echo "${URLS[@]}" | tr ' ' '\n' | grep "^NVM" | cut -d'|' -f2)
        curl -o- "$nvm_url" | bash || {
            print_error "Failed to install NVM"
            return 1
        }
    fi
    
    # Source NVM and install latest Node.js
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if command_exists nvm; then
        print_info "Installing latest Node.js via NVM..."
        
        if [[ "$DRY_RUN" == "true" ]]; then
            print_debug "[DRY RUN] Would install Node.js"
            return 0
        fi
        
        nvm install node || print_warning "Failed to install Node.js"
        nvm use node || print_warning "Failed to set default Node.js version"
        nvm alias default node || print_warning "Failed to set default Node.js alias"
        
        print_status "NVM and Node.js installed successfully"
    else
        print_warning "NVM installed but not available in current session"
    fi
}

# Install Oh My Bash
install_oh_my_bash() {
    if [ -d "$HOME/.oh-my-bash" ] && [[ "$FORCE_INSTALL" != "true" ]]; then
        print_status "Oh My Bash is already installed"
        return 0
    fi
    
    print_info "Installing Oh My Bash..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_debug "[DRY RUN] Would install Oh My Bash"
        return 0
    fi
    
    # Backup existing .bashrc
    backup_file "$HOME/.bashrc"
    
    local oh_my_bash_url=$(echo "${URLS[@]}" | tr ' ' '\n' | grep "^OH_MY_BASH" | cut -d'|' -f2)
    bash -c "$(curl -fsSL $oh_my_bash_url)" --unattended || {
        print_warning "Failed to install Oh My Bash"
        return 1
    }
    
    print_status "Oh My Bash installed successfully"
}

# Install Oh My Tmux
install_oh_my_tmux() {
    # Check if oh-my-tmux is actually installed (directory exists and symlink is valid)
    if [ -d "$HOME/.tmux" ] && [ -L "$HOME/.tmux.conf" ] && [[ "$FORCE_INSTALL" != "true" ]]; then
        print_status "Oh My Tmux is already installed"
        return 0
    fi
    
    print_info "Installing Oh My Tmux..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_debug "[DRY RUN] Would install Oh My Tmux"
        return 0
    fi
    
    # Backup existing tmux config
    backup_file "$HOME/.tmux.conf"
    backup_file "$HOME/.tmux.conf.local"
    
    cd "$HOME" || return 1
    git clone https://github.com/gpakosz/.tmux.git || {
        print_error "Failed to clone Oh My Tmux"
        return 1
    }
    
    ln -s -f .tmux/.tmux.conf || {
        print_error "Failed to create tmux.conf symlink"
        return 1
    }
    
    print_status "Oh My Tmux installed successfully"
}

# Install Rust and Cargo
install_rust() {
    if command_exists cargo && [[ "$FORCE_INSTALL" != "true" ]]; then
        print_status "Rust/Cargo is already installed"
        return 0
    fi
    
    print_info "Installing Rust and Cargo..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_debug "[DRY RUN] Would install Rust"
        return 0
    fi
    
    local rustup_url=$(echo "${URLS[@]}" | tr ' ' '\n' | grep "^RUSTUP" | cut -d'|' -f2)
    curl --proto '=https' --tlsv1.2 -sSf "$rustup_url" | sh -s -- -y --no-modify-path || {
        print_error "Failed to install Rust"
        return 1
    }
    
    # Source cargo environment for current session
    if [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
    fi
    
    print_status "Rust and Cargo installed successfully"
}

# Install uv (Python package manager)
install_uv() {
    if command_exists uv && [[ "$FORCE_INSTALL" != "true" ]]; then
        print_status "uv is already installed"
        return 0
    fi
    
    print_info "Installing uv (Python package manager)..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_debug "[DRY RUN] Would install uv"
        return 0
    fi
    
    local uv_url=$(echo "${URLS[@]}" | tr ' ' '\n' | grep "^UV" | cut -d'|' -f2)
    
    # Try official installer first
    if curl -LsSf "$uv_url" | sh; then
        print_status "uv installed successfully"
        return 0
    fi
    
    # Fallback to pip
    print_warning "Failed to install uv using official installer, trying pip..."
    
    if command_exists pip3; then
        pip3 install --user uv || {
            print_error "Failed to install uv via pip"
            return 1
        }
        print_status "uv installed via pip"
    else
        print_error "pip3 not found, cannot install uv"
        return 1
    fi
}

# Install nvtop (GPU monitoring tool)
install_nvtop() {
    if command_exists nvtop && [[ "$FORCE_INSTALL" != "true" ]]; then
        print_status "nvtop is already installed"
        return 0
    fi
    
    print_info "Installing nvtop (GPU monitoring tool)..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_debug "[DRY RUN] Would install nvtop"
        return 0
    fi
    
    case "$OS" in
        debian|ubuntu)
            install_package "nvtop" false || {
                print_info "Trying to build nvtop from source..."
                install_nvtop_from_source
            }
            ;;
        arch)
            install_package "nvtop" false
            ;;
        redhat|fedora)
            if command_exists dnf; then
                install_package "nvtop" false
            else
                print_warning "nvtop not available in standard repos"
                install_nvtop_from_source
            fi
            ;;
        macos)
            print_warning "nvtop is Linux-specific. For macOS GPU monitoring:"
            print_info "  - Activity Monitor (built-in)"
            print_info "  - iStat Menus (third-party)"
            print_info "  - asitop for Apple Silicon: pip3 install asitop"
            return 0
            ;;
        *)
            print_warning "nvtop installation not supported on $OS"
            return 1
            ;;
    esac
}

# Build nvtop from source
install_nvtop_from_source() {
    print_info "Building nvtop from source..."
    
    # Install build dependencies
    local build_deps=("cmake" "libncurses5-dev" "libncursesw5-dev" "git" "build-essential")
    install_packages build_deps false false
    
    local build_dir=$(create_temp_dir)
    cd "$build_dir" || return 1
    
    git clone https://github.com/Syllo/nvtop.git || {
        print_error "Failed to clone nvtop repository"
        return 1
    }
    
    mkdir -p nvtop/build && cd nvtop/build || return 1
    
    cmake .. -DCMAKE_BUILD_TYPE=Release || {
        print_error "Failed to configure nvtop build"
        return 1
    }
    
    make || {
        print_error "Failed to build nvtop"
        return 1
    }
    
    sudo make install || {
        print_error "Failed to install nvtop"
        return 1
    }
    
    cd - > /dev/null
    rm -rf "$build_dir"
    
    print_status "nvtop built and installed from source"
}

# Install Claude Code configuration (from submodule)
install_claude_config() {
    local claude_dir="$SCRIPT_DIR/../claude"
    local claude_install="$claude_dir/install.sh"

    if [ ! -f "$claude_install" ]; then
        # Submodule not initialized - try to init
        print_info "Initializing Claude config submodule..."

        if [[ "$DRY_RUN" == "true" ]]; then
            print_debug "[DRY RUN] Would initialize claude submodule"
            return 0
        fi

        cd "$SCRIPT_DIR/.." || return 1
        git submodule update --init claude 2>/dev/null || {
            print_warning "Failed to initialize claude submodule"
            print_info "You can manually clone: git clone git@github.com:jaehyun-ko/claude-dotfiles.git claude"
            return 1
        }
    fi

    if [ ! -f "$claude_install" ]; then
        print_warning "Claude config not found at $claude_install"
        return 1
    fi

    # Skip if already fully configured
    if [[ "$FORCE_INSTALL" != "true" ]] && [ -L "$HOME/.claude/CLAUDE.md" ] && [ -L "$HOME/.claude/rules" ]; then
        local current_target
        current_target="$(readlink -f "$HOME/.claude/CLAUDE.md" 2>/dev/null)"
        local expected_target
        expected_target="$(readlink -f "$claude_dir/CLAUDE.md" 2>/dev/null)"
        if [ "$current_target" = "$expected_target" ]; then
            print_status "Claude Code configuration already installed (skipping)"
            return 0
        fi
    fi

    print_info "Installing Claude Code configuration..."

    if [[ "$DRY_RUN" == "true" ]]; then
        print_debug "[DRY RUN] Would run claude/install.sh"
        return 0
    fi

    DOTFILES_CLAUDE="$claude_dir" bash "$claude_install" || {
        print_warning "Claude config installation had issues"
        return 1
    }

    print_status "Claude Code configuration installed"
}

# Create symlinks for dotfiles
create_symlinks() {
    print_info "Creating symlinks for dotfiles..."
    
    # Save current git config before symlinking
    local git_user_name=""
    local git_user_email=""
    
    if [ -f "$HOME/.gitconfig" ]; then
        git_user_name=$(git config --global user.name 2>/dev/null || echo "")
        git_user_email=$(git config --global user.email 2>/dev/null || echo "")
        
        if [ -n "$git_user_name" ] || [ -n "$git_user_email" ]; then
            print_info "Preserving existing git configuration..."
        fi
    fi
    
    for file in "${DOTFILES_TO_LINK[@]}"; do
        local source_file="$DOTFILES_DIR/$file"
        local target_file="$HOME/$file"
        
        if [ ! -f "$source_file" ]; then
            print_warning "$file not found in dotfiles directory"
            continue
        fi
        
        if [[ "$DRY_RUN" == "true" ]]; then
            print_debug "[DRY RUN] Would link $source_file to $target_file"
            continue
        fi
        
        # Backup existing file
        if [ -f "$target_file" ] && [ ! -L "$target_file" ]; then
            backup_file "$target_file"
        fi
        
        # Remove existing symlink or file
        rm -f "$target_file"
        
        # Create symlink
        ln -sf "$source_file" "$target_file" || {
            print_error "Failed to create symlink for $file"
            continue
        }
        
        print_status "Created symlink for $file"
    done
    
    # Restore git config after symlinking
    if [ -n "$git_user_name" ] || [ -n "$git_user_email" ]; then
        if [ -n "$git_user_name" ]; then
            git config --global user.name "$git_user_name"
            print_status "Restored git user.name: $git_user_name"
        fi
        if [ -n "$git_user_email" ]; then
            git config --global user.email "$git_user_email"
            print_status "Restored git user.email: $git_user_email"
        fi
    fi
}

# Change default shell to zsh
change_default_shell() {
    if [ "$SHELL" = "$(which zsh)" ]; then
        print_status "Default shell is already zsh"
        return 0
    fi
    
    print_info "Attempting to change default shell to zsh..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_debug "[DRY RUN] Would change default shell to zsh"
        return 0
    fi
    
    local current_user=$(whoami)
    local zsh_path=$(which zsh)
    
    # Check if zsh is in /etc/shells
    if ! grep -q "^${zsh_path}$" /etc/shells 2>/dev/null; then
        print_info "Adding zsh to /etc/shells..."
        echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null || {
            print_warning "Failed to add zsh to /etc/shells"
        }
    fi
    
    # Try to change shell
    if command_exists sudo; then
        sudo usermod -s "$zsh_path" "$current_user" 2>/dev/null && {
            print_status "Successfully changed default shell to zsh"
            print_info "Please log out and log back in for the change to take effect"
            return 0
        }
    fi
    
    # Fallback to chsh
    if command_exists chsh; then
        chsh -s "$zsh_path" && {
            print_status "Successfully changed default shell to zsh"
            print_info "Please log out and log back in for the change to take effect"
            return 0
        }
    fi
    
    # Last resort: add exec zsh to .bashrc
    if ! grep -q "exec zsh" "$HOME/.bashrc" 2>/dev/null; then
        print_info "Adding 'exec zsh' to .bashrc as fallback..."
        cat >> "$HOME/.bashrc" << 'EOF'

# Auto-start zsh if available
if [ -x "$(command -v zsh)" ] && [ "$SHELL" != "$(which zsh)" ]; then
    exec zsh
fi
EOF
        print_status "Added zsh auto-start to .bashrc"
    fi
    
    print_warning "Could not automatically change default shell"
    print_info "Please manually run: chsh -s $zsh_path"
}

# Configure pip to use Kakao mirror for faster downloads in Korea
install_pip_mirror() {
    # Skip if user explicitly disabled pip mirror configuration
    if [[ "$SKIP_PIP_MIRROR" == "true" ]]; then
        print_info "Skipping pip mirror configuration (--skip-pip-mirror flag)"
        return 0
    fi
    
    # Auto-detect location and configure accordingly
    local use_kakao_mirror=false
    
    if [[ "$AUTO_MIRROR" == "true" ]] || [[ "$MIRROR_LOCATION" == "kr" ]]; then
        # Auto mode or forced Korean location
        use_kakao_mirror=true
        print_info "Configuring pip to use Kakao mirror (Korean mirror)..."
    elif [[ -z "$MIRROR_LOCATION" ]]; then
        # Try to detect location
        local timezone=$(timedatectl 2>/dev/null | grep "Time zone" | awk '{print $3}' || echo "")
        local locale=$(locale 2>/dev/null | grep "LANG" | cut -d= -f2 | cut -d_ -f2 | cut -d. -f1 || echo "")
        
        if [[ "$timezone" == "Asia/Seoul" ]] || [[ "$locale" == "KR" ]]; then
            use_kakao_mirror=true
            print_info "Detected Korean location, configuring pip to use Kakao mirror..."
        else
            print_info "Non-Korean location detected, skipping pip mirror configuration"
            return 0
        fi
    else
        print_info "Skipping pip mirror configuration for location: $MIRROR_LOCATION"
        return 0
    fi
    
    if [[ "$use_kakao_mirror" != "true" ]]; then
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_debug "[DRY RUN] Would configure pip with Kakao mirror"
        return 0
    fi
    
    # Create .pip directory if it doesn't exist
    mkdir -p "$HOME/.pip"
    
    # Backup existing pip.conf if it exists
    if [ -f "$HOME/.pip/pip.conf" ]; then
        backup_file "$HOME/.pip/pip.conf"
    fi
    
    # Create pip configuration with Kakao mirror
    cat > "$HOME/.pip/pip.conf" << 'EOF'
[global]
index-url = https://mirror.kakao.com/pypi/simple
extra-index-url = https://pypi.python.org/simple
trusted-host = mirror.kakao.com
EOF
    
    if [ $? -eq 0 ]; then
        print_status "Successfully configured pip to use Kakao mirror"
        print_debug "pip will now use Kakao mirror for faster downloads in Korea"
        return 0
    else
        print_warning "Failed to configure pip mirror"
        return 1
    fi
}