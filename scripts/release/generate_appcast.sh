#!/usr/bin/env bash

set -euo pipefail

version="${VERSION:?VERSION is required}"
tag="${TAG:?TAG is required}"
zip_path="${ZIP_PATH:?ZIP_PATH is required}"
private_key_file="${SPARKLE_PRIVATE_KEY_FILE:?SPARKLE_PRIVATE_KEY_FILE is required}"
output_path="${OUTPUT_PATH:-dist/pages/appcast.xml}"
minimum_system_version="$(awk -F ' = ' '/^MACOSX_DEPLOYMENT_TARGET/ { print $2 }' config/base.xcconfig)"
signature="$(vendor/Sparkle/bin/sign_update --ed-key-file "$private_key_file" "$zip_path")"
publication_date="$(LC_ALL=C date -R)"
asset_url="https://github.com/tyrival/alt-tab-macos/releases/download/$tag/$(basename "$zip_path")"
release_notes_url="https://github.com/tyrival/alt-tab-macos/releases/tag/$tag"

mkdir -p "$(dirname "$output_path")"
cat > "$output_path" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Moosh updates</title>
    <link>https://tyrival.github.io/alt-tab-macos/appcast.xml</link>
    <description>Moosh release feed</description>
    <language>en</language>
    <item>
      <title>Moosh $version</title>
      <pubDate>$publication_date</pubDate>
      <sparkle:minimumSystemVersion>$minimum_system_version</sparkle:minimumSystemVersion>
      <sparkle:releaseNotesLink>$release_notes_url</sparkle:releaseNotesLink>
      <enclosure url="$asset_url" sparkle:version="$version" sparkle:shortVersionString="$version" $signature type="application/octet-stream"/>
    </item>
  </channel>
</rss>
EOF
