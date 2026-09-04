#!/bin/zsh
# gbmt-package-macos.sh
# goldenballoon-mactimber — Intel Mac DMG packaging
#
# Packages the verified "Golden Balloon.app" into a distributable DMG using upstream's
# app-agnostic macos/Scripts/create_dmg.sh (hdiutil-based, styled layout,
# hdiutil verify included), then renames to the series scheme and writes a
# SHA-256 sidecar. Skips upstream's verify_unsigned_dmg.sh because it chains
# into the arm64-hardcoded verify_unsigned_release.sh; the app inside was
# already gate-checked for x86_64 by gbmt-bundle-macos.sh.
#
# The DMG is ad-hoc signed only (no Developer ID, no notarization): first
# launch triggers Gatekeeper's unidentified-developer prompt — see README.md.
#
# Usage:
#   ./gbmt-package-macos.sh
#
# Output:
#   dist/Golden-Balloon-MacTimber-<upstream-version>-Intel-Mac.dmg (+ .sha256)
#
# Log output:
#   logs/package-<timestamp>.log
#
# CHANGELOG
# v1.1  (2026-09-04) - Pin bump to upstream v1.6.0; app bundle is now
#                      "Golden Balloon.app" (upstream rename, engine binary still
#                      mdkr64); pending hardware re-validation
# v1.0  (2026-09-04) - Promoted unchanged after confirmed end-to-end validation
#                      on Intel hardware (see CHANGELOG.md)
# v0.10 (2026-09-03) - Initial version

set -eo pipefail
VERSION="1.1"
SCRIPT_DIR="${0:A:h}"

UPSTREAM_TAG="v1.6.0"
APP_VERSION="${UPSTREAM_TAG#v}"

REPO_DIR="$SCRIPT_DIR/goldenballoon"
APP_PATH="$REPO_DIR/dist/Golden Balloon.app"
DIST_DIR="$SCRIPT_DIR/dist"
DMG_NAME="Golden-Balloon-MacTimber-$APP_VERSION-Intel-Mac.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"
TIMESTAMP="$(date '+%Y%m%d-%H%M')"

LOG_DIR="$SCRIPT_DIR/logs"
LOGFILE="$LOG_DIR/package-$TIMESTAMP.log"
mkdir -p "$LOG_DIR" "$DIST_DIR"

echo "💿 gbmt-package-macos.sh v$VERSION — $(date)" | tee -a "$LOGFILE"
echo "   Log: $LOGFILE" | tee -a "$LOGFILE"

# ── Step 1: Preflight ─────────────────────────────────────────────────────────

echo "" | tee -a "$LOGFILE"
echo "🔍 Step 1: Preflight" | tee -a "$LOGFILE"
if [[ ! -d "$APP_PATH" ]]; then
  echo "   ❌ App not found at: $APP_PATH" | tee -a "$LOGFILE"
  echo "      👉 Run ./gbmt-build-macos.sh && ./gbmt-bundle-macos.sh first." | tee -a "$LOGFILE"
  exit 1
fi
if ! codesign -dvvv "$APP_PATH" 2>&1 | grep -Fq 'Signature=adhoc'; then
  echo "   ❌ App is not ad-hoc sealed — run ./gbmt-bundle-macos.sh first." | tee -a "$LOGFILE"
  exit 1
fi
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Contents/Info.plist")"
if [[ "$BUNDLE_ID" != "com.mkoterski.goldenballoon-mactimber" ]]; then
  echo "   ⚠️  Bundle ID is '$BUNDLE_ID' (not rebranded) — run ./gbmt-bundle-macos.sh." | tee -a "$LOGFILE"
  exit 1
fi
echo "   ✅ App sealed and rebranded ($BUNDLE_ID)" | tee -a "$LOGFILE"

# ── Step 2: Create DMG (upstream hdiutil pipeline) ────────────────────────────

echo "" | tee -a "$LOGFILE"
echo "💿 Step 2: create_dmg.sh" | tee -a "$LOGFILE"
TMP_DMG="$REPO_DIR/dist/gbmt-package-tmp.dmg"
rm -f "$TMP_DMG"
( cd "$REPO_DIR" && ./macos/Scripts/create_dmg.sh "$APP_PATH" "$TMP_DMG" ) 2>&1 | tee -a "$LOGFILE"
[[ -f "$TMP_DMG" ]] || { echo "   ❌ DMG was not created." | tee -a "$LOGFILE"; exit 1; }
mv -f "$TMP_DMG" "$DMG_PATH"
echo "   ✅ $DMG_PATH ($(du -h "$DMG_PATH" | cut -f1))" | tee -a "$LOGFILE"

# ── Step 3: SHA-256 sidecar ───────────────────────────────────────────────────

echo "" | tee -a "$LOGFILE"
echo "🔐 Step 3: SHA-256 sidecar" | tee -a "$LOGFILE"
( cd "$DIST_DIR" && shasum -a 256 "$DMG_NAME" > "$DMG_NAME.sha256" )
echo "   ✅ $(cat "$DMG_PATH.sha256")" | tee -a "$LOGFILE"

# ── Summary ───────────────────────────────────────────────────────────────────

echo "" | tee -a "$LOGFILE"
echo "════════════════════════════════════════════════════════════════" | tee -a "$LOGFILE"
echo "✅ gbmt-package-macos.sh v$VERSION complete!" | tee -a "$LOGFILE"
echo "   📍 $DMG_PATH" | tee -a "$LOGFILE"
echo "   📄 $LOGFILE" | tee -a "$LOGFILE"
echo "   👉 Test: open DMG, drag app to /Applications, first launch needs" | tee -a "$LOGFILE"
echo "      System Settings → Privacy & Security → Open Anyway (see README)" | tee -a "$LOGFILE"
echo "════════════════════════════════════════════════════════════════" | tee -a "$LOGFILE"
