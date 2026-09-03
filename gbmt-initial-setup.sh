#!/bin/zsh
# gbmt-initial-setup.sh
# goldenballoon-mactimber — one-time environment setup for an Intel Mac
#
# Checks Xcode CLT, Homebrew (+ host tools), clones akratch/goldenballoon
# pinned to $UPSTREAM_TAG, and reports readiness. Safe to re-run.
#
# Usage:
#   ./gbmt-initial-setup.sh
#
# CHANGELOG
# v0.10 (2026-09-03) - Initial version

set -eo pipefail
VERSION="0.10"
SCRIPT_DIR="${0:A:h}"

UPSTREAM_REPO="https://github.com/akratch/goldenballoon.git"
UPSTREAM_TAG="v1.5.2"
REPO_DIR="$SCRIPT_DIR/goldenballoon"
TIMESTAMP="$(date '+%Y%m%d-%H%M')"
LOG_DIR="$SCRIPT_DIR/logs"
LOGFILE="$LOG_DIR/setup-$TIMESTAMP.log"
mkdir -p "$LOG_DIR"

echo "🛠️  gbmt-initial-setup.sh v$VERSION — $(date)" | tee -a "$LOGFILE"
echo "   Log: $LOGFILE" | tee -a "$LOGFILE"

# ── Step 1: Architecture sanity ───────────────────────────────────────────────

echo "" | tee -a "$LOGFILE"
echo "🖥️  Step 1: Host check" | tee -a "$LOGFILE"
HOST_ARCH="$(uname -m)"
echo "   Host arch: $HOST_ARCH — $(sysctl -n machdep.cpu.brand_string)" | tee -a "$LOGFILE"
if [[ "$HOST_ARCH" != "x86_64" ]]; then
  echo "   ⚠️  Not an Intel Mac. Building x86_64 by cross-compilation works," | tee -a "$LOGFILE"
  echo "      but v1.0 validation requires real Intel hardware (see README)." | tee -a "$LOGFILE"
fi
if [[ "$(sysctl -in sysctl.proc_translated)" == "1" ]]; then
  echo "   ❌ Running under Rosetta translation — validation results would be" | tee -a "$LOGFILE"
  echo "      meaningless for real Intel hardware. Aborting." | tee -a "$LOGFILE"
  exit 1
fi
echo "   macOS: $(sw_vers -productVersion) ($(sw_vers -buildVersion))" | tee -a "$LOGFILE"

# ── Step 2: Xcode CLT ─────────────────────────────────────────────────────────

echo "" | tee -a "$LOGFILE"
echo "🔧 Step 2: Xcode CLT" | tee -a "$LOGFILE"
if ! xcode-select -p &>/dev/null; then
  echo "   ❌ Xcode Command Line Tools not found." | tee -a "$LOGFILE"
  echo "      Run: xcode-select --install  then re-run this script." | tee -a "$LOGFILE"
  exit 1
fi
echo "   ✅ $(xcode-select -p)" | tee -a "$LOGFILE"
echo "   ✅ $(clang --version | head -1)" | tee -a "$LOGFILE"

# ── Step 3: Homebrew + host tools ─────────────────────────────────────────────

echo "" | tee -a "$LOGFILE"
echo "🍺 Step 3: Homebrew + host tools" | tee -a "$LOGFILE"
if ! command -v brew &>/dev/null; then
  echo "   Installing Homebrew..." | tee -a "$LOGFILE"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>&1 | tee -a "$LOGFILE"
  eval "$(/usr/local/bin/brew shellenv)"
fi
echo "   ✅ $(brew --version | head -1) ($(brew --prefix))" | tee -a "$LOGFILE"
echo "   ⚠️  Intel macOS is Homebrew Tier 3 (since 2026-09): no Intel bottles," | tee -a "$LOGFILE"
echo "      installs may compile from source; brew drops Intel entirely 2027-09." | tee -a "$LOGFILE"
for pkg in cmake pkg-config python3 git; do
  if ! brew list --versions "$pkg" &>/dev/null && ! command -v "$pkg" &>/dev/null; then
    echo "   Installing $pkg..." | tee -a "$LOGFILE"
    brew install "$pkg" 2>&1 | tee -a "$LOGFILE"
  else
    echo "   ✅ $pkg: $(command -v "$pkg" || brew list --versions "$pkg")" | tee -a "$LOGFILE"
  fi
done

# ── Step 4: Clone / pin upstream ──────────────────────────────────────────────

echo "" | tee -a "$LOGFILE"
echo "📥 Step 4: Clone akratch/goldenballoon @ $UPSTREAM_TAG" | tee -a "$LOGFILE"
if [[ ! -f "$REPO_DIR/CMakeLists.txt" ]]; then
  rm -rf "$REPO_DIR"
  git clone --branch "$UPSTREAM_TAG" --depth 1 "$UPSTREAM_REPO" "$REPO_DIR" 2>&1 | tee -a "$LOGFILE"
else
  echo "   ✅ Already cloned ($(git -C "$REPO_DIR" describe --tags --always))" | tee -a "$LOGFILE"
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo "" | tee -a "$LOGFILE"
echo "════════════════════════════════════════════════════════════════" | tee -a "$LOGFILE"
echo "✅ gbmt-initial-setup.sh v$VERSION complete!" | tee -a "$LOGFILE"
echo "   ℹ️  Build needs network access (hash-verified wgpu-native fetch)." | tee -a "$LOGFILE"
echo "   ℹ️  No ROM needed to build; gameplay needs your own US/EU 1.1 dump" | tee -a "$LOGFILE"
echo "      → roms/README.md" | tee -a "$LOGFILE"
echo "   👉 ./gbmt-build-macos.sh" | tee -a "$LOGFILE"
echo "════════════════════════════════════════════════════════════════" | tee -a "$LOGFILE"
