#!/usr/bin/env bash

set -euo pipefail

app_path="${APP_PATH:?APP_PATH is required}"
version="${VERSION:?VERSION is required}"
output_dir="${OUTPUT_DIR:-dist}"
app_name="Moosh"
zip_path="$output_dir/$app_name-$version.zip"
dmg_path="$output_dir/$app_name-$version-arm64.dmg"
staging_dir="$(mktemp -d)"
trap 'rm -rf "$staging_dir"' EXIT

mkdir -p "$output_dir"
ditto -c -k --keepParent "$app_path" "$zip_path"
cp -R "$app_path" "$staging_dir/$app_name.app"
ln -s /Applications "$staging_dir/Applications"
hdiutil create -volname "$app_name" -srcfolder "$staging_dir" -ov -format UDZO "$dmg_path"
echo "$zip_path"
echo "$dmg_path"
