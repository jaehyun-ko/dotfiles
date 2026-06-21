#!/bin/bash
# Claude Config Installer
# Usage: curl -fsSL <raw-url>/install.sh | bash
# Or: ./install.sh

set -e

DOTFILES_CLAUDE="${DOTFILES_CLAUDE:-$HOME/dotfiles/claude}"
CLAUDE_DIR="$HOME/.claude"

# Validate source directory
DOTFILES_CLAUDE="$(cd "$DOTFILES_CLAUDE" 2>/dev/null && pwd)" || {
    echo "❌ Source directory not found: $DOTFILES_CLAUDE"
    exit 1
}

echo "Installing Claude config..."

# Create .claude directory if not exists
mkdir -p "$CLAUDE_DIR"

# Files to symlink
CONFIG_FILES=(
    "settings.json"
)

# Directories to symlink
CONFIG_DIRS=(
    "output-styles"
)

LEGACY_LINKS=(
    "CLAUDE.md"
    "commands"
    "hooks"
)

LEGACY_PATHS=(
    "agents"
    "plugins"
)

LEGACY_GLOBS=(
    "commands.backup.*"
    "hooks.backup.*"
    "rules.backup.*"
    "ML-STACK.md.backup.*"
)

# Backup and symlink files
SKIP_COUNT=0
LINK_COUNT=0

for file in "${CONFIG_FILES[@]}"; do
    src="$DOTFILES_CLAUDE/$file"
    dst="$CLAUDE_DIR/$file"

    if [ -f "$src" ]; then
        # Skip if already correctly linked
        if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
            SKIP_COUNT=$((SKIP_COUNT + 1))
            continue
        fi

        # Backup existing file if it's not a symlink
        if [ -f "$dst" ] && [ ! -L "$dst" ]; then
            echo "  backing up $file"
            mv "$dst" "$dst.backup.$(date +%Y%m%d)"
        fi

        # Atomic symlink create/replace
        ln -sf "$src" "$dst"
        LINK_COUNT=$((LINK_COUNT + 1))
        echo "  linked $file"
    fi
done

# Symlink directories
for dir in "${CONFIG_DIRS[@]}"; do
    src="$DOTFILES_CLAUDE/$dir"
    dst="$CLAUDE_DIR/$dir"

    if [ -d "$src" ]; then
        # Skip if already correctly linked
        if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
            SKIP_COUNT=$((SKIP_COUNT + 1))
            continue
        fi

        # Backup existing directory if it's not a symlink
        if [ -d "$dst" ] && [ ! -L "$dst" ]; then
            echo "  backing up $dir/"
            mv "$dst" "$dst.backup.$(date +%Y%m%d)"
        fi

        # Atomic symlink create/replace
        ln -sfn "$src" "$dst"
        LINK_COUNT=$((LINK_COUNT + 1))
        echo "  linked $dir/"
    fi
done

for rel in "${LEGACY_LINKS[@]}"; do
    dst="$CLAUDE_DIR/$rel"
    if [ -L "$dst" ]; then
        rm -f "$dst"
        echo "  removed legacy $rel"
    fi
done

for rel in "${LEGACY_PATHS[@]}"; do
    dst="$CLAUDE_DIR/$rel"
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        rm -rf "$dst"
        echo "  removed legacy $rel"
    fi
done

for pattern in "${LEGACY_GLOBS[@]}"; do
    for dst in "$CLAUDE_DIR"/$pattern; do
        [ -e "$dst" ] || [ -L "$dst" ] || continue
        rm -rf "$dst"
        echo "  removed legacy $(basename "$dst")"
    done
done

# Create local directories that shouldn't be synced
LOCAL_DIRS=(
    "cache"
    "logs"
    "todos"
    "plans"
    "session-env"
    "file-history"
)

for dir in "${LOCAL_DIRS[@]}"; do
    mkdir -p "$CLAUDE_DIR/$dir"
done

echo ""
if [ "$LINK_COUNT" -eq 0 ] && [ "$SKIP_COUNT" -gt 0 ]; then
    echo "Claude config already up to date. ($SKIP_COUNT items skipped)"
else
    echo "Claude config installed. ($LINK_COUNT linked, $SKIP_COUNT skipped)"
fi
echo "   Config source: $DOTFILES_CLAUDE"
echo "   Installed to:  $CLAUDE_DIR"
