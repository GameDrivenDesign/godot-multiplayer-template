#!/usr/bin/bash

# Build game, reset timestamp on project.godot that changes as part of export, run as client

set -e

# NAME=$1
# TODO: jump to right platform and get the specific export_path
NAME=$(grep 'export_path' export_presets.cfg | cut -c14- | sed 's/.$//')
ENGINE=${1:-../Godot_v3.4-stable_linux_headless.64}

ORIGINAL_DATE=$(date -r project.godot "+%Y-%m-%d %H:%M:%S")
$ENGINE --export-debug "Linux/X11" || exit 1
touch -m --date="$ORIGINAL_DATE" project.godot

$NAME --client
