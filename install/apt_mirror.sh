#!/bin/bash

# APT Mirror Configuration for faster package downloads

# Backup original sources.list
backup_apt_sources() {
    local sources_file="/etc/apt/sources.list"
    local backup_file="/etc/apt/sources.list.backup.$(date +%Y%m%d)"
    
    if [ -f "$sources_file" ] && [ ! -f "$backup_file" ]; then
        print_info "Backing up original sources.list..."
        sudo cp "$sources_file" "$backup_file" || {
            print_warning "Failed to backup sources.list"
            return 1
        }
        print_status "Backup created: $backup_file"
    fi
    return 0
}

# Detect best mirror based on location
detect_best_mirror() {
    local country=""
    
    # Try to detect country from various sources
    if command_exists curl; then
        # Try ipinfo.io
        country=$(curl -s https://ipinfo.io/country 2>/dev/null | tr -d '\n')
        
        # Fallback to ip-api.com
        if [ -z "$country" ]; then
            country=$(curl -s http://ip-api.com/json/ 2>/dev/null | grep -Po '"countryCode":"[^"]*' | cut -d'"' -f4)
        fi
    fi
    
    # Select mirror based on country
    case "${country^^}" in
        KR|KOREA)
            echo "kr"
            ;;
        JP|JAPAN)
            echo "jp"
            ;;
        CN|CHINA)
            echo "cn"
            ;;
        US|USA)
            echo "us"
            ;;
        *)
            echo "default"
            ;;
    esac
}

# Get mirror URL based on location
get_mirror_url() {
    local location="${1:-$(detect_best_mirror)}"
    local ubuntu_codename="${2:-$(lsb_release -cs 2>/dev/null)}"
    
    case "$location" in
        kr)
            # Kakao mirror (Korea) - Usually fastest in Korea
            echo "http://mirror.kakao.com/ubuntu/"
            ;;
        jp)
            # JAIST mirror (Japan)
            echo "http://ftp.jaist.ac.jp/pub/Linux/ubuntu/"
            ;;
        cn)
            # Aliyun mirror (China)
            echo "http://mirrors.aliyun.com/ubuntu/"
            ;;
        us)
            # US mirror
            echo "http://us.archive.ubuntu.com/ubuntu/"
            ;;
        *)
            # Default Ubuntu mirror
            echo "http://archive.ubuntu.com/ubuntu/"
            ;;
    esac
}

