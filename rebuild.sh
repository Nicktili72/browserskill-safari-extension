#!/bin/bash
# Regenerates and builds the Xcode wrapper from scratch.
#
# safari-web-extension-converter --copy-resources copies its source
# directory *verbatim*. Two things follow from that:
#  - --project-location must never be nested inside the source directory,
#    or it recurses into its own output until it hits a path-length error.
#  - the source directory must contain only the extension's own files —
#    not .git, node_modules, this script, etc. So this script stages a
#    clean copy in .rebuild-src/ (gitignored) and converts that, rather
#    than converting the repo root directly.
#
# --copy-resources itself is also required — without it this Xcode/Safari
# build silently produces an empty Resources/ folder (no manifest.json),
# and the extension never appears in Safari at all, with no error shown
# anywhere. See README.md's "Bugs found" section.
set -euo pipefail
cd "$(dirname "$0")"

REPO_NAME="$(basename "$PWD")"
SRC_STAGE=".rebuild-src"
WRAPPER_DIR="../${REPO_NAME}-wrapper"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}"

echo "=== Staging a clean copy of the extension source ==="
rm -rf "$SRC_STAGE"
mkdir "$SRC_STAGE"
cp manifest.json protocol.js background.js content.js confirm.html confirm.js icon-128.png "$SRC_STAGE/"

echo "=== Regenerating Xcode project ==="
rm -rf "$WRAPPER_DIR"
xcrun safari-web-extension-converter "$SRC_STAGE" \
  --project-location "$WRAPPER_DIR" \
  --app-name "BrowserSkill for Safari" --macos-only --no-open --no-prompt --copy-resources
rm -rf "$SRC_STAGE"

echo "=== Building ==="
cd "$WRAPPER_DIR/BrowserSkill for Safari"
xcodebuild -project "BrowserSkill for Safari.xcodeproj" -scheme "BrowserSkill for Safari" \
  -configuration Debug -derivedDataPath ../build build

APP="../build/Build/Products/Debug/BrowserSkill for Safari.app"
echo "=== Built: $APP ==="
echo "Next: fully quit Safari, then run:  open \"$(pwd)/$APP\""
