#!/usr/bin/env bash

set -e

TARGET="/storage/emulated/0/Android/media/is.xyz.mpv"
BACKUP="/storage/emulated/0/Android/media/is.xyz.mpv.bak"

echo "Target directory: $TARGET"

# Backup existing config if exists
if [ -d "$TARGET" ]; then
    echo "Existing installation found."

    # Remove old backup if exists
    if [ -d "$BACKUP" ]; then
        echo "Removing old backup..."
        rm -rf "$BACKUP"
    fi

    echo "Creating backup..."
    mv "$TARGET" "$BACKUP"
fi

# Create fresh target directory
mkdir -p "$TARGET"

# Copy shaders
echo "Copying shaders..."
cp -r shaders "$TARGET/"

# Copy base scripts
echo "Copying scripts..."
cp -r scripts "$TARGET/"

# Overwrite with Android-specific scripts
if [ -d "conf/android/scripts" ]; then
    echo "Overwriting scripts with Android-specific scripts..."
    mkdir -p "$TARGET/scripts"
    cp -rf conf/android/scripts/* "$TARGET/scripts/"
fi

# Copy configs
echo "Copying mpv.conf..."
cp -f conf/android/mpv.conf "$TARGET/mpv.conf"

echo "Copying input.conf..."
cp -f conf/android/input.conf "$TARGET/input.conf"

echo
echo "Installation completed successfully."
echo "Installed to: $TARGET"

if [ -d "$BACKUP" ]; then
    echo "Backup saved to: $BACKUP"
fi