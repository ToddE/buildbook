#!/usr/bin/env bash
# ============================================================
# BuildBook Installer
# This script installs BuildBook and its dependencies.
# ============================================================
set -e

# Configuration
REPO_RAW_URL="https://raw.githubusercontent.com/ToddE/buildbook/main"
BIN_DIR="$HOME/.local/bin"
INSTALL_PATH="$BIN_DIR/buildbook"

echo "------------------------------------------------------------"
echo "BuildBook Installer"
echo "------------------------------------------------------------"

# 1. Dependency Installation
echo "Checking for system dependencies..."
DEPS="pandoc xelatex bc"
MISSING_DEPS=""

for dep in $DEPS; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        MISSING_DEPS="$MISSING_DEPS $dep"
    fi
done

if [ -n "$MISSING_DEPS" ]; then
    echo "The following dependencies are missing: $MISSING_DEPS"
    read -p "Would you like to attempt to install them via apt? (y/N): " do_inst
    if [[ "$do_inst" =~ ^[Yy]$ ]]; then
        sudo apt update
        sudo apt install -y pandoc texlive-xetex texlive-latex-extra \
                            texlive-fonts-extra fonts-linuxlibertine bc
    else
        echo "Skipping dependency installation. Please install them manually."
    fi
else
    echo "All core system dependencies found."
fi

# 2. Directory Setup
if [ ! -d "$BIN_DIR" ]; then
    echo "Creating $BIN_DIR..."
    mkdir -p "$BIN_DIR"
fi

# 3. Script Download
echo "Downloading buildbook script..."
if command -v wget >/dev/null 2>&1; then
    wget -q -O "$INSTALL_PATH" "$REPO_RAW_URL/buildbook.sh"
elif command -v curl >/dev/null 2>&1; then
    curl -sL -o "$INSTALL_PATH" "$REPO_RAW_URL/buildbook.sh"
else
    echo "Error: Neither wget nor curl found. Cannot download script."
    exit 1
fi

chmod +x "$INSTALL_PATH"
echo "Successfully installed buildbook to $INSTALL_PATH"

# 4. PATH Detection and Configuration
# Determine which shell profile to use
if [[ "$SHELL" == */zsh ]]; then
    PROFILE="$HOME/.zshrc"
elif [[ "$SHELL" == */bash ]]; then
    PROFILE="$HOME/.bashrc"
else
    PROFILE="$HOME/.profile"
fi

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo ""
    echo "NOTE: $BIN_DIR is not in your PATH."
    echo "Detected shell profile: $PROFILE"
    read -p "Would you like to add BuildBook to your PATH in $PROFILE? (y/N): " add_path
    if [[ "$add_path" =~ ^[Yy]$ ]]; then
        echo "" >> "$PROFILE"
        echo "# BuildBook Path" >> "$PROFILE"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$PROFILE"
        echo "PATH updated in $PROFILE. Please run 'source $PROFILE' to apply."
    else
        echo "Please manually add 'export PATH=\"\$HOME/.local/bin:\$PATH\"' to your profile."
    fi
else
    echo "Installation complete! 'buildbook' is already in your PATH."
fi

echo "------------------------------------------------------------"
echo "Installation Finished."
echo "------------------------------------------------------------"