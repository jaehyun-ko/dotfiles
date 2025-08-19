#!/bin/bash

# Package management functions

# Update package manager
update_package_manager() {
    print_info "Updating package manager..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_debug "[DRY RUN] Would execute: $PKG_UPDATE"
        return 0
    fi
    
    retry_command "$PKG_UPDATE" "package manager update" || {
        print_warning "Failed to update package manager, continuing anyway..."
    }
}

# Install single package
install_package() {
    local package="$1"
    local required="${2:-true}"
    
    # Get OS-specific package name
    local pkg_name=$(get_package_name "$package")
    
    if [ -z "$pkg_name" ] || [ "$pkg_name" == "" ]; then
        print_debug "Package $package not available for $OS"
        return 1
    fi
    
    # Check if already installed
    if [[ "$FORCE_INSTALL" != "true" ]]; then
        if command_exists "$pkg_name" || is_package_installed "$pkg_name"; then
            print_status "$pkg_name is already installed"
            return 0
        fi
    fi
    
    print_info "Installing $pkg_name..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_debug "[DRY RUN] Would execute: $PKG_INSTALL $pkg_name"
        return 0
    fi
    
    if retry_command "$PKG_INSTALL $pkg_name" "install $pkg_name"; then
        print_status "$pkg_name installed successfully"
        return 0
    else
        if [[ "$required" == "true" ]]; then
            print_error "Failed to install required package: $pkg_name"
            return 1
        else
            print_warning "Failed to install optional package: $pkg_name"
            return 0
        fi
    fi
}

# Install multiple packages in parallel
install_packages_parallel() {
    local -n packages=$1
    local required="${2:-true}"
    local pids=()
    local failed=0
    
    print_info "Installing ${#packages[@]} packages..."
    
    # Create temp directory for status files
    local status_dir=$(create_temp_dir)
    
    local count=0
    for package in "${packages[@]}"; do
        if [ $count -ge $PARALLEL_JOBS ]; then
            # Wait for a slot to be available
            wait -n
        fi
        
        (
            install_package "$package" "$required"
            echo $? > "$status_dir/$(basename "$package").status"
        ) &
        
        pids+=($!)
        count=$((count + 1))
        
        # Update progress
        local installed=$((${#packages[@]} - ${#pids[@]} + 1))
        show_progress "$installed" "${#packages[@]}" "Installing packages"
    done
    
    # Wait for all background jobs
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    # Check results
    for status_file in "$status_dir"/*.status 2>/dev/null; do
        if [ -f "$status_file" ]; then
            local status=$(cat "$status_file")
            if [ "$status" -ne 0 ]; then
                failed=$((failed + 1))
            fi
        fi
    done
    
    # Cleanup
    rm -rf "$status_dir"
    
    if [ $failed -gt 0 ]; then
        print_warning "$failed package(s) failed to install"
        return 1
    else
        print_status "All packages installed successfully"
        return 0
    fi
}

# Install packages sequentially
install_packages_sequential() {
    local -n packages=$1
    local required="${2:-true}"
    local failed=0
    local total=${#packages[@]}
    local current=0
    
    for package in "${packages[@]}"; do
        current=$((current + 1))
        show_progress "$current" "$total" "Installing packages"
        
        if ! install_package "$package" "$required"; then
            failed=$((failed + 1))
        fi
    done
    
    if [ $failed -gt 0 ]; then
        print_warning "$failed package(s) failed to install"
        return 1
    else
        print_status "All packages installed successfully"
        return 0
    fi
}

# Main package installation function
install_packages() {
    local -n packages=$1
    local required="${2:-true}"
    local parallel="${3:-true}"
    
    if [ ${#packages[@]} -eq 0 ]; then
        print_debug "No packages to install"
        return 0
    fi
    
    if [[ "$parallel" == "true" ]] && [ ${#packages[@]} -gt 1 ]; then
        install_packages_parallel packages "$required"
    else
        install_packages_sequential packages "$required"
    fi
}

# Check and install missing dependencies
check_dependencies() {
    local deps=("curl" "git" "wget")
    local missing=()
    
    print_info "Checking dependencies..."
    
    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            missing+=("$dep")
            print_debug "Missing dependency: $dep"
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_info "Installing missing dependencies: ${missing[*]}"
        install_packages missing true false  # Install sequentially
    else
        print_status "All dependencies are satisfied"
    fi
}

# Install package from URL
install_from_url() {
    local name="$1"
    local url="$2"
    local install_cmd="$3"
    
    print_info "Installing $name from URL..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_debug "[DRY RUN] Would download from: $url"
        return 0
    fi
    
    local temp_file=$(mktemp)
    
    if retry_command "curl -fsSL '$url' -o '$temp_file'" "download $name"; then
        if [ -n "$install_cmd" ]; then
            eval "$install_cmd" < "$temp_file"
        else
            bash "$temp_file"
        fi
        local result=$?
        rm -f "$temp_file"
        return $result
    else
        rm -f "$temp_file"
        print_error "Failed to download $name"
        return 1
    fi
}

# Clone git repository
clone_repository() {
    local url="$1"
    local dest="$2"
    local depth="${3:-1}"
    
    if [ -d "$dest" ]; then
        if [[ "$FORCE_INSTALL" == "true" ]]; then
            print_info "Removing existing $dest..."
            rm -rf "$dest"
        else
            print_status "$dest already exists"
            return 0
        fi
    fi
    
    print_info "Cloning repository to $dest..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_debug "[DRY RUN] Would clone: $url to $dest"
        return 0
    fi
    
    if [ "$depth" -gt 0 ]; then
        retry_command "git clone --depth=$depth '$url' '$dest'" "clone repository"
    else
        retry_command "git clone '$url' '$dest'" "clone repository"
    fi
}