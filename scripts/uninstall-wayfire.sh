#!/bin/bash
#!/usr/bin/env bash
set -e

BUILD_DIR="$HOME/src/wayfire-build"
PKG_FILE="packages_to_compile_wayfire.list"
LOG_FILE="/var/log/wayfire_installed_files.txt"

echo "=========================================="
echo " 1. Removing Installed Wayfire Files"
echo "=========================================="

if [ -f "$LOG_FILE" ]; then
    echo "Removing compiled binaries and libraries tracked in $LOG_FILE..."
    while IFS= read -r file; do
        if [ -f "$file" ] || [ -L "$file" ]; then
            sudo rm -f "$file"
            echo "Removed: $file"
        fi
    done < "$LOG_FILE"
    sudo rm -f "$LOG_FILE"
else
    echo "Manifest file not found. Fallback to manually cleaning Wayfire files in /usr/local..."
    sudo rm -f /usr/local/bin/wayfire
    sudo rm -f /usr/local/bin/wf-dock
    sudo rm -f /usr/local/bin/wf-panel
    sudo rm -f /usr/local/bin/wf-background
    sudo rm -rf /usr/local/lib/*/libwf-config*
    sudo rm -rf /usr/local/lib/*/wayfire/
    sudo rm -rf /usr/local/include/wayfire/
    sudo rm -f /usr/share/wayland-sessions/wayfire.desktop
fi

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
    echo "Warning: $PKG_FILE not found. Skipping package purge."
fi

echo "=========================================="
echo " 3. Cleaning Up Local Build Workspace"
echo "=========================================="

if [ -d "$BUILD_DIR" ]; then
    echo "Removing $BUILD_DIR..."
    rm -rf "$BUILD_DIR"
fi

echo "=========================================="
echo " System rollback complete!"
echo "=========================================="
