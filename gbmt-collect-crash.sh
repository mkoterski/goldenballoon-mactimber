#!/bin/zsh
# gbmt-collect-crash.sh
# goldenballoon-mactimber — bundle crash reports + logs for a bug report
#
# Collects macOS DiagnosticReports for mdkr64 (last 7 days), the wrapper's
# own logs/, and a fresh systeminfo snapshot into a single zip.
#
# Usage:
#   ./gbmt-collect-crash.sh
#
# Output:
#   logs/gbmt-crash-bundle-<timestamp>.zip
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
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/gbmt-crash.XXXXXX")"
ZIP="$LOG_DIR/gbmt-crash-bundle-$TIMESTAMP.zip"
mkdir -p "$LOG_DIR"
trap 'rm -rf "$STAGE"' EXIT

echo "🧰 gbmt-collect-crash.sh v$VERSION — $(date)"

echo "🔍 Collecting DiagnosticReports (mdkr64, last 7 days)..."
mkdir -p "$STAGE/DiagnosticReports"
found=0
for dir in "$HOME/Library/Logs/DiagnosticReports" "/Library/Logs/DiagnosticReports"; do
  [[ -d "$dir" ]] || continue
  while IFS= read -r -d '' f; do
    cp "$f" "$STAGE/DiagnosticReports/" && (( found+=1 ))
  done < <(find "$dir" -maxdepth 1 \( -name 'mdkr64*' \) -mtime -7 -print0 2>/dev/null)
done
echo "   $found report(s) found"

echo "📄 Collecting wrapper logs..."
mkdir -p "$STAGE/logs"
setopt null_glob
wrapper_logs=("$LOG_DIR"/*.log)
(( ${#wrapper_logs} > 0 )) && cp "${wrapper_logs[@]}" "$STAGE/logs/"
unsetopt null_glob

echo "🖥️  Fresh systeminfo snapshot..."
"$SCRIPT_DIR/gbmt-systeminfo.sh" >/dev/null 2>&1 || true
setopt null_glob
sysinfo=("$LOG_DIR"/systeminfo-*.log(Om))
(( ${#sysinfo} > 0 )) && cp "${sysinfo[-1]}" "$STAGE/"
unsetopt null_glob

( cd "$STAGE" && zip -qr "$ZIP" . )
echo ""
echo "✅ Crash bundle: $ZIP ($(du -h "$ZIP" | cut -f1))"
echo "   ⚠️  Review before sharing — logs may contain local paths/usernames."
echo "   ROMs are never collected."
