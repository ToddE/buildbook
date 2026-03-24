#!/usr/bin/env bash
# ============================================================
# BuildBook Uninstaller
# This script removes BuildBook from ~/.local/bin
# ============================================================
set -e

BIN_DIR="$HOME/.local/bin"
INSTALL_PATH="$BIN_DIR/buildbook"

echo "------------------------------------------------------------"
echo "BuildBook Uninstaller"
echo "------------------------------------------------------------"

if [ -f "$INSTALL_PATH" ]; then
    echo "Removing BuildBook from $INSTALL_PATH..."
    rm "$INSTALL_PATH"
    echo "Successfully removed the buildbook executable."
else
    echo "BuildBook was not found in $INSTALL_PATH."
fi

echo ""
echo "NOTE: This script does not remove system dependencies"
echo "(pandoc, texlive, bc, etc.) as they may be used by other"
echo "applications."
echo ""
echo "To finish cleanup, you may want to manually remove the"
echo "PATH export from your ~/.bashrc or ~/.zshrc if you added it:"
echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
echo "------------------------------------------------------------"