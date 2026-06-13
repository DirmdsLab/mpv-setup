#!/usr/bin/env bash

set -e

TARGET="$HOME/.config/mpv"
BACKUP="$HOME/.config/mpv.bak"

echo "Target directory: $TARGET"

# Backup existing config if it exists
if [ -d "$TARGET" ]; then
    echo "Existing mpv configuration found."

    # Remove old backup if it exists
    if [ -d "$BACKUP" ]; then
        echo "Removing previous backup..."
        rm -rf "$BACKUP"
    fi

    echo "Creating backup..."
    mv "$TARGET" "$BACKUP"
fi

# Create fresh config directory
mkdir -p "$TARGET"

echo "Copying shaders..."
cp -r shaders "$TARGET/"

echo "Copying scripts..."
cp -r scripts "$TARGET/"

echo "Copying mpv.conf..."
cp -f conf/linux/mpv.conf "$TARGET/mpv.conf"

echo "Copying input.conf..."
cp -f conf/linux/input.conf "$TARGET/input.conf"

echo
echo "Installation completed successfully."
echo "Installed to: $TARGET"

if [ -d "$BACKUP" ]; then
    echo "Backup saved to: $BACKUP"
fi