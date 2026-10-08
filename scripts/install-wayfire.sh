#!/usr/bin/env bash
set -e

BUILD_DIR="$HOME/src/wayfire-build"
CONFIG_REPO="https://github.com/ClaudeStabile/wayfireFS.git"
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

    if [ -d "build" ]; then
        meson setup build --reconfigure --prefix=/usr/local --buildtype=release
    else
        meson setup build --prefix=/usr/local --buildtype=release
    fi

    ninja -C build
    sudo ninja -C build install | grep -E 'Installing|Replacing' | awk '{print $2}' | sudo tee -a "$LOG_FILE"
    
    sudo ldconfig
done

echo "=========================================="
echo " 4. Fetching & Deploying GitHub Configs"
echo "=========================================="

cd "$BUILD_DIR"
if [ -d "wayfireFS" ]; then
    rm -rf wayfireFS
fi

git clone "$CONFIG_REPO"

echo "Deploying configuration files to ~/.config/ ..."
mkdir -p "$HOME/.config"

if [ -d "$BUILD_DIR/wayfireFS/config" ]; then
    # Copy all .ini, .css, and subfolders from the repo's config/ directory to ~/.config/
    cp -r "$BUILD_DIR/wayfireFS/config/"* "$HOME/.config/"
    echo "Successfully deployed configuration files from wayfireFS/config!"
else
    echo "Warning: 'config' directory not found in the cloned repository."
fi

echo "=========================================="
echo " 5. Creating Wayland Desktop Session"
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
echo " Wayfire Stack and Configs Deployed!"
echo " Logged installed files to: $LOG_FILE"
echo "=========================================="
