# ttg-batocera-store — the Teletype Games store for Batocera

Puts the <https://teletypegames.org> catalog into a Batocera box's ROM folders,
with EmulationStation metadata and box art. Triggered from the **Ports** menu on
the device, or from the CLI over SSH.

This repository is only the store definition — `config.json` plus the two wrapper
scripts. All the logic lives in the shared engine,
[`warp-engine-batocera-store`](https://git.teletypegames.org/stores/warp-engine-batocera-store),
which works with any WarpEngine-based site; this is just the Teletype Games
configuration of it.

For RetroArch rather than a Batocera box — desktop, Android, Steam Deck — the
same catalog is served by
[`ttg-retroarch-store`](https://git.teletypegames.org/stores/ttg-retroarch-store).

## Install

Straight onto the device:

```sh
curl -fsSL https://git.teletypegames.org/stores/ttg-batocera-store/raw/branch/master/install.sh | sh
```

Or from a checkout of this repo:

```sh
scp -r ttg-batocera-store root@batocera:/tmp/
ssh root@batocera /tmp/ttg-batocera-store/install.sh
```

The installer fetches the engine, drops it and this config in
`/userdata/system/batocera-store/ttg/`, writes the `ttg-store` launcher and the
*Teletype Games Store* Ports entry, and runs the first sync. Restart
EmulationStation (`batocera-es-swissknife --restart`) to see the games.

## Use

**On the device.** *Ports ▸ Teletype Games Store*. It downloads anything new,
then restarts EmulationStation. Ports scripts get no console in Batocera, so the
output goes to `/userdata/system/batocera-store/ttg/store.log`.

**Over SSH.**

```sh
S=/userdata/system/batocera-store/ttg-store

$S list                 # compatible catalog entries; * installed, ^ update available
$S sync                 # download everything new, refresh gamelists
$S sync blessingofra    # just one title (never prunes)
$S -n sync              # dry run
$S remove c64demo       # uninstall
$S config               # effective configuration
```

Global flags go before the subcommand: `$S --roms-root /tmp/roms sync`.

## Uninstall

```sh
curl -fsSL https://git.teletypegames.org/stores/ttg-batocera-store/raw/branch/master/uninstall.sh | sh
```

Or `/tmp/ttg-batocera-store/uninstall.sh` from a checkout on the box. It takes
out the games — including any unpacked Ports payload — our gamelist entries, the
*Teletype Games* Ports entry, the launcher and the store home, and restarts
EmulationStation.

```sh
DRY_RUN=1 ./uninstall.sh     # show what would go, remove nothing
KEEP_HOME=1 ./uninstall.sh   # keep state.json and the log, for a reinstall
```

Nothing of yours goes with it: your own ROMs keep their folders, and your
gamelists are rewritten without our nodes rather than deleted — play counts and
favourites survive. The `gamelist.xml.ttg-backup` copies are listed and left
alone.

## What this store installs

Cartridges go to their emulator's ROM folder, native builds to **Ports**:

| Catalog platform | Asset kind | Batocera system | Extension |
| --- | --- | --- | --- |
| `c64` | `cartridge` | `c64` (VICE) | `.prg` |
| `tic80` | `cartridge` | `tic80` | `.tic` |
| `ebitengine` | `linux_x64` / `linux_arm64` | `ports` | `.zip` |
| `bevy` | `linux_x64` / `linux_arm64` | `ports` | `.zip` |
| `godot` | `linux_x64` | `ports` | `.zip` |
| `love` | `linux_x64` | `ports` | `.zip` |

Statuses `released` and `archived`, whole catalog, no owner filter. Everything
lands under the `teletypegames/` subfolder of each system, so a prune can never
reach ROMs you put there yourself. To change any of it, edit
`/userdata/system/batocera-store/ttg/config.json` on the box — the full key
reference is in the engine's README.

## Native games as Ports

Cartridges are a little under half the catalog; the rest of our games are native
Linux builds, and no emulator boots those. Batocera runs Linux, so they are
installed through its **Ports** system instead: the zip is unpacked under
`ports/.data/teletypegames/`, and the launcher EmulationStation lists is
`ports/teletypegames/<name>.sh`, which `cd`s into the program's directory before
running it. They appear under *Ports ▸ Teletype Games*, and `remove` takes the
unpacked program with it.

Each one is a 30–100 MB download rather than the few kilobytes of a cartridge.

**The build has to match the box.** Batocera runs on x86_64 mini-PCs as much as
on the Raspberry Pi and the ARM handhelds, and a native binary only starts on the
architecture it was built for. The engine detects the architecture — `list` and
`config` both report it — and picks the asset for it; where there is none the
title is skipped with a message naming the architecture, rather than installing
something that cannot start:

```
skipped rabbitroller: no 'linux_arm64' asset in any release
```

`ebitengine` and `bevy` build for both `linux_x64` and `linux_arm64`; `godot` and
`love` are x86_64-only for now — a Godot ARM export needs a preset in the game
repo, and LÖVE has no upstream ARM runtime. `tic80` has an ARM problem too, but
it is installed as a cartridge, which is data for an emulator and runs anywhere.
`phaser` ships only a web build, so it is not mapped at all.

Statuses still apply, and they are what keeps this small today: most of our
native titles are `demo`, which is not in `catalog.statuses`. On x86_64 the only
native game that currently installs is `rabbitroller`. Add `"demo"` to
`catalog.statuses` on the box to get the rest.

## Where things land

```
/userdata/system/batocera-store/
├── ttg-store                            launcher
└── ttg/
    ├── store.py, warpstore.py, config.json
    └── state.json, catalog.json, store.log

/userdata/roms/c64/teletypegames/        blessingofra-2.0.0.prg, rabbit-1.0.0.prg, …
/userdata/roms/c64/teletypegames/images/ blessingofra.png, …
/userdata/roms/c64/gamelist.xml          our entries merged in

/userdata/roms/ports/Teletype Games Store.sh        the store itself
/userdata/roms/ports/teletypegames/          rabbitroller.sh, …
/userdata/roms/ports/teletypegames/images/   rabbitroller.png, …
/userdata/roms/ports/.data/teletypegames/    the unpacked programs
```
