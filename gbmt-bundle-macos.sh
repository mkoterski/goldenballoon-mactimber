#!/bin/zsh
# gbmt-bundle-macos.sh
# goldenballoon-mactimber — Intel Mac bundle branding + verification
#
# The .app itself is assembled by gbmt-build-macos.sh (via upstream's
# build_app_bundle.sh, which ad-hoc signs it). This script:
#   1. rebrands CFBundleIdentifier to the series scheme
#      (com.mkoterski.goldenballoon-mactimber) and stamps copyright,
#   2. re-seals the bundle ad-hoc (upstream doctrine: re-sign after every
#      bundle mutation — on Tahoe an unsealed bundle reports as "damaged"),
#   3. verifies with upstream's own gates, called directly with x86_64
#      because upstream's verify_unsigned_release.sh hardcodes
#      --expected-arch arm64 (upstream PR candidate, see ROADMAP.md):
#        - verify_gatekeeper_bundle.sh --expected-arch x86_64
#        - verify_asset_free.sh   (proves no ROM/game data is bundled)
#
# Usage:
#   ./gbmt-bundle-macos.sh
#
# Log output:
#   logs/bundle-<timestamp>.log
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
ARCH="x86_64"
DEPLOYMENT_TARGET="14.0"
BUNDLE_ID="com.mkoterski.goldenballoon-mactimber"
COPYRIGHT="© 2026 Golden Balloon contributors (akratch) — Intel Mac packaging: mkoterski"

REPO_DIR="$SCRIPT_DIR/goldenballoon"
APP_PATH="$REPO_DIR/dist/Golden Balloon.app"
INFO_PLIST="$APP_PATH/Contents/Info.plist"
TIMESTAMP="$(date '+%Y%m%d-%H%M')"

LOG_DIR="$SCRIPT_DIR/logs"
LOGFILE="$LOG_DIR/bundle-$TIMESTAMP.log"
mkdir -p "$LOG_DIR"

echo "📦 gbmt-bundle-macos.sh v$VERSION — $(date)" | tee -a "$LOGFILE"
echo "   Log: $LOGFILE" | tee -a "$LOGFILE"

# ── Step 1: Locate app ────────────────────────────────────────────────────────

echo "" | tee -a "$LOGFILE"
echo "🔍 Step 1: Locate app bundle" | tee -a "$LOGFILE"
if [[ ! -f "$INFO_PLIST" ]]; then
  echo "   ❌ App not found at: $APP_PATH" | tee -a "$LOGFILE"
  echo "      👉 Run ./gbmt-build-macos.sh first." | tee -a "$LOGFILE"
  exit 1
fi
echo "   ✅ $APP_PATH" | tee -a "$LOGFILE"

# ── Step 2: Rebrand Info.plist ────────────────────────────────────────────────

echo "" | tee -a "$LOGFILE"
echo "🏷️  Step 2: Rebrand Info.plist" | tee -a "$LOGFILE"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Set :NSHumanReadableCopyright $COPYRIGHT" "$INFO_PLIST" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Add :NSHumanReadableCopyright string $COPYRIGHT" "$INFO_PLIST"
plutil -lint "$INFO_PLIST" >/dev/null
echo "   ✅ CFBundleIdentifier: $(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INFO_PLIST")" | tee -a "$LOGFILE"
echo "   ✅ LSMinimumSystemVersion: $(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$INFO_PLIST")" | tee -a "$LOGFILE"

# ── Step 3: Re-seal ad-hoc ────────────────────────────────────────────────────

echo "" | tee -a "$LOGFILE"
echo "🔏 Step 3: Re-seal (ad-hoc) after plist mutation" | tee -a "$LOGFILE"
codesign --force -s - "$APP_PATH" 2>&1 | tee -a "$LOGFILE"
SIGN_DETAILS="$(codesign -dvvv "$APP_PATH" 2>&1)"
if ! printf '%s\n' "$SIGN_DETAILS" | grep -Fq 'Signature=adhoc'; then
  echo "   ❌ App is not ad-hoc signed after re-seal." | tee -a "$LOGFILE"
  exit 1
fi
echo "   ✅ Signature=adhoc (integrity seal, not a trust signature)" | tee -a "$LOGFILE"

# ── Step 4: Upstream verification gates (x86_64) ──────────────────────────────

echo "" | tee -a "$LOGFILE"
echo "🛡️  Step 4: verify_gatekeeper_bundle ($ARCH, min $DEPLOYMENT_TARGET) + verify_asset_free" | tee -a "$LOGFILE"
( cd "$REPO_DIR" && ./macos/Scripts/verify_gatekeeper_bundle.sh \
    --expected-arch "$ARCH" \
    --expected-min-os "$DEPLOYMENT_TARGET" \
    "$APP_PATH" ) 2>&1 | tee -a "$LOGFILE"
( cd "$REPO_DIR" && ./macos/Scripts/verify_asset_free.sh "$APP_PATH" ) 2>&1 | tee -a "$LOGFILE"
echo "   ✅ Gatekeeper seal + asset-free (no ROM data) verified" | tee -a "$LOGFILE"

# ── Step 5: Version smoke ─────────────────────────────────────────────────────

echo "" | tee -a "$LOGFILE"
echo "🔍 Step 5: Version smoke" | tee -a "$LOGFILE"
EXEC_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$INFO_PLIST")"
REPORTED="$("$APP_PATH/Contents/MacOS/$EXEC_NAME" --version 2>&1)"
if [[ "$REPORTED" != "mdkr64 $APP_VERSION" ]]; then
  echo "   ❌ Binary reports '$REPORTED', expected 'mdkr64 $APP_VERSION'." | tee -a "$LOGFILE"
  exit 1
fi
echo "   ✅ $REPORTED (matches pin $UPSTREAM_TAG)" | tee -a "$LOGFILE"

# ── Summary ───────────────────────────────────────────────────────────────────

echo "" | tee -a "$LOGFILE"
echo "════════════════════════════════════════════════════════════════" | tee -a "$LOGFILE"
echo "✅ gbmt-bundle-macos.sh v$VERSION complete!" | tee -a "$LOGFILE"
echo "   📍 $APP_PATH" | tee -a "$LOGFILE"
echo "   📄 $LOGFILE" | tee -a "$LOGFILE"
echo "   👉 ./gbmt-package-macos.sh" | tee -a "$LOGFILE"
echo "════════════════════════════════════════════════════════════════" | tee -a "$LOGFILE"
