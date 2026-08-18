#!/bin/sh
# Remove the Teletype Games store from this Batocera box.
#
#   curl -fsSL https://git.teletypegames.org/stores/ttg-batocera-store/raw/branch/master/uninstall.sh | sh
#
# All the work is done by the engine's uninstaller; this only says which store.
# DRY_RUN=1 to see what would go, KEEP_HOME=1 to keep the state and the log.
set -eu
FORGE="${FORGE:-https://git.teletypegames.org/stores}"
ENGINE_RAW_BASE="${ENGINE_RAW_BASE:-$FORGE/warp-engine-batocera-store/raw/branch/master}"
STORE_ID="${STORE_ID:-ttg}"
export STORE_ID

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
curl -fsSL "$ENGINE_RAW_BASE/uninstall.sh" -o "$TMP"
sh "$TMP"
