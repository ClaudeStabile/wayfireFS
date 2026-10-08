#!/bin/bash
#!/usr/bin/env bash
set -e

BUILD_DIR="$HOME/src/wayfire-build"
PKG_FILE="packages_to_compile_wayfire.list"
LOG_FILE="/var/log/wayfire_installed_files.txt"

echo "=========================================="
echo " 1. Installing APT Dependencies"
echo "=========================================="

if [ ! -f "$PKG_FILE" ]; then
    echo "Error: $PKG_FILE not found in current directory!"
    exit 1
fi

sudo apt update
# Read non-empty, non-comment lines from packages list
APT_PKGS=$(grep -vE '^\s*#|^\s*$' "$PKG_FILE" | tr '\n' ' ')
sudo apt install -y $APT_PKGS

echo "=========================================="
echo " 2. Preparing Build Directory"
echo "=========================================="
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

REPOS=(
    "https://github.com/WayfireWM/wf-config.git"
    "https://github.com/WayfireWM/wayfire.git"
    "https://github.com/WayfireWM/wf-shell.git"
    "https://github.com/WayfireWM/wayfire-plugins-extra.git"
)

# Clear or initialize manifest log
sudo touch "$LOG_FILE"

echo "=========================================="
echo " 3. Cloning, Building & Installing Modules"
echo "=========================================="

for repo in "${REPOS[@]}"; do
    repo_name=$(basename "$repo" .git)
    echo "------------------------------------------"
    echo " Processing: $repo_name"
    echo "------------------------------------------"
    
    cd "$BUILD_DIR"
    if [ ! -d "$repo_name" ]; then
        git clone --recursive "$repo"
        cd "$repo_name"
    else
        cd "$repo_name"
        git pull origin master --recurse-submodules
    fi

    # Configure build
    if [ -d "build" ]; then
        meson setup build --reconfigure --prefix=/usr/local --buildtype=release
    else
        meson setup build --prefix=/usr/local --buildtype=release
    fi

    ninja -C build

    # Record files installed by ninja
    sudo ninja -C build install | grep -E 'Installing|Replacing' | awk '{print $2}' | sudo tee -a "$LOG_FILE"
    
    sudo ldconfig
done

echo "=========================================="
echo " 4. Creating Wayland Desktop Session"
echo "=========================================="

sudo mkdir -p /usr/share/wayland-sessions
sudo tee /usr/share/wayland-sessions/wayfire.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Wayfire
Comment=Wayfire Compositor (Compiled from Source)
Exec=/usr/local/bin/wayfire
Type=Application
DesktopNames=Wayfire;
EOF

echo "/usr/share/wayland-sessions/wayfire.desktop" | sudo tee -a "$LOG_FILE"

echo "=========================================="
echo " Wayfire Stack Successfully Installed!"
echo " Logged installed files to: $LOG_FILE"
echo "=========================================="
