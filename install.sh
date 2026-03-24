#!/usr/bin/env bash
# ============================================================
# BuildBook Installer
# Installs BuildBook to ~/.local/bin and checks dependencies.
# ============================================================
set -e

# --- Configuration ---
# Ensure this matches your actual GitHub path
REPO_RAW_URL="https://raw.githubusercontent.com/ToddE/buildbook/main"
BIN_DIR="$HOME/.local/bin"
INSTALL_PATH="$BIN_DIR/buildbook"

echo "------------------------------------------------------------"
echo "BuildBook Installer"
echo "------------------------------------------------------------"

# 1. Dependency Check
echo "Step 1: Checking system dependencies..."
DEPS=("pandoc" "xelatex" "bc" "wget")
MISSING_DEPS=()

for dep in "${DEPS[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        MISSING_DEPS+=("$dep")
    fi
done

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo "The following dependencies are missing: ${MISSING_DEPS[*]}"
    read -p "Would you like to attempt to install them via apt? (y/N): " do_inst
    if [[ "$do_inst" =~ ^[Yy]$ ]]; then
        sudo apt update
        sudo apt install -y wget pandoc texlive-xetex texlive-latex-extra \
                            texlive-fonts-extra fonts-linuxlibertine bc
    else
        echo "Please install missing dependencies manually to use BuildBook."
    fi
else
    echo "  [OK] All core system dependencies found."
fi

# 2. Directory Setup
if [ ! -d "$BIN_DIR" ]; then
    echo "Step 2: Creating $BIN_DIR..."
    mkdir -p "$BIN_DIR"
fi

# 3. Script Download
echo "Step 3: Downloading BuildBook script..."
echo "  Source: $REPO_RAW_URL/buildbook.sh"

# Use a temporary file for the download to ensure we don't overwrite 
# a working version with a failed download
TEMP_FILE=$(mktemp)

set +e
if command -v wget >/dev/null 2>&1; then
    wget -q --show-progress -O "$TEMP_FILE" "$REPO_RAW_URL/buildbook.sh"
    DL_RET=$?
elif command -v curl >/dev/null 2>&1; then
    curl -sL -o "$TEMP_FILE" "$REPO_RAW_URL/buildbook.sh"
    DL_RET=$?
fi
set -e

if [ "$DL_RET" -ne 0 ] || [ ! -s "$TEMP_FILE" ]; then
    echo "------------------------------------------------------------"
    echo "ERROR: Download failed."
    echo "Please verify that the file exists at the URL above."
    echo "If your repository is private, this one-liner won't work."
    echo "------------------------------------------------------------"
    rm -f "$TEMP_FILE"
    exit 1
fi

mv "$TEMP_FILE" "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"
echo "  [OK] Installed to $INSTALL_PATH"

# 4. PATH Verification
if [[ "$SHELL" == */zsh ]]; then
    PROFILE="$HOME/.zshrc"
elif [[ "$SHELL" == */bash ]]; then
    PROFILE="$HOME/.bashrc"
else
    PROFILE="$HOME/.profile"
fi

echo "Step 4: Verifying PATH..."
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "  $BIN_DIR is not in your current PATH."
    read -p "  Add 'export PATH=\"\$HOME/.local/bin:\$PATH\"' to $PROFILE? (y/N): " add_path
    if [[ "$add_path" =~ ^[Yy]$ ]]; then
        echo "" >> "$PROFILE"
        echo "# BuildBook Path" >> "$PROFILE"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$PROFILE"
        echo "  [DONE] Path updated. Run 'source $PROFILE' to activate."
    fi
else
    echo "  [OK] $BIN_DIR is already in your PATH."
fi

echo "------------------------------------------------------------"
echo "BuildBook Installation Complete!"
echo "Try running: buildbook -v"
echo "------------------------------------------------------------"