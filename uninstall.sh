#!/usr/bin/env bash
# ============================================================
# BuildBook Uninstaller
# Removes the buildbook executable from ~/.local/bin
# ============================================================
set -e

INSTALL_PATH="$HOME/.local/bin/buildbook"

echo "------------------------------------------------------------"
echo "BuildBook Uninstaller"
echo "------------------------------------------------------------"

if [ -f "$INSTALL_PATH" ]; then
    echo "Removing BuildBook from $INSTALL_PATH..."
    rm "$INSTALL_PATH"
    echo "Successfully removed BuildBook."
else
    echo "BuildBook was not found at $INSTALL_PATH."
fi

echo ""
echo "Note: This script does not remove system dependencies"
echo "(Pandoc, LaTeX, etc.) or your PATH settings."
echo "------------------------------------------------------------"