#!/usr/bin/env bash

set -euo pipefail

app_path="${APP_PATH:?APP_PATH is required}"
zip_path="${ZIP_PATH:?ZIP_PATH is required}"
dmg_path="${DMG_PATH:?DMG_PATH is required}"
expected_bundle_id="${EXPECTED_BUNDLE_ID:-com.tyrival.moosh}"
expected_architecture="${EXPECTED_ARCHITECTURE:-arm64}"
actual_bundle_id="$(defaults read "$app_path/Contents/Info" CFBundleIdentifier)"
binary_path="$app_path/Contents/MacOS/Moosh"

test "$actual_bundle_id" = "$expected_bundle_id"
file "$binary_path" | grep -q "$expected_architecture"
codesign --verify --deep --strict --verbose=2 "$app_path"
ditto -x -k "$zip_path" "$(mktemp -d)"
hdiutil verify "$dmg_path"
echo "Moosh release artifacts verified"
