#!/bin/bash

# OS Detection and Package Manager Configuration

detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS_NAME="$NAME"
            OS_VERSION="$VERSION_ID"
        fi
        
        if [ -f /etc/debian_version ]; then
            OS="debian"
            PKG_MANAGER="apt"
            PKG_UPDATE="sudo apt update"
            PKG_INSTALL="sudo apt install -y"
            PKG_SEARCH="apt search"
            PKG_LIST="dpkg -l"
        elif [ -f /etc/redhat-release ]; then
            OS="redhat"
            if command_exists dnf; then
                PKG_MANAGER="dnf"
                PKG_UPDATE="sudo dnf check-update"
                PKG_INSTALL="sudo dnf install -y"
                PKG_SEARCH="dnf search"
                PKG_LIST="rpm -qa"
            else
                PKG_MANAGER="yum"
                PKG_UPDATE="sudo yum check-update"
                PKG_INSTALL="sudo yum install -y"
                PKG_SEARCH="yum search"
                PKG_LIST="rpm -qa"
            fi
        elif [ -f /etc/arch-release ]; then
            OS="arch"
            PKG_MANAGER="pacman"
            PKG_UPDATE="sudo pacman -Sy"
            PKG_INSTALL="sudo pacman -S --noconfirm"
            PKG_SEARCH="pacman -Ss"
            PKG_LIST="pacman -Q"
        elif [ -f /etc/alpine-release ]; then
            OS="alpine"
            PKG_MANAGER="apk"
            PKG_UPDATE="sudo apk update"
            PKG_INSTALL="sudo apk add --no-cache"
            PKG_SEARCH="apk search"
            PKG_LIST="apk info"
        elif [ -f /etc/gentoo-release ]; then
            OS="gentoo"
            PKG_MANAGER="emerge"
            PKG_UPDATE="sudo emerge --sync"
            PKG_INSTALL="sudo emerge"
            PKG_SEARCH="emerge -s"
            PKG_LIST="qlist -I"
        else
            OS="unknown-linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        OS_VERSION=$(sw_vers -productVersion)
        
        if command_exists brew; then
            PKG_MANAGER="brew"
            PKG_UPDATE="brew update"
            PKG_INSTALL="brew install"
            PKG_SEARCH="brew search"
            PKG_LIST="brew list"
        else
            print_warning "Homebrew not installed. Installing..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            
            # Add Homebrew to PATH for current session
            if [[ -f /opt/homebrew/bin/brew ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -f /usr/local/bin/brew ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
            
            PKG_MANAGER="brew"
            PKG_UPDATE="brew update"
            PKG_INSTALL="brew install"
            PKG_SEARCH="brew search"
            PKG_LIST="brew list"
        fi
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
        print_warning "Windows detected. Limited support available."
        
        if command_exists pacman; then
            # MSYS2
            PKG_MANAGER="pacman"
            PKG_UPDATE="pacman -Sy"
            PKG_INSTALL="pacman -S --noconfirm"
            PKG_SEARCH="pacman -Ss"
            PKG_LIST="pacman -Q"
        elif command_exists apt-cyg; then
            # Cygwin
            PKG_MANAGER="apt-cyg"
            PKG_UPDATE="apt-cyg update"
            PKG_INSTALL="apt-cyg install"
            PKG_SEARCH="apt-cyg search"
            PKG_LIST="apt-cyg list"
        else
            OS="unsupported-windows"
        fi
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        OS="freebsd"
        PKG_MANAGER="pkg"
        PKG_UPDATE="sudo pkg update"
        PKG_INSTALL="sudo pkg install -y"
        PKG_SEARCH="pkg search"
        PKG_LIST="pkg info"
    else
        OS="unknown"
    fi
    
    # Export all variables
    export OS
    export OS_NAME
    export OS_VERSION
    export PKG_MANAGER
    export PKG_UPDATE
    export PKG_INSTALL
    export PKG_SEARCH
    export PKG_LIST
}

# Check if package is installed
is_package_installed() {
    local package="$1"
    
    case "$PKG_MANAGER" in
        apt)
            dpkg -l "$package" 2>/dev/null | grep -q "^ii"
            ;;
        yum|dnf)
            rpm -q "$package" &>/dev/null
            ;;
        pacman)
            pacman -Q "$package" &>/dev/null
            ;;
        brew)
            brew list "$package" &>/dev/null
            ;;
        apk)
            apk info -e "$package" &>/dev/null
            ;;
        emerge)
            qlist -I "$package" &>/dev/null
            ;;
        pkg)
            pkg info "$package" &>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# Check system requirements
check_system_requirements() {
    local min_memory=512  # MB
    local min_disk=1024   # MB
    
    print_info "Checking system requirements..."
    
    # Check available memory
    if command_exists free; then
        local available_mem=$(free -m | awk 'NR==2 {print $7}')
        if [ "$available_mem" -lt "$min_memory" ]; then
            print_warning "Low memory available: ${available_mem}MB (recommended: ${min_memory}MB)"
        else
            print_debug "Available memory: ${available_mem}MB"
        fi
    fi
    
    # Check available disk space
    local available_disk=$(df -m "$HOME" | awk 'NR==2 {print $4}')
    if [ "$available_disk" -lt "$min_disk" ]; then
        print_warning "Low disk space available: ${available_disk}MB (recommended: ${min_disk}MB)"
        return 1
    else
        print_debug "Available disk space: ${available_disk}MB"
    fi
    
    # Check internet connectivity
    local connectivity_urls=(
        "https://github.com"
        "https://www.google.com"
        "http://example.com"
    )
    local has_connectivity=false

    for url in "${connectivity_urls[@]}"; do
        if curl -s --head --connect-timeout 5 "$url" >/dev/null 2>&1; then
            print_debug "Internet connectivity confirmed via $url"
            has_connectivity=true
            break
        fi
    done

    if [[ "$has_connectivity" != true ]]; then
        print_error "No internet connectivity detected"
        return 1
    fi
    
    # Check sudo privileges (if not macOS)
    if [[ "$OS" != "macos" ]]; then
        if ! sudo -n true 2>/dev/null; then
            print_warning "Sudo password may be required during installation"
        else
            print_debug "Sudo privileges confirmed"
        fi
    fi

    return 0
}

# Get architecture
get_architecture() {
    local arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        armv7l|armhf)
            echo "armv7"
            ;;
        i386|i686)
            echo "x86"
            ;;
        *)
            echo "$arch"
            ;;
    esac
}

# Export architecture
export ARCH=$(get_architecture)