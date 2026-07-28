#!/usr/bin/env bash

set -euo pipefail

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

require_text() {
    local pattern="$1"
    local path="$2"
    rg -q -- "$pattern" "$path" || fail "$path must contain: $pattern"
}

forbid_product_text() {
    local pattern="$1"
    shift
    if rg -n --glob '*.swift' --glob '*.xcconfig' --glob '*.sh' --glob '*.yml' --glob '*.yaml' --glob '*.plist' --glob '!scripts/tests/test_moosh_personal_static.sh' -- "$pattern" "$@"; then
        fail "product files must not contain: $pattern"
    fi
}

require_text '^PRODUCT_NAME = Moosh$' config/base.xcconfig
require_text '^PRODUCT_BUNDLE_IDENTIFIER = com\.tyrival\.moosh$' config/base.xcconfig
require_text '^ARCHS = arm64$' config/base.xcconfig
require_text 'https://tyrival\.github\.io/alt-tab-macos/appcast\.xml' src/vendors/SparkleDelegate.swift
require_text 'github\.com/tyrival/alt-tab-macos/releases/download' scripts/release/generate_appcast.sh
require_text 'GNU GENERAL PUBLIC LICENSE' LICENCE.md
require_text 'Moosh is an unofficial modified version of AltTab' README.md

forbid_product_text 'com\.lwouis\.alt-tab-macos' config Info.plist src scripts .github alt-tab-macos.xcodeproj
forbid_product_text 'Developer ID Application: Louis Pontoise|QXD7GW8FHY' config scripts .github alt-tab-macos.xcodeproj
forbid_product_text '2e9SQOBoaKElchSa/4QDli/nvYkyuDNfynfzBF6vJK4=' Info.plist
forbid_product_text 'LicenseManager|ProTransitionManager|UpgradeTab|ProBadgeView|licenseApiBaseUrl|checkoutUrl|accountUrl' src
forbid_product_text 'github\.com/lwouis/alt-tab-macos/releases/download' scripts .github src

echo "Moosh personal static checks passed"
