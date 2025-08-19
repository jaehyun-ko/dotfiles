#!/bin/bash

# Intelligent Dotfiles Installation Script - Main Entry Point
# Version 2.0.0 - Modular Architecture

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                export FORCE_INSTALL=true
                shift
                ;;
            --verbose|-v)
                export VERBOSE=true
                shift
                ;;
            --dry-run)
                export DRY_RUN=true
                shift
                ;;
            --no-color)
                export COLOR_ENABLED=false
                shift
                ;;
            --parallel-jobs)
                export PARALLEL_JOBS="$2"
                shift 2
                ;;
            --skip-confirmation|-y)
                export SKIP_CONFIRMATION=true
                shift
                ;;
            --skip-mirror)
                export SKIP_MIRROR_CHANGE=true
                shift
                ;;
            --skip-pip-mirror)
                export SKIP_PIP_MIRROR=true
                shift
                ;;
            --auto-mirror)
                export AUTO_MIRROR=true
                shift
                ;;
            --fastest-mirror)
                export FASTEST_MIRROR=true
                shift
                ;;
            --mirror-location)
                export MIRROR_LOCATION="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Show help message
show_help() {
    cat << EOF
Intelligent Dotfiles Installer v2.0.0

Usage: $0 [OPTIONS]

Options:
    --force                 Force reinstall even if already installed
    --verbose, -v          Enable verbose output
    --dry-run              Simulate installation without making changes
    --no-color             Disable colored output
    --parallel-jobs N      Number of parallel jobs (default: 4)
    --skip-confirmation, -y Skip all confirmation prompts
    --help, -h             Show this help message

Mirror Options:
    --skip-mirror          Skip APT mirror configuration (Ubuntu/Debian)
    --skip-pip-mirror      Skip pip mirror configuration
    --auto-mirror          Automatically select best mirror (no prompts)
    --fastest-mirror       Test and select fastest mirror (slower startup)
    --mirror-location LOC  Force specific mirror (kr, jp, cn, us)

Examples:
    # Normal installation
    $0

    # Korean users - auto select Kakao mirror
    $0 --auto-mirror

    # Force reinstall with verbose output
    $0 --force --verbose

    # Dry run to see what would be installed
    $0 --dry-run

    # Fast installation with no prompts and fastest mirror
    $0 -y --fastest-mirror --parallel-jobs 8

    # Skip mirror change (use current sources)
    $0 --skip-mirror

EOF
}

# Load modules
load_modules() {
    local modules=(
        "config.sh"
        "utils.sh"
        "os_detection.sh"
        "apt_mirror.sh"
        "package_manager.sh"
        "installers.sh"
        "installation_phases.sh"
    )
    
    for module in "${modules[@]}"; do
        local module_path="$SCRIPT_DIR/install/$module"
        if [ -f "$module_path" ]; then
            source "$module_path" || {
                echo "Failed to load module: $module"
                exit 1
            }
        else
            echo "Module not found: $module_path"
            exit 1
        fi
    done
}

# Main installation orchestrator
main() {
    # Parse arguments first
    parse_arguments "$@"
    
    # Load configuration and modules
    load_modules
    
    # Set up trap for cleanup
    trap cleanup_on_exit EXIT
    
    # Initialize logging
    log_init
    
    # Print header
    print_header "Intelligent Dotfiles Installer v$INSTALLER_VERSION"
    
    # Detect OS
    detect_os
    print_info "Detected OS: $OS ($OS_NAME $OS_VERSION)"
    print_info "Package Manager: $PKG_MANAGER"
    print_info "Architecture: $ARCH"
    echo
    
    # Check system requirements
    if ! check_system_requirements; then
        print_error "System requirements not met"
        if ! confirm "Continue anyway?"; then
            exit 1
        fi
    fi
    
    # Show installation plan
    if [[ "$DRY_RUN" == "true" ]]; then
        print_warning "DRY RUN MODE - No changes will be made"
    fi
    
    print_info "Installation will proceed in 6 optimized phases:"
    print_info "  Phase 1: System Preparation (APT mirror, package manager update)"
    print_info "  Phase 2: Core Packages (basic, development, optional)"
    print_info "  Phase 3-5: Parallel Installation (shell, dev tools, system tools)"
    print_info "  Phase 6: Configuration (symlinks, shell setup)"
    echo
    
    if ! confirm "Proceed with installation?"; then
        print_info "Installation cancelled"
        exit 0
    fi
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    print_info "Backup directory: $BACKUP_DIR"
    
    # Execute optimized installation phases
    if execute_installation_phases; then
        print_status "All installation phases completed successfully"
    else
        print_error "Some installation phases encountered errors"
        print_info "Check the log for details: $LOG_FILE"
    fi
    
    # Validate installation
    echo
    if validate_installation; then
        print_status "Installation validation passed"
    else
        print_warning "Installation validation detected issues"
        print_info "Some components may need manual installation"
    fi
    
    # Final summary
    echo
    print_header "Installation Summary"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_warning "DRY RUN completed - no actual changes were made"
    else
        print_status "Installation completed successfully!"
    fi
    
    print_info "Log file: $LOG_FILE"
    
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A $BACKUP_DIR)" ]; then
        print_info "Backups saved to: $BACKUP_DIR"
    fi
    
    echo
    print_info "Next steps:"
    print_info "  1. Restart your terminal or run: source ~/.zshrc"
    print_info "  2. Configure Powerlevel10k: p10k configure"
    print_info "  3. Review the log file for any warnings"
    
    if [ "$SHELL" != "$(which zsh)" ]; then
        print_info "  4. Log out and log back in to use zsh as default shell"
    fi
}

# Check if being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Being executed
    main "$@"
fi