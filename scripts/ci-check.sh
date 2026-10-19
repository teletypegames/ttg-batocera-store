#!/bin/sh
# Checks config.json against the engine install.sh pins: the engine has to load
# it, and every key in it has to be one the engine knows — a key the engine does
# not read is silently ignored, which is how a missing or misspelt setting hides.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
eval "$(grep -E '^(ENGINE|WARPSTORE)_REF=' "$ROOT/install.sh")"
FORGE=https://git.teletypegames.org
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

curl -fsSL --retry 3 "$FORGE/stores/warp-engine-batocera-store/raw/$ENGINE_REF/store.py" -o "$WORK/store.py"
curl -fsSL --retry 3 "$FORGE/engines/warpstore/raw/$WARPSTORE_REF/warpstore.py" -o "$WORK/warpstore.py"
cp "$ROOT/config.json" "$WORK/config.json"

echo "==> engine at $ENGINE_REF, warpstore at $WARPSTORE_REF"
BATOCERA_STORE_HOME="$WORK" python3 "$WORK/store.py" --config "$WORK/config.json" \
  --roms-root "$WORK/roms" config >/dev/null

echo "==> config keys"
python3 - "$WORK" <<'PY'
import json, sys
sys.path.insert(0, sys.argv[1])
import store

user = json.load(open(f"{sys.argv[1]}/config.json"))
unknown = []

def walk(have, known, path):
    for key, value in have.items():
        where = f"{path}.{key}" if path else key
        if key not in known:
            unknown.append(where)
        elif isinstance(value, dict) and isinstance(known[key], dict) and where != "platforms" \
                and where != "emulationstation.menu.labels":
            walk(value, known[key], where)

walk(user, store.DEFAULT_CONFIG, "")
spec_keys = {"system", "install", "kind", "ext", "enabled"}
for name, spec in (user.get("platforms") or {}).items():
    unknown += [f"platforms.{name}.{k}" for k in spec if k not in spec_keys]
if unknown:
    sys.exit("unknown config keys: " + ", ".join(unknown))
print("all keys known to the engine")
PY

echo "==> logos"
python3 - "$ROOT/config.json" <<'PY'
import json, sys, urllib.request
for url in json.load(open(sys.argv[1]))["emulationstation"]["menu"]["logo"]:
    with urllib.request.urlopen(urllib.request.Request(url, method="HEAD"), timeout=30) as r:
        print(r.status, url)
PY
