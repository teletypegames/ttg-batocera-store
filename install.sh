#!/bin/bash
# Install the Teletype Games store on a Batocera box.
#
#   curl -fsSL https://git.teletypegames.org/tools/ttg-batocera-store/raw/branch/master/install.sh | bash
#
# All the work is done by the shared engine; this script only says which store
# to install. See https://git.teletypegames.org/tools/warp-engine-batocera-store
#
set -euo pipefail

FORGE="${FORGE:-https://git.teletypegames.org}"
ENGINE_RAW_BASE="${ENGINE_RAW_BASE:-$FORGE/tools/warp-engine-batocera-store/raw/branch/master}"
# Only set when run as a file; piped from curl "$0" is `bash` and everything
# has to come from the forge — never from whatever the cwd happens to hold.
SRC_DIR=""
if [ -f "$0" ]; then
  SRC_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
fi

# Prefer the config next to this script when run from a checkout.
if [ -z "${STORE_CONFIG:-}" ] && [ -n "$SRC_DIR" ] && [ -f "$SRC_DIR/config.json" ]; then
  STORE_CONFIG="$SRC_DIR/config.json"
else
  STORE_CONFIG="${STORE_CONFIG:-$FORGE/tools/ttg-batocera-store/raw/branch/master/config.json}"
fi
export STORE_CONFIG ENGINE_RAW_BASE

# Keep the Ports entry the box already has, so an upgrade replaces it in place.
export BATOCERA_PORT_NAME="${BATOCERA_PORT_NAME:-Teletype Games Store}"

# --- migrate the pre-split ttg-store layout -------------------------------
# Up to engine 1.x everything lived in /userdata/system/ttg-store. The ROMs
# themselves do not move (the subfolder is still `teletypegames`), so carrying
# state.json across is enough to avoid a full re-download.
LEGACY_HOME="${LEGACY_STORE_HOME:-/userdata/system/ttg-store}"
NEW_HOME="${BATOCERA_STORE_ROOT:-/userdata/system/batocera-store}/ttg"

if [ -d "$LEGACY_HOME" ] && [ ! -f "$NEW_HOME/state.json" ]; then
  echo "[install] migrating $LEGACY_HOME -> $NEW_HOME"
  mkdir -p "$NEW_HOME"
  if [ -f "$LEGACY_HOME/state.json" ]; then
    cp "$LEGACY_HOME/state.json" "$NEW_HOME/state.json"
  fi
  if [ -f "$LEGACY_HOME/ttg-store.log" ]; then
    cp "$LEGACY_HOME/ttg-store.log" "$NEW_HOME/store.log"
  fi
  rm -rf "$LEGACY_HOME.pre-split"
  mv "$LEGACY_HOME" "$LEGACY_HOME.pre-split"
  echo "[install] old install kept at $LEGACY_HOME.pre-split — delete it once things look right"
fi

curl -fsSL "$ENGINE_RAW_BASE/install.sh" | bash
