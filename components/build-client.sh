#!/usr/bin/bash

# Build game, reset timestamp on project.godot that changes as part of export, run as client

set -e

OS=$1

case "$OS" in
    "win")
    ENGINE_DEFAULT="../Godot_v3.4.1-stable_win64.exe"
    TEMPLATE="Windows Desktop"
    ;;
    "linux")
    ENGINE_DEFAULT="../Godot_v3.4-stable_linux_headless.64"
    TEMPLATE="Linux/X11"
    ;;
esac

# TODO: jump to right platform and get the specific export_path
NAME=$(grep 'export_path' export_presets.cfg | cut -c14- | sed 's/.$//')
ENGINE=${2:-$ENGINE_DEFAULT}

ORIGINAL_DATE=$(date -r project.godot "+%Y-%m-%d %H:%M:%S")
$ENGINE --no-window --export-debug "$TEMPLATE" || exit 1
touch -m --date="$ORIGINAL_DATE" project.godot

$NAME --client
