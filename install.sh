#!/bin/sh
# Install the Teletype Games store on a Batocera box.
#
#   curl -fsSL https://git.teletypegames.org/stores/ttg-batocera-store/raw/branch/master/install.sh | sh
#
# All the work is done by the shared engine; this script only says which store
# to install. See https://git.teletypegames.org/stores/warp-engine-batocera-store
#
set -eu

FORGE="${FORGE:-https://git.teletypegames.org/stores}"
# The engine and its shared core are pinned to the commits this config was tested
# with, so a push to either master cannot change what a fresh install gets. To
# move on, bump both refs here together; `ENGINE_REF=branch/master
# WARPSTORE_REF=branch/master` tries the current heads.
ENGINE_REF="${ENGINE_REF:-commit/8ffe70d8d0eea50ccc1a56ea54665089fbf58761}"
WARPSTORE_REF="${WARPSTORE_REF:-commit/168624695532a8db0977e0dd295890afc08cccc9}"
ENGINE_RAW_BASE="${ENGINE_RAW_BASE:-$FORGE/warp-engine-batocera-store/raw/$ENGINE_REF}"
WARPSTORE_RAW_BASE="${WARPSTORE_RAW_BASE:-https://git.teletypegames.org/engines/warpstore/raw/$WARPSTORE_REF}"
# Only set when run as a file; piped from curl "$0" is `sh` and everything
# has to come from the forge — never from whatever the cwd happens to hold.
SRC_DIR=""
if [ -f "$0" ]; then
  SRC_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")" && pwd)"
fi

# Prefer the config next to this script when run from a checkout.
if [ -z "${STORE_CONFIG:-}" ] && [ -n "$SRC_DIR" ] && [ -f "$SRC_DIR/config.json" ]; then
  STORE_CONFIG="$SRC_DIR/config.json"
else
  STORE_CONFIG="${STORE_CONFIG:-$FORGE/ttg-batocera-store/raw/branch/master/config.json}"
fi
export STORE_CONFIG ENGINE_RAW_BASE WARPSTORE_RAW_BASE

# No Ports entry any more: the store has its own EmulationStation menu entry,
# with the updater inside it. The engine takes the old Ports entry away on the
# first sync after the upgrade.

# --- migrate the pre-split ttg-store layout -------------------------------
# Up to engine 1.x everything lived in /userdata/system/ttg-store. Carrying
# state.json across is what lets the engine recognise what is installed — from
# engine 4.0 on it uses that to take the old layout off the box before filling
# /userdata/roms/teletypegames, the store's own folder.
LEGACY_HOME="${LEGACY_STORE_HOME:-/userdata/system/ttg-store}"
NEW_HOME="${BATOCERA_STORE_ROOT:-/userdata/system/batocera-store}/ttg"
PORTS_DIR="${BATOCERA_PORTS_DIR:-/userdata/roms/ports}"

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

  # The 1.x Ports entry names the old home, and the engine finds its Ports
  # entries by looking for the new one in them — so it would never see this one,
  # and a dead entry would stay in Ports. Pointing it at the new home is enough:
  # the first sync recognises it as ours and removes it with its gamelist node.
  if [ -d "$PORTS_DIR" ]; then
    for entry in "$PORTS_DIR"/*.sh; do
      [ -f "$entry" ] || continue
      if grep -q -F "$LEGACY_HOME" "$entry" 2>/dev/null; then
        sed "s|$LEGACY_HOME|$NEW_HOME|g" "$entry" > "$entry.tmp"
        cat "$entry.tmp" > "$entry"
        rm -f "$entry.tmp"
        echo "[install] old Ports entry $entry handed to the engine for removal"
      fi
    done
  fi
fi

# Fetched to a file rather than piped into a shell: a failed download must fail
# loudly instead of feeding an empty script to sh, which would look like success.
# The file sits alone in its own directory, because the engine installs any
# store.py or warpstore.py it finds next to itself.
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
curl -fsSL --retry 3 --connect-timeout 15 "$ENGINE_RAW_BASE/install.sh" -o "$TMP_DIR/install.sh"
sh "$TMP_DIR/install.sh"
