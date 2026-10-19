#!/bin/sh
# Remove the Teletype Games store from this Batocera box.
#
#   curl -fsSL https://git.teletypegames.org/stores/ttg-batocera-store/raw/branch/master/uninstall.sh | sh
#
# All the work is done by the engine's uninstaller; this only says which store.
# DRY_RUN=1 to see what would go, KEEP_HOME=1 to keep the state and the log.
set -eu
FORGE="${FORGE:-https://git.teletypegames.org/stores}"
# The same engine commit install.sh pins.
ENGINE_REF="${ENGINE_REF:-commit/8ffe70d8d0eea50ccc1a56ea54665089fbf58761}"
ENGINE_RAW_BASE="${ENGINE_RAW_BASE:-$FORGE/warp-engine-batocera-store/raw/$ENGINE_REF}"
STORE_ID="${STORE_ID:-ttg}"
export STORE_ID

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
curl -fsSL --retry 3 --connect-timeout 15 "$ENGINE_RAW_BASE/uninstall.sh" -o "$TMP_DIR/uninstall.sh"
sh "$TMP_DIR/uninstall.sh"
