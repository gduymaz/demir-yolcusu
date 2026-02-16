#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

DEFAULT_GODOT_BIN="/Users/splendour/Downloads/Godot.app/Contents/MacOS/Godot"

find_godot_bin() {
  if [[ -n "${GODOT_BIN:-}" && -x "${GODOT_BIN}" ]]; then
    echo "$GODOT_BIN"
    return
  fi

  if [[ -x "$DEFAULT_GODOT_BIN" ]]; then
    echo "$DEFAULT_GODOT_BIN"
    return
  fi

  local candidates=(
    "/Applications/Godot.app/Contents/MacOS/Godot"
    "$HOME/Applications/Godot.app/Contents/MacOS/Godot"
    "$(command -v godot 2>/dev/null || true)"
  )

  local path
  for path in "${candidates[@]}"; do
    if [[ -n "$path" && -x "$path" ]]; then
      echo "$path"
      return
    fi
  done

  echo ""
}

usage() {
  cat <<USAGE
Usage: ./run.sh [mode]

Modes:
  play      Run game normally (default)
  debug     Run game with debug output + file logging enabled
  headless  Run headless smoke check and quit
USAGE
}

MODE="${1:-play}"
GODOT_BIN_RESOLVED="$(find_godot_bin)"

if [[ -z "$GODOT_BIN_RESOLVED" ]]; then
  echo "Godot binary not found."
  echo "Set GODOT_BIN or install Godot to one of these locations:"
  echo "  - /Users/splendour/Downloads/Godot.app/Contents/MacOS/Godot"
  echo "  - /Applications/Godot.app/Contents/MacOS/Godot"
  exit 1
fi

echo "Using Godot: $GODOT_BIN_RESOLVED"

case "$MODE" in
  play)
    exec "$GODOT_BIN_RESOLVED" --path "$ROOT_DIR"
    ;;
  debug)
    export DEMIR_DEBUG_LOG=1
    export DEMIR_DEBUG_STDOUT="${DEMIR_DEBUG_STDOUT:-0}"
    export DEMIR_DEBUG_LOG_DIR="${DEMIR_DEBUG_LOG_DIR:-$ROOT_DIR/logs}"
    mkdir -p "$DEMIR_DEBUG_LOG_DIR"
    ts="$(date +\"%Y-%m-%d_%H-%M-%S\")"
    log_file="${DEMIR_DEBUG_LOG_DIR}/debug-log-${ts}.log"
    export DEMIR_DEBUG_LOG_PATH="$log_file"
    echo "Debug logging enabled: $log_file"
    # Godot stdout/stderr and in-game DebugLogger output are collected in the same file.
    "$GODOT_BIN_RESOLVED" --path "$ROOT_DIR" --verbose 2>&1 | tee -a "$log_file"
    exit ${PIPESTATUS[0]}
    ;;
  headless)
    exec "$GODOT_BIN_RESOLVED" --headless --path "$ROOT_DIR" --quit
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    echo "Unknown mode: $MODE"
    usage
    exit 1
    ;;
esac
