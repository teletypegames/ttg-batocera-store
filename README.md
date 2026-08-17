# ttg-batocera-store — the Teletype Games store for Batocera

Puts the <https://teletypegames.org> catalog into a Batocera box's ROM folders,
with EmulationStation metadata and box art. Triggered from the **Ports** menu on
the device, or from the CLI over SSH.

This repository is only the store definition — `config.json` plus a wrapper
installer. All the logic lives in the shared engine,
[`warp-engine-batocera-store`](https://git.teletypegames.org/tools/warp-engine-batocera-store),
which works with any WarpEngine-based site; this is just the Teletype Games
configuration of it.

## Install

Straight onto the device:

```sh
curl -fsSL https://git.teletypegames.org/tools/ttg-batocera-store/raw/branch/master/install.sh | bash
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

## What this store installs

| Catalog platform | Asset kind | Batocera system | Extension |
| --- | --- | --- | --- |
| `c64` | `cartridge` | `c64` (VICE) | `.prg` |
| `tic80` | `cartridge` | `tic80` | `.tic` |

Statuses `released` and `archived`, whole catalog, no owner filter. Everything
lands under the `teletypegames/` subfolder of each system, so a prune can never
reach ROMs you put there yourself. To change any of it, edit
`/userdata/system/batocera-store/ttg/config.json` on the box — the full key
reference is in the engine's README.

## Native games as Ports — experimental

Cartridges are all this store installs by default, which is a little under half
the catalog: the rest of our games are native builds, and an emulator cannot
boot those. The engine can install them through Batocera's **Ports** system
instead, but it is off here on purpose — **nobody has yet confirmed on real
hardware that the games start**, and each one is a 30–100 MB download rather
than a few kilobytes.

To try it, add platform entries to
`/userdata/system/batocera-store/ttg/config.json` on the box:

```json
"platforms": {
  "ebitengine": {
    "system": "ports",
    "install": "port",
    "kind": { "x86_64": "linux_x64", "aarch64": "linux_arm64" },
    "ext": ".zip",
    "enabled": true
  },
  "godot": { "system": "ports", "install": "port",
             "kind": { "x86_64": "linux_x64" }, "ext": ".zip", "enabled": true },
  "love":  { "system": "ports", "install": "port",
             "kind": { "x86_64": "linux_x64" }, "ext": ".zip", "enabled": true },
  "bevy":  { "system": "ports", "install": "port",
             "kind": { "x86_64": "linux_x64", "aarch64": "linux_arm64" },
             "ext": ".zip", "enabled": true }
}
```

Then `/userdata/system/batocera-store/ttg-store sync`. The games appear under
*Ports ▸ Teletype Games*; `remove` takes the unpacked program with it.

**Mind the architecture.** Only the platforms listed with an `aarch64` entry
above have ARM builds today — on a Raspberry Pi or a handheld the others are
skipped with a message naming the architecture, rather than installing something
that cannot start. `godot`, `love` and `tic80` have no ARM build at all yet: a
Godot ARM export needs a preset in the game repo, LÖVE has no upstream ARM
runtime, and TIC-80's exporter has no ARM target.

With everything that can be enabled turned on, the coverage measured on
2026-08-17 was **13 of 15** titles on x86_64 and **9 of 15** on ARM. The two that
stay out either way are `phaserdemo` and `trickster-tiles`: they ship only a web
build.

Report back what happens on a real box — that is the missing piece before this
becomes the default.

## Where things land

```
/userdata/system/batocera-store/
├── ttg-store                            launcher
└── ttg/
    ├── store.py, config.json
    └── state.json, catalog.json, store.log

/userdata/roms/c64/teletypegames/        blessingofra-2.0.0.prg, rabbit-1.0.0.prg, …
/userdata/roms/c64/teletypegames/images/ blessingofra.png, …
/userdata/roms/c64/gamelist.xml          our entries merged in
/userdata/roms/ports/Teletype Games Store.sh
```

## Upgrading from the pre-split `batocera-store`

The old repo installed everything into `/userdata/system/ttg-store`. Re-running
the install command above migrates it: `state.json` is carried over, the old
directory is renamed to `ttg-store.pre-split`, and the Ports entry is replaced
in place. The ROMs themselves never move, so nothing is re-downloaded. Delete
`/userdata/system/ttg-store.pre-split` once the new install looks right.
