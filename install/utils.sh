#!/bin/bash

# Utility functions for dotfiles installation

# Colors for output
if [[ "${COLOR_ENABLED:-true}" == "true" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    MAGENTA=''
    CYAN=''
    NC=''
fi

# Logging functions
log_init() {
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"
    log_to_file "INFO: Installation started at $(date)"
    log_to_file "INFO: Installer version: $INSTALLER_VERSION"
}

log_to_file() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
    log_to_file "SUCCESS: $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1" >&2
    log_to_file "ERROR: $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
    log_to_file "INFO: $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
    log_to_file "WARNING: $1"
}

print_debug() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${CYAN}[D]${NC} $1"
    fi
    log_to_file "DEBUG: $1"
}

print_header() {
    echo -e "${MAGENTA}===================================================${NC}"
    echo -e "${MAGENTA}    $1${NC}"
    echo -e "${MAGENTA}===================================================${NC}"
    log_to_file "SECTION: $1"
}

# Command checking
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Retry mechanism
retry_command() {
    local cmd="$1"
    local description="${2:-command}"
    local retries=0
    
    while [ $retries -lt $RETRY_COUNT ]; do
        print_debug "Attempting $description (try $((retries + 1))/$RETRY_COUNT)"
        
        if eval "$cmd"; then
            return 0
        fi
        
        retries=$((retries + 1))
        if [ $retries -lt $RETRY_COUNT ]; then
            print_warning "Failed, retrying in ${RETRY_DELAY}s..."
            sleep $RETRY_DELAY
        fi
    done
    
    print_error "Failed after $RETRY_COUNT attempts: $description"
    return 1
}

# Backup file
backup_file() {
    local file="$1"
    if [ -f "$file" ] && [ ! -L "$file" ]; then
        mkdir -p "$BACKUP_DIR"
        local backup_path="$BACKUP_DIR/$(basename "$file")"
        cp -p "$file" "$backup_path"
        print_debug "Backed up $file to $backup_path"
        log_to_file "BACKUP: $file -> $backup_path"
    fi
}

# Progress bar
show_progress() {
    local current=$1
    local total=$2
    local task="${3:-Processing}"
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    
    printf "\r%s: [" "$task"
    printf "%${filled}s" | tr ' ' '='
    printf "%$((width - filled))s" | tr ' ' '-'
    printf "] %d%%" "$percentage"
    
    if [ "$current" -eq "$total" ]; then
        echo
    fi
}

# Confirmation prompt
confirm() {
    local prompt="${1:-Continue?}"
    
    if [[ "$SKIP_CONFIRMATION" == "true" ]]; then
        return 0
    fi
    
    read -r -p "$prompt [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Get package name for current OS
get_package_name() {
    local package_spec="$1"
    local os_index=0
    
    case "$OS" in
        debian) os_index=0 ;;
        redhat) os_index=1 ;;
        arch) os_index=2 ;;
        macos) os_index=3 ;;
        *) echo "$package_spec" | cut -d'|' -f1; return ;;
    esac
    
    # If package spec contains OS-specific names (separated by |)
    if [[ "$package_spec" == *"|"* ]]; then
        echo "$package_spec" | cut -d'|' -f$((os_index + 1))
    else
        echo "$package_spec"
    fi
}

# Check if running in CI environment
is_ci() {
    [[ "${CI:-false}" == "true" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]] || [[ -n "${GITLAB_CI:-}" ]]
}

# Create temporary directory
create_temp_dir() {
    local temp_dir
    temp_dir=$(mktemp -d 2>/dev/null || mktemp -d -t 'dotfiles-install')
    echo "$temp_dir"
}

# Cleanup function
cleanup_on_exit() {
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        print_status "Installation completed successfully"
        log_to_file "Installation completed successfully"
    else
        print_error "Installation failed with exit code $exit_code"
        log_to_file "Installation failed with exit code $exit_code"
    fi
    
    # Cleanup temporary files
    if [ -n "${TEMP_DIR:-}" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
    
    print_info "Log file saved to: $LOG_FILE"
}