# Configure APT mirror for Ubuntu/Debian
configure_apt_mirror() {
    # Only for Debian-based systems
    if [[ "$OS" != "debian" ]]; then
        print_debug "Not a Debian-based system, skipping APT mirror configuration"
        return 0
    fi
    
    # Check if running in CI or container
    if is_ci || [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
        print_info "Running in CI/container environment, skipping mirror configuration"
        return 0
    fi
    
    # Check if user wants to change mirror
    if [[ "$SKIP_MIRROR_CHANGE" == "true" ]]; then
        print_info "Skipping APT mirror configuration (--skip-mirror)"
        return 0
    fi
    
    print_info "Configuring APT mirror for faster downloads..."
    
    # Detect distribution
    local distro=""
    local codename=""
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        distro="${ID,,}"
        codename="${VERSION_CODENAME:-$(lsb_release -cs 2>/dev/null)}"
    fi
    
    if [[ "$distro" != "ubuntu" ]] && [[ "$distro" != "debian" ]]; then
        print_debug "Distribution $distro doesn't support mirror change"
        return 0
    fi
    
    # Backup original sources
    if ! backup_apt_sources; then
        print_warning "Skipping mirror configuration due to backup failure"
        return 1
    fi
    
    # Detect best mirror
    local location=$(detect_best_mirror)
    local mirror_url=$(get_mirror_url "$location" "$codename")
    
    print_info "Detected location: $location"
    print_info "Selected mirror: $mirror_url"
    
    # Ask for confirmation
    if ! confirm "Change APT mirror to $mirror_url for faster downloads?"; then
        print_info "Keeping original APT sources"
        return 0
    fi
    
    # Create new sources.list
    local temp_sources=$(mktemp)
    
    if [[ "$distro" == "ubuntu" ]]; then
        cat > "$temp_sources" << EOF
# Ubuntu mirror - $mirror_url
deb $mirror_url $codename main restricted universe multiverse
deb $mirror_url $codename-updates main restricted universe multiverse
deb $mirror_url $codename-backports main restricted universe multiverse
deb $mirror_url $codename-security main restricted universe multiverse

# Uncomment to enable source packages
# deb-src $mirror_url $codename main restricted universe multiverse
# deb-src $mirror_url $codename-updates main restricted universe multiverse
# deb-src $mirror_url $codename-backports main restricted universe multiverse
# deb-src $mirror_url $codename-security main restricted universe multiverse
EOF
    elif [[ "$distro" == "debian" ]]; then
        cat > "$temp_sources" << EOF
# Debian mirror
deb $mirror_url $codename main contrib non-free
deb $mirror_url $codename-updates main contrib non-free
deb http://security.debian.org/debian-security $codename-security main contrib non-free

# Uncomment to enable source packages
# deb-src $mirror_url $codename main contrib non-free
# deb-src $mirror_url $codename-updates main contrib non-free
# deb-src http://security.debian.org/debian-security $codename-security main contrib non-free
EOF
    fi
    
    # Apply new sources
    if sudo cp "$temp_sources" /etc/apt/sources.list; then
        print_status "APT mirror changed successfully"
        
        # Update package lists with new mirror
        print_info "Updating package lists with new mirror..."
        if sudo apt update; then
            print_status "Package lists updated successfully"
        else
            print_error "Failed to update package lists, reverting to original sources"
            sudo cp "/etc/apt/sources.list.backup.$(date +%Y%m%d)" /etc/apt/sources.list
            sudo apt update
            return 1
        fi
    else
        print_error "Failed to update sources.list"
        rm -f "$temp_sources"
        return 1
    fi
    
    rm -f "$temp_sources"
    return 0
}

# Speed test for mirrors
test_mirror_speed() {
    local mirror_url="$1"
    local test_file="ls-lR.gz"  # Common test file on Ubuntu mirrors
    
    print_info "Testing mirror speed: $mirror_url"
    
    # Test download speed (timeout after 5 seconds)
    local start_time=$(date +%s%N)
    
    if curl -s --max-time 5 -o /dev/null "${mirror_url}${test_file}" 2>/dev/null; then
        local end_time=$(date +%s%N)
        local duration=$((($end_time - $start_time) / 1000000))  # Convert to milliseconds
        echo "$duration"
    else
        echo "999999"  # Return high number for failed/slow mirrors
    fi
}

# Find fastest mirror from a list
find_fastest_mirror() {
    local mirrors=(
        "http://mirror.kakao.com/ubuntu/"
        "http://ftp.kaist.ac.kr/ubuntu/"
        "http://ftp.jaist.ac.jp/pub/Linux/ubuntu/"
        "http://archive.ubuntu.com/ubuntu/"
    )
    
    local fastest_mirror=""
    local fastest_time=999999
    
    print_info "Finding fastest mirror (this may take a moment)..."
    
    for mirror in "${mirrors[@]}"; do
        local time=$(test_mirror_speed "$mirror")
        print_debug "Mirror $mirror: ${time}ms"
        
        if [ "$time" -lt "$fastest_time" ]; then
            fastest_time="$time"
            fastest_mirror="$mirror"
        fi
    done
    
    if [ -n "$fastest_mirror" ]; then
        print_status "Fastest mirror: $fastest_mirror (${fastest_time}ms)"
        echo "$fastest_mirror"
    else
        print_warning "Could not determine fastest mirror, using default"
        echo "http://archive.ubuntu.com/ubuntu/"
    fi
}

# Restore original sources.list
restore_apt_sources() {
    local backup_file="/etc/apt/sources.list.backup.$(date +%Y%m%d)"
    
    if [ -f "$backup_file" ]; then
        print_info "Restoring original APT sources..."
        if sudo cp "$backup_file" /etc/apt/sources.list; then
            print_status "Original sources restored"
            sudo apt update
            return 0
        else
            print_error "Failed to restore original sources"
            return 1
        fi
    else
        print_warning "No backup file found"
        return 1
    fi
}

# Main function to setup APT mirror
setup_apt_mirror() {
    # Skip if not applicable
    if [[ "$OS" != "debian" ]]; then
        return 0
    fi
    
    # Skip in certain environments
    if [[ "$SKIP_MIRROR_CHANGE" == "true" ]] || is_ci; then
        return 0
    fi
    
    # Configure mirror with auto-detection
    if [[ "$AUTO_MIRROR" == "true" ]]; then
        # Auto-select without prompting
        export SKIP_CONFIRMATION=true
        configure_apt_mirror
    elif [[ "$FASTEST_MIRROR" == "true" ]]; then
        # Find and use fastest mirror
        local fastest=$(find_fastest_mirror)
        export MIRROR_URL="$fastest"
        configure_apt_mirror
    else
        # Interactive configuration
        configure_apt_mirror
    fi
}