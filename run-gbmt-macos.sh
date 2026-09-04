#!/bin/zsh
# run-gbmt-macos.sh
# goldenballoon-mactimber — local dev launcher
#
# Launches the built "Golden Balloon.app" engine directly (stdout captured to logs/).
# If a ROM is present in roms/, it is passed via --rom; otherwise the
# launcher's own file picker asks for one. The ROM is validated by the game
# at runtime (US 1.1 / EU 1.1 only) and is never copied anywhere.
#
# Usage:
#   ./run-gbmt-macos.sh [--gl] [-- <extra engine args>]
#     --gl    force the OpenGL diagnostic renderer (MDKR_RENDERER=gl);
#             WebGPU/Metal is the qualified default — use --gl only to
#             isolate renderer issues on Intel GPUs
#
# Log output:
#   logs/run-<timestamp>.log   (last 5 kept)
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

REPO_DIR="$SCRIPT_DIR/goldenballoon"
APP_PATH="$REPO_DIR/dist/Golden Balloon.app"
ROM_DIR="$SCRIPT_DIR/roms"
TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
LOG_DIR="$SCRIPT_DIR/logs"
LOGFILE="$LOG_DIR/run-$TIMESTAMP.log"
LOG_KEEP=5
mkdir -p "$LOG_DIR"

log() { echo "[info] $(date '+%H:%M:%S') $*" | tee -a "$LOGFILE"; }

# Rotate run logs, keep the newest $LOG_KEEP
setopt null_glob
run_logs=("$LOG_DIR"/run-*.log(Om))
if (( ${#run_logs} > LOG_KEEP )); then
  rm -f "${run_logs[@]:0:$(( ${#run_logs} - LOG_KEEP ))}"
fi
unsetopt null_glob

echo "🎈 run-gbmt-macos.sh v$VERSION — $(date)" | tee -a "$LOGFILE"

if [[ ! -d "$APP_PATH" ]]; then
  log "❌ App not found: $APP_PATH — run ./gbmt-build-macos.sh first."
  exit 1
fi
EXEC_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP_PATH/Contents/Info.plist")"
ENGINE="$APP_PATH/Contents/MacOS/$EXEC_NAME"

ENGINE_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --gl) export MDKR_RENDERER=gl; log "⚠️  OpenGL diagnostic renderer forced (WebGPU is the qualified path)"; shift ;;
    --)   shift; ENGINE_ARGS+=("$@"); break ;;
    *)    ENGINE_ARGS+=("$1"); shift ;;
  esac
done

# ROM: first match in roms/ wins; otherwise the in-app launcher asks.
setopt null_glob
roms=("$ROM_DIR"/*.z64 "$ROM_DIR"/*.v64 "$ROM_DIR"/*.n64)
unsetopt null_glob
if (( ${#roms} > 0 )); then
  log "🎮 ROM: ${roms[1]}"
  ENGINE_ARGS=(--rom "${roms[1]}" "${ENGINE_ARGS[@]}")
else
  log "🎮 No ROM in roms/ — the launcher will ask (see roms/README.md)"
fi

log "🚀 Launching: $ENGINE ${ENGINE_ARGS[*]}"
log "   Renderer: ${MDKR_RENDERER:-webgpu (default)}"
STATUS=0
"$ENGINE" "${ENGINE_ARGS[@]}" 2>&1 | tee -a "$LOGFILE" || STATUS=$?
log "🏁 Engine exited with status $STATUS"
if (( STATUS != 0 )); then
  log "👉 Collect diagnostics with ./gbmt-collect-crash.sh"
fi
exit $STATUS
