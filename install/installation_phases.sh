#!/bin/bash

# Installation phases with dependency management and parallel execution

# Phase 1: System Preparation (Sequential - Critical foundation)
phase1_system_preparation() {
    print_header "Phase 1: System Preparation"
    
    # 1.1 Configure APT mirror FIRST for faster downloads
    if [[ "$OS" == "debian" ]]; then
        print_info "Configuring APT mirror for faster downloads..."
        setup_apt_mirror || print_warning "Failed to configure APT mirror, using default"
    fi
    
    # 1.2 Update package manager
    print_info "Updating package manager..."
    update_package_manager || print_warning "Package manager update failed"
    
    # 1.3 Check and install critical dependencies
    print_info "Installing critical dependencies..."
    check_dependencies || {
        print_error "Critical dependencies missing"
        return 1
    }
    
    print_status "Phase 1 completed: System prepared"
    return 0
}

# Phase 2: Core Packages (Parallel where possible)
phase2_core_packages() {
    print_header "Phase 2: Core Package Installation"
    
    # 2.1 Install basic packages (required for everything else)
    print_info "Installing basic packages..."
    install_packages BASIC_PACKAGES true true || {
        print_error "Failed to install basic packages"
        return 1
    }
    
    # 2.2 Install development and optional packages in parallel
    print_info "Installing development and optional packages..."
    local pids=()
    
    (
        print_debug "Installing development packages..."
        install_packages DEV_PACKAGES false false
    ) & pids+=($!)
    
    (
        print_debug "Installing optional packages..."
        install_packages OPTIONAL_PACKAGES false false
    ) & pids+=($!)
    
    # Wait for parallel installations
    local failed=0
    for pid in "${pids[@]}"; do
        wait "$pid" || failed=$((failed + 1))
    done
    
    if [ $failed -gt 0 ]; then
        print_warning "$failed package group(s) had issues"
    fi
    
    print_status "Phase 2 completed: Core packages installed"
    return 0
}

# Phase 3: Shell Environment (Parallel installation)
phase3_shell_environment() {
    print_header "Phase 3: Shell Environment Setup"
    
    # 3.1 Install shell frameworks in parallel (independent)
    print_info "Installing shell frameworks..."
    local pids=()
    local results_dir=$(create_temp_dir)
    
    (
        install_oh_my_zsh
        echo $? > "$results_dir/omz.status"
    ) & pids+=($!)
    
    (
        install_oh_my_bash
        echo $? > "$results_dir/omb.status"
    ) & pids+=($!)
    
    (
        install_oh_my_tmux
        echo $? > "$results_dir/omt.status"
    ) & pids+=($!)
    
    # Wait for all shell installations
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    # Check results
    local zsh_installed=false
    if [ -f "$results_dir/omz.status" ] && [ "$(cat "$results_dir/omz.status")" = "0" ]; then
        zsh_installed=true
    fi
    
    # 3.2 Install zsh-specific components (depends on Oh My Zsh)
    if [ "$zsh_installed" = true ]; then
        print_info "Installing Zsh enhancements..."
        
        # These depend on Oh My Zsh being installed first
        install_powerlevel10k || print_warning "Powerlevel10k installation failed"
        install_zsh_plugins || print_warning "Some Zsh plugins failed to install"
    else
        print_warning "Skipping Zsh enhancements (Oh My Zsh not installed)"
    fi
    
    # Cleanup
    rm -rf "$results_dir"
    
    print_status "Phase 3 completed: Shell environment configured"
    return 0
}

