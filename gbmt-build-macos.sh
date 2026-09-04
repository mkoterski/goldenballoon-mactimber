#!/bin/zsh
# gbmt-build-macos.sh
# goldenballoon-mactimber — Intel Mac (x86_64) build script
#
# Clones akratch/goldenballoon pinned to $UPSTREAM_TAG, builds the pinned
# standalone SDL2 dylib for x86_64, then drives upstream's own
# macos/Scripts/build_app_bundle.sh with --arch x86_64 to compile the engine
# and assemble an ad-hoc-signed mdkr64.app. Unlike the sibling ports
# (perfectdark-macvanta etc.), upstream ships a complete macOS packaging
# pipeline, so this wrapper pins, orchestrates, and validates instead of
# reimplementing.
#
# Requires network access at configure time: upstream fetches the SHA-256
# pinned wgpu-native prebuilt (wgpu-macos-x86_64-release.zip) via CMake
# FetchContent.
#
# Usage:
#   ./gbmt-build-macos.sh [--clean] [--verbose]
#     --clean     wipe upstream build dirs, SDL2 dep build, and dist/ first
#     --verbose   trace every command (set -x)
#
# No ROM is needed to build: Golden Balloon reads the ROM at runtime
# (bring your own ROM — see roms/README.md).
#
# Log output:
#   logs/build-<timestamp>.log   ← top-level logs/, survives rm -rf goldenballoon/
#
# CHANGELOG
# v1.0  (2026-09-04) - Promoted unchanged after confirmed end-to-end validation
#                      on Intel hardware (see CHANGELOG.md)
# v0.10 (2026-09-03) - Initial version; series conventions from
#                      smca-build-macos.sh v0.10 / pdmv-build-macos.sh v0.17,
#                      build itself delegated to upstream macos/Scripts
#                      (see RESEARCH.md §5a)

set -eo pipefail
VERSION="1.0"
SCRIPT_DIR="${0:A:h}"

UPSTREAM_REPO="https://github.com/akratch/goldenballoon.git"
UPSTREAM_TAG="v1.5.2"            # bump deliberately; keep in sync with README/CHANGELOG
APP_VERSION="${UPSTREAM_TAG#v}"  # must match the version compiled into mdkr64
ARCH="x86_64"
DEPLOYMENT_TARGET="14.0"         # sign-off decision: Sonoma floor (RESEARCH.md §5a)

REPO_DIR="$SCRIPT_DIR/goldenballoon"
BUILD_DIR_NAME="build-macos-release"
APP_PATH="$REPO_DIR/dist/mdkr64.app"
TIMESTAMP="$(date '+%Y%m%d-%H%M')"

LOG_DIR="$SCRIPT_DIR/logs"
LOGFILE="$LOG_DIR/build-$TIMESTAMP.log"
mkdir -p "$LOG_DIR"

CLEAN=0
for arg in "$@"; do
  case "$arg" in
    --clean)   CLEAN=1 ;;
    --verbose) set -x ;;
    *) echo "Unknown flag: $arg (supported: --clean --verbose)"; exit 2 ;;
  esac
done

echo "🔨 gbmt-build-macos.sh v$VERSION — $(date)" | tee -a "$LOGFILE"
echo "   Upstream pin: $UPSTREAM_TAG   arch: $ARCH   min macOS: $DEPLOYMENT_TARGET" | tee -a "$LOGFILE"
echo "   Log: $LOGFILE" | tee -a "$LOGFILE"

# ── Step 1: Xcode CLT ─────────────────────────────────────────────────────────

echo "" | tee -a "$LOGFILE"
echo "🔧 Step 1: Xcode CLT" | tee -a "$LOGFILE"
if ! xcode-select -p &>/dev/null; then
  echo "   ❌ Xcode Command Line Tools not found." | tee -a "$LOGFILE"
  echo "      Run: xcode-select --install  then re-run this script." | tee -a "$LOGFILE"
  exit 1
fi
echo "   ✅ $(xcode-select -p)" | tee -a "$LOGFILE"

# ── Step 2: Host tools ────────────────────────────────────────────────────────

# Homebrew on Intel is Tier 3 since 2026-09 (no new Intel bottles; removal
# 2027-09). Only host-side tools come from brew — the app's runtime deps
# (SDL2, wgpu-native) are built/fetched by upstream's pinned pipeline.

echo "" | tee -a "$LOGFILE"
echo "🍺 Step 2: Host tools (Homebrew)" | tee -a "$LOGFILE"
if ! command -v brew &>/dev/null; then
  echo "   Installing Homebrew..." | tee -a "$LOGFILE"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>&1 | tee -a "$LOGFILE"
  eval "$(/usr/local/bin/brew shellenv)"
