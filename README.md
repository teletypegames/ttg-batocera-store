# ttg-batocera-store — the Teletype Games store for Batocera

Puts the <https://teletypegames.org> catalog on a Batocera box, with
EmulationStation metadata and box art, under **its own menu entry**: *Teletype
Games*, next to the box's own systems. Started from there on the device, or from
the CLI over SSH.

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
`/userdata/system/batocera-store/ttg/`, writes the `ttg-store` launcher, and runs
the first sync — which downloads the games and writes the menu entry. Restart
EmulationStation (`batocera-es-swissknife --restart`) to see it.

## Use

**On the device.** *Teletype Games ▸ "Update Teletype Games"*. It
downloads anything new, then restarts EmulationStation. ES gives a launched
script no console, so the output goes to
`/userdata/system/batocera-store/ttg/store.log`.

```
main carousel:  …  ▸  Teletype Games  ▸  ┌ Commodore 64
                                         ├ TIC-80
                                         ├ Ports                    the native builds
                                         └ Update Teletype Games    the sync
```

The entry carries our own logo — the TTG mark (`media/LOGOv2/TTG-Logo-Black`),
shipped in this repository as `logo.png`, plus a pixel-exact `logo.svg` for the
themes that only look for an SVG. The engine installs it into the logo folder of
every theme on the box; a theme it cannot reach shows *TELETYPE GAMES* as text.
Themes that came with the Batocera image live on the read-only system, so their
copy is in the RAM overlay and goes away on a reboot — the next update puts it
back, and `batocera-save-overlay` makes it permanent.

Only the platforms that have something installed show up as folders, so the entry
never has a dead end in it. The games are launched exactly as the box would
launch them — the engine copies the launch command and the emulator list off the
box's own `c64`, `cplus4`, `tic80` and `ports` systems, so whatever you configured for the
C64 applies to our C64 games too.

**Over SSH.**

```sh
S=/userdata/system/batocera-store/ttg-store

$S list                 # compatible catalog entries; * installed, ^ update available
$S sync                 # download everything new, refresh gamelists and the menu
$S sync blessingofra    # just one title (never prunes)
$S -n sync              # dry run
$S remove c64demo       # uninstall
$S config               # effective configuration, and where the menu entry lives
```

Global flags go before the subcommand: `$S --roms-root /tmp/roms sync`.

## Upgrading from a pre-4.0 install

Older versions installed into the box's own systems — `c64/teletypegames/`,
`tic80/teletypegames/`, `ports/teletypegames/` — and ran the sync from *Ports ▸
Teletype Games Store*. The first sync after the upgrade moves all of that into
`/userdata/roms/teletypegames/`, the store's own folder, by taking the old
install off the box and downloading again. It also removes the old Ports entry:
the updater now lives inside the menu entry.

Nothing of yours goes with it: our nodes come out of your gamelists and the rest
— your own games, their play counts and favourites — is written back untouched,
and the `gamelist.xml.ttg-backup` copies are listed and left alone. Today's
catalog is six cartridges and one native build, so the re-download is minutes.

`-n sync` shows the whole thing without doing any of it. To stay on the old
layout, set `emulationstation.menu.mode` to `merge` in
`/userdata/system/batocera-store/ttg/config.json` before syncing.

## Uninstall

```sh
curl -fsSL https://git.teletypegames.org/stores/ttg-batocera-store/raw/branch/master/uninstall.sh | sh
```

Or `/tmp/ttg-batocera-store/uninstall.sh` from a checkout on the box. It takes
out the games — including any unpacked port payload — our gamelists, the menu
entry, the logos it put in your themes, the launcher and the store home, and
restarts EmulationStation.

```sh
DRY_RUN=1 ./uninstall.sh     # show what would go, remove nothing
KEEP_HOME=1 ./uninstall.sh   # keep state.json and the log, for a reinstall
```

Since everything the store installs lives in one folder of its own, an uninstall
leaves the box exactly as it was: your own ROM folders are never touched.

## What this store installs

Cartridges go to the folder of the system that boots them, native builds to a
`ports` folder — all of them inside the store's own tree:

| Catalog platform | Asset kind | Folder in the menu | Extension |
| --- | --- | --- | --- |
| `c64` | `cartridge` | Commodore 64 (VICE) | `.prg` |
| `plus4` | `cartridge` | Commodore Plus/4 (VICE) | `.prg` |
| `tic80` | `cartridge` | TIC-80 | `.tic` |
| `ebitengine` | `linux_x64` / `linux_arm64` | Ports | `.zip` |
| `bevy` | `linux_x64` / `linux_arm64` | Ports | `.zip` |
| `godot` | `linux_x64` | Ports | `.zip` |
| `love` | `linux_x64` | Ports | `.zip` |

Statuses `released` and `archived`, whole catalog, no owner filter. To change any
of it, edit `/userdata/system/batocera-store/ttg/config.json` on the box — the
full key reference is in the engine's README.

## Native games as Ports

Cartridges are a little under half the catalog; the rest of our games are native
Linux builds, and no emulator boots those. Batocera runs Linux, so they are
installed the way its **Ports** system does it: the zip is unpacked under
`teletypegames/ports/.data/`, and the launcher EmulationStation lists is
`teletypegames/ports/<name>.sh`, which `cd`s into the program's directory before
running it. They appear under *Teletype Games ▸ Ports*, and `remove` takes the
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

/userdata/system/configs/emulationstation/es_systems_ttg.cfg   the menu entry
<every theme>/<its logo folder>/ttg.png, ttg.svg                the entry's logo

/userdata/roms/teletypegames/            the store's own ROM folder
├── c64/
│   ├── blessingofra-2.0.0.prg, rabbit-1.0.0.prg, …
│   ├── images/blessingofra.png, …
│   └── gamelist.xml
├── tic80/
│   └── …
├── ports/
│   ├── rabbitroller.sh, images/rabbitroller.png
│   ├── .data/rabbitroller/              the unpacked program
│   └── gamelist.xml
└── store/                               the menu entry itself
    ├── update.sh                        the sync, as the menu starts it
    └── gamelist.xml
```
