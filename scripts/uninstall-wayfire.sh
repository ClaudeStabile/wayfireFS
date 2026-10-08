#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_FILE="${SCRIPT_DIR}/packages_to_compile_wayfire.list"

BUILD_DIR="$HOME/src/wayfire-build"
LOG_FILE="/var/log/wayfire_installed_files.txt"
SESSION_FILE="/usr/share/wayland-sessions/wayfire.desktop"

echo "=========================================="
echo " 1. Removing Installed Wayfire System Files"
echo "=========================================="

if [ -f "$LOG_FILE" ]; then
    echo "Removing compiled binaries, libraries, and session files tracked in $LOG_FILE..."
    while IFS= read -r file; do
        if [ -f "$file" ] || [ -L "$file" ]; then
            sudo rm -f "$file"
            echo "Removed: $file"
        fi
    done < "$LOG_FILE"
    sudo rm -f "$LOG_FILE"
fi

# Explicit fallback cleanup for session files and binaries
if [ -f "$SESSION_FILE" ]; then
    echo "Removing Wayland session file: $SESSION_FILE"
    sudo rm -f "$SESSION_FILE"
fi

echo "Cleaning up Wayfire executables and shared components..."
sudo rm -f /usr/local/bin/wayfire
sudo rm -f /usr/local/bin/wf-dock
sudo rm -f /usr/local/bin/wf-panel
sudo rm -f /usr/local/bin/wf-background
sudo rm -rf /usr/local/lib/*/libwf-config*
sudo rm -rf /usr/local/lib/*/wayfire/
sudo rm -rf /usr/local/include/wayfire/

sudo ldconfig

echo "=========================================="
echo " 2. Removing Installed APT Packages"
echo "=========================================="

if [ -f "$PKG_FILE" ]; then
    APT_PKGS=$(grep -vE '^\s*#|^\s*$' "$PKG_FILE" | tr '\n' ' ')
    echo "Purging packages listed in $PKG_FILE..."
    sudo apt purge -y $APT_PKGS
    sudo apt autoremove --purge -y
else
    echo "Warning: $PKG_FILE not found at $PKG_FILE. Skipping package purge."
fi

echo "=========================================="
echo " 3. Cleaning Up Local Build, Assets & Workspace"
echo "=========================================="

if [ -d "$BUILD_DIR" ]; then
    echo "Removing $BUILD_DIR..."
    rm -rf "$BUILD_DIR"
fi

# Clean up deployed LookAndFeel_2.0 folder from home directory
if [ -d "$HOME/LookAndFeel_2.0" ]; then
    echo "Removing deployed assets folder: $HOME/LookAndFeel_2.0..."
    rm -rf "$HOME/LookAndFeel_2.0"
fi

# Backup user config files
if [ -f "$HOME/.config/wayfire.ini" ] || [ -f "$HOME/.config/wf-shell.ini" ]; then
    echo "Backing up user config files to ~/.config_wayfire_backup..."
    mkdir -p "$HOME/.config_wayfire_backup"
    mv -f "$HOME/.config/wayfire.ini" "$HOME/.config_wayfire_backup/" 2>/dev/null || true
    mv -f "$HOME/.config/wf-shell.ini" "$HOME/.config_wayfire_backup/" 2>/dev/null || true
fi

echo "=========================================="
echo " System rollback complete!"
echo " Wayfire desktop session option removed."
echo "=========================================="