fi
echo "   ✅ $(brew --version | head -1) ($(brew --prefix))" | tee -a "$LOGFILE"
echo "   ⚠️  Intel macOS is Homebrew Tier 3 — installs may build from source." | tee -a "$LOGFILE"
for pkg in cmake pkg-config python3 git; do
  if ! brew list --versions "$pkg" &>/dev/null && ! command -v "$pkg" &>/dev/null; then
    echo "   Installing $pkg..." | tee -a "$LOGFILE"
    brew install "$pkg" 2>&1 | tee -a "$LOGFILE"
  else
    echo "   ✅ $pkg: $(command -v "$pkg")" | tee -a "$LOGFILE"
  fi
done

# ── Step 3: Clone / pin upstream ──────────────────────────────────────────────

echo "" | tee -a "$LOGFILE"
echo "📥 Step 3: Clone akratch/goldenballoon @ $UPSTREAM_TAG" | tee -a "$LOGFILE"
if [[ ! -f "$REPO_DIR/CMakeLists.txt" ]]; then
  [[ -d "$REPO_DIR" ]] && echo "   ⚠️  Repo dir exists but CMakeLists.txt missing — removing and re-cloning..." | tee -a "$LOGFILE"
  rm -rf "$REPO_DIR"
  git clone --branch "$UPSTREAM_TAG" --depth 1 "$UPSTREAM_REPO" "$REPO_DIR" 2>&1 | tee -a "$LOGFILE"
else
  CURRENT="$(git -C "$REPO_DIR" describe --tags --exact-match 2>/dev/null || echo none)"
  if [[ "$CURRENT" != "$UPSTREAM_TAG" ]]; then
    echo "   Repo at '$CURRENT' — switching to $UPSTREAM_TAG..." | tee -a "$LOGFILE"
    git -C "$REPO_DIR" fetch --depth 1 origin tag "$UPSTREAM_TAG" 2>&1 | tee -a "$LOGFILE"
    git -C "$REPO_DIR" checkout --detach "$UPSTREAM_TAG" 2>&1 | tee -a "$LOGFILE"
  else
    echo "   ✅ Already pinned at $UPSTREAM_TAG" | tee -a "$LOGFILE"
  fi
fi

# Upstream's release pipeline stamps provenance with HEAD, so the tree must be
# clean — a dirty tree would make the stamped commit dishonest.
if [[ -n "$(git -C "$REPO_DIR" status --porcelain=v1 --untracked-files=all)" ]]; then
  echo "   ❌ Upstream tree is dirty. Reset it or delete goldenballoon/ and re-run:" | tee -a "$LOGFILE"
  echo "      git -C \"$REPO_DIR\" checkout -- . && git -C \"$REPO_DIR\" clean -fd" | tee -a "$LOGFILE"
  exit 1
fi
SOURCE_COMMIT="$(git -C "$REPO_DIR" rev-parse HEAD)"
echo "   ✅ Pinned commit: $SOURCE_COMMIT" | tee -a "$LOGFILE"

# ── Step 4: Clean (optional) ──────────────────────────────────────────────────

if (( CLEAN )); then
  echo "" | tee -a "$LOGFILE"
  echo "🧹 Step 4: --clean — wiping build artifacts" | tee -a "$LOGFILE"
  rm -rf "$REPO_DIR/$BUILD_DIR_NAME" "$REPO_DIR/build-macos-deps" "$REPO_DIR/dist" "$SCRIPT_DIR/dist"
  echo "   ✅ Wiped $BUILD_DIR_NAME/, build-macos-deps/, dist/" | tee -a "$LOGFILE"
fi

# ── Step 5: Pinned SDL2 (x86_64) ──────────────────────────────────────────────

# Upstream refuses Homebrew's sdl2-compat shim and instead builds the pinned
# SDL2 release from authenticated source — which also gives us the x86_64
# slice Homebrew no longer bottles.

echo "" | tee -a "$LOGFILE"
echo "📦 Step 5: Pinned standalone SDL2 ($ARCH)" | tee -a "$LOGFILE"
SDL_VER="$(bash -c "source '$REPO_DIR/macos/Scripts/release_sdl2_config.sh' && printf %s \"\$MDKR_RELEASE_SDL2_VERSION\"")"
[[ -n "$SDL_VER" ]] || { echo "   ❌ Could not read MDKR_RELEASE_SDL2_VERSION" | tee -a "$LOGFILE"; exit 1; }
SDL_WORK="$REPO_DIR/build-macos-deps/sdl2-$SDL_VER"
SDL_PREFIX="$SDL_WORK/install"
if [[ -f "$SDL_PREFIX/lib/libSDL2-2.0.0.dylib" ]]; then
  echo "   ✅ SDL2 $SDL_VER already built at $SDL_PREFIX" | tee -a "$LOGFILE"
