#!/bin/zsh
# gbmt-systeminfo.sh
# goldenballoon-mactimber — collect host system info for bug reports
#
# Usage:
#   ./gbmt-systeminfo.sh
#
# Log output:
#   logs/systeminfo-<timestamp>.log
#
# CHANGELOG
# v1.0  (2026-09-04) - Promoted unchanged after confirmed end-to-end validation
#                      on Intel hardware (see CHANGELOG.md)
# v0.10 (2026-09-03) - Initial version

set -eo pipefail
VERSION="1.0"
SCRIPT_DIR="${0:A:h}"
TIMESTAMP="$(date '+%Y%m%d-%H%M')"
LOG_DIR="$SCRIPT_DIR/logs"
LOGFILE="$LOG_DIR/systeminfo-$TIMESTAMP.log"
mkdir -p "$LOG_DIR"

out() { echo "$@" | tee -a "$LOGFILE"; }

out "🖥️  gbmt-systeminfo.sh v$VERSION — $(date)"
out ""
out "═══ macOS ═══"
sw_vers | tee -a "$LOGFILE"
out ""
out "═══ Hardware ═══"
out "Arch:  $(uname -m)"
out "CPU:   $(sysctl -n machdep.cpu.brand_string)"
out "Cores: $(sysctl -n hw.logicalcpu) logical"
out "RAM:   $(( $(sysctl -n hw.memsize) / 1073741824 )) GB"
out "Rosetta: $(sysctl -in sysctl.proc_translated | sed 's/^0$/native/;s/^1$/TRANSLATED/;s/^$/native (no key)/')"
out ""
out "═══ GPU (relevant: WebGPU→Metal on Intel-era GPUs) ═══"
system_profiler SPDisplaysDataType 2>/dev/null | grep -E 'Chipset Model|VRAM|Metal' | sed 's/^ *//' | tee -a "$LOGFILE"
out ""
out "═══ Toolchain ═══"
out "CLT:    $(xcode-select -p 2>/dev/null || echo 'not installed')"
out "clang:  $(clang --version 2>/dev/null | head -1 || echo 'not found')"
out "SDK:    $(xcrun --show-sdk-version 2>/dev/null || echo 'n/a')"
out "cmake:  $(cmake --version 2>/dev/null | head -1 || echo 'not installed')"
out "git:    $(git --version 2>/dev/null || echo 'not installed')"
out "python: $(python3 --version 2>/dev/null || echo 'not installed')"
out "brew:   $(brew --version 2>/dev/null | head -1 || echo 'not installed') ($(brew --prefix 2>/dev/null))"
out ""
out "═══ Wrapper / upstream state ═══"
if [[ -d "$SCRIPT_DIR/goldenballoon/.git" ]]; then
  out "upstream pin: $(git -C "$SCRIPT_DIR/goldenballoon" describe --tags --always) @ $(git -C "$SCRIPT_DIR/goldenballoon" rev-parse --short HEAD)"
else
  out "upstream: not cloned yet"
fi
APP="$SCRIPT_DIR/goldenballoon/dist/mdkr64.app"
if [[ -d "$APP" ]]; then
  ENGINE="$APP/Contents/MacOS/$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP/Contents/Info.plist")"
  out "app:  $(file "$ENGINE" | grep -o 'Mach-O.*')"
  out "ver:  $("$ENGINE" --version 2>&1)"
  out "id:   $(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist")"
else
  out "app:  not built yet"
fi
out ""
out "📄 Saved to: $LOGFILE"