# Phase 4: Development Tools (Parallel installation)
phase4_development_tools() {
    print_header "Phase 4: Development Tools Installation"
    
    print_info "Installing language toolchains in parallel..."
    local pids=()
    local results_dir=$(create_temp_dir)
    
    # All these are independent and can run in parallel
    (
        print_debug "Installing Node.js via NVM..."
        install_nvm
        echo $? > "$results_dir/nvm.status"
    ) & pids+=($!)
    
    (
        print_debug "Installing Rust toolchain..."
        install_rust
        echo $? > "$results_dir/rust.status"
    ) & pids+=($!)
    
    (
        print_debug "Installing Python package manager (uv)..."
        install_uv
        echo $? > "$results_dir/uv.status"
    ) & pids+=($!)
    
    # Monitor progress
    local total=${#pids[@]}
    local completed=0
    
    for pid in "${pids[@]}"; do
        wait "$pid"
        completed=$((completed + 1))
        show_progress "$completed" "$total" "Installing development tools"
    done
    
    # Check results and report
    local failed=0
    for status_file in "$results_dir"/*.status; do
        if [ -f "$status_file" ] && [ "$(cat "$status_file")" != "0" ]; then
            failed=$((failed + 1))
        fi
    done
    
    if [ $failed -gt 0 ]; then
        print_warning "$failed development tool(s) failed to install"
    fi
    
    # Cleanup
    rm -rf "$results_dir"
    
    print_status "Phase 4 completed: Development tools installed"
    return 0
}

# Phase 5: System Tools (Can run after core packages)
phase5_system_tools() {
    print_header "Phase 5: System Tools Installation"
    
    # Install monitoring tools
    print_info "Installing system monitoring tools..."
    install_nvtop || print_warning "nvtop installation failed"
    
    # Add more system tools here as needed
    # Examples: htop, btop, ncdu, etc.
    
    print_status "Phase 5 completed: System tools installed"
    return 0
}

# Phase 6: Configuration (Must run last)
phase6_configuration() {
    print_header "Phase 6: Final Configuration"
    
    # 6.1 Create symlinks (requires all configs to be ready)
    print_info "Creating dotfile symlinks..."
    create_symlinks || print_warning "Some symlinks failed"
    
    # 6.2 Change default shell (should be last)
    print_info "Setting default shell..."
    change_default_shell || print_warning "Could not change default shell"
    
    print_status "Phase 6 completed: Configuration applied"
    return 0
}

# Main orchestration function
execute_installation_phases() {
    local phase_results=()
    local start_time=$(date +%s)
    
    # Phase 1: System Preparation (Sequential, Required)
    if phase1_system_preparation; then
        phase_results+=("✅ System Preparation")
    else
        phase_results+=("❌ System Preparation")
        print_error "Critical phase failed, aborting installation"
        return 1
    fi
    
    # Phase 2: Core Packages (Sequential, Required)
    if phase2_core_packages; then
        phase_results+=("✅ Core Packages")
    else
        phase_results+=("⚠️  Core Packages (partial)")
    fi
    
    # Phases 3-5 can run in parallel since they're independent
    print_header "Parallel Installation Phase"
    print_info "Running independent installations in parallel..."
    
    local parallel_pids=()
    local parallel_results_dir=$(create_temp_dir)
    
    # Start parallel phases
    (
        phase3_shell_environment
        echo $? > "$parallel_results_dir/phase3.status"
    ) & parallel_pids+=($!)
    
    (
        phase4_development_tools
        echo $? > "$parallel_results_dir/phase4.status"
    ) & parallel_pids+=($!)
    
    (
        phase5_system_tools
        echo $? > "$parallel_results_dir/phase5.status"
    ) & parallel_pids+=($!)
    
    # Wait for all parallel phases
    for pid in "${parallel_pids[@]}"; do
        wait "$pid"
    done
    
    # Check parallel phase results
    if [ -f "$parallel_results_dir/phase3.status" ] && [ "$(cat "$parallel_results_dir/phase3.status")" = "0" ]; then
        phase_results+=("✅ Shell Environment")
    else
        phase_results+=("⚠️  Shell Environment")
    fi
    
    if [ -f "$parallel_results_dir/phase4.status" ] && [ "$(cat "$parallel_results_dir/phase4.status")" = "0" ]; then
        phase_results+=("✅ Development Tools")
    else
        phase_results+=("⚠️  Development Tools")
    fi
    
    if [ -f "$parallel_results_dir/phase5.status" ] && [ "$(cat "$parallel_results_dir/phase5.status")" = "0" ]; then
        phase_results+=("✅ System Tools")
    else
        phase_results+=("⚠️  System Tools")
    fi
    
    # Cleanup parallel results
    rm -rf "$parallel_results_dir"
    
    # Phase 6: Configuration (Sequential, Must be last)
    if phase6_configuration; then
        phase_results+=("✅ Configuration")
    else
        phase_results+=("⚠️  Configuration")
    fi
    
    # Calculate execution time
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    # Print summary
    echo
    print_header "Installation Phase Summary"
    for result in "${phase_results[@]}"; do
        echo "  $result"
    done
    echo
    print_info "Total execution time: ${minutes}m ${seconds}s"
    
    # Check if any critical phase failed
    if [[ "${phase_results[*]}" == *"❌"* ]]; then
        return 1
    fi
    
    return 0
}

# Validation function to check installation success
validate_installation() {
    print_header "Validating Installation"
    
    local validation_passed=true
    local checks=()
    
    # Check shell frameworks
    if [ -d "$HOME/.oh-my-zsh" ]; then
        checks+=("✅ Oh My Zsh")
    else
        checks+=("❌ Oh My Zsh")
        validation_passed=false
    fi
    
    # Check for zsh
    if command_exists zsh; then
        checks+=("✅ Zsh")
    else
        checks+=("❌ Zsh")
        validation_passed=false
    fi
    
    # Check for git
    if command_exists git; then
        checks+=("✅ Git")
    else
        checks+=("❌ Git")
        validation_passed=false
    fi
    
    # Check for development tools
    if command_exists node || [ -d "$HOME/.nvm" ]; then
        checks+=("✅ Node.js/NVM")
    else
        checks+=("⚠️  Node.js/NVM")
    fi
    
    if command_exists cargo || [ -d "$HOME/.cargo" ]; then
        checks+=("✅ Rust/Cargo")
    else
        checks+=("⚠️  Rust/Cargo")
    fi
    
    # Check symlinks
    local symlink_count=0
    for file in "${DOTFILES_TO_LINK[@]}"; do
        if [ -L "$HOME/$file" ]; then
            symlink_count=$((symlink_count + 1))
        fi
    done
    
    if [ $symlink_count -eq ${#DOTFILES_TO_LINK[@]} ]; then
        checks+=("✅ Dotfile Symlinks")
    elif [ $symlink_count -gt 0 ]; then
        checks+=("⚠️  Dotfile Symlinks ($symlink_count/${#DOTFILES_TO_LINK[@]})")
    else
        checks+=("❌ Dotfile Symlinks")
        validation_passed=false
    fi
    
    # Print validation results
    print_info "Installation validation results:"
    for check in "${checks[@]}"; do
        echo "  $check"
    done
    
    if [ "$validation_passed" = true ]; then
        print_status "Installation validation passed"
        return 0
    else
        print_error "Installation validation failed"
        return 1
    fi
}