else
  ( cd "$REPO_DIR" && ./macos/Scripts/build_release_sdl2.sh \
      --work-dir "$SDL_WORK" \
      --prefix "$SDL_PREFIX" \
      --arch "$ARCH" \
      --deployment-target "$DEPLOYMENT_TARGET" ) 2>&1 | tee -a "$LOGFILE"
fi
SDL_ARCHS="$(lipo -archs "$SDL_PREFIX/lib/libSDL2-2.0.0.dylib")"
if [[ "$SDL_ARCHS" != "$ARCH" ]]; then
  echo "   ❌ SDL2 dylib arch is '$SDL_ARCHS', expected exactly '$ARCH' — refusing to continue." | tee -a "$LOGFILE"
  exit 1
fi
echo "   ✅ SDL2 $SDL_VER — arch: $SDL_ARCHS" | tee -a "$LOGFILE"

# ── Step 6: Build + bundle via upstream (x86_64) ──────────────────────────────

echo "" | tee -a "$LOGFILE"
echo "🔨 Step 6: upstream build_app_bundle.sh --arch $ARCH ($(sysctl -n hw.logicalcpu) cores)" | tee -a "$LOGFILE"
echo "   (network required: wgpu-native prebuilt is fetched + hash-verified)" | tee -a "$LOGFILE"
( cd "$REPO_DIR" && PKG_CONFIG_PATH="$SDL_PREFIX/lib/pkgconfig" \
  ./macos/Scripts/build_app_bundle.sh \
    --release \
    --build-dir "$BUILD_DIR_NAME" \
    --output dist/mdkr64.app \
    --arch "$ARCH" \
    --version "$APP_VERSION" \
    --build-stamp "$SOURCE_COMMIT" \
    --deployment-target "$DEPLOYMENT_TARGET" \
    --strict-deployment-target \
    --bundle-sdl2 ) 2>&1 | tee -a "$LOGFILE"

# ── Step 7: Validate binary (fail loudly on any non-x86_64 slice) ─────────────

echo "" | tee -a "$LOGFILE"
echo "🔍 Step 7: Validate binary" | tee -a "$LOGFILE"
INFO_PLIST="$APP_PATH/Contents/Info.plist"
EXEC_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$INFO_PLIST")"
ENGINE="$APP_PATH/Contents/MacOS/$EXEC_NAME"
if [[ ! -x "$ENGINE" ]]; then
  echo "   ❌ Executable not found at: $ENGINE" | tee -a "$LOGFILE"
  echo "   Check log: $LOGFILE" | tee -a "$LOGFILE"
  exit 1
fi
BIN_ARCHS="$(lipo -archs "$ENGINE")"
if [[ "$BIN_ARCHS" != "$ARCH" ]]; then
  echo "   ❌ Binary arch is '$BIN_ARCHS', expected exactly '$ARCH'." | tee -a "$LOGFILE"
  echo "      Never ship a silent arm64/universal fallback from this repo." | tee -a "$LOGFILE"
  exit 1
fi
echo "   ✅ Binary: $(file "$ENGINE" | grep -o 'Mach-O.*')" | tee -a "$LOGFILE"
echo "   ✅ Arch:   $BIN_ARCHS" | tee -a "$LOGFILE"
echo "   ✅ Size:   $(du -h "$ENGINE" | cut -f1)" | tee -a "$LOGFILE"
echo "   ✅ Ver:    $("$ENGINE" --version 2>&1)" | tee -a "$LOGFILE"

# ── Summary ───────────────────────────────────────────────────────────────────

echo "" | tee -a "$LOGFILE"
echo "════════════════════════════════════════════════════════════════" | tee -a "$LOGFILE"
echo "✅ gbmt-build-macos.sh v$VERSION complete!" | tee -a "$LOGFILE"
echo "   📍 $APP_PATH" | tee -a "$LOGFILE"
echo "   📄 $LOGFILE" | tee -a "$LOGFILE"
echo "   👉 ./gbmt-bundle-macos.sh" | tee -a "$LOGFILE"
echo "════════════════════════════════════════════════════════════════" | tee -a "$LOGFILE"
