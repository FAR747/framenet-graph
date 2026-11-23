# FrameNet Graph

A lightweight World of Warcraft addon for FPS and Home/World network latency history.

Repository: [FAR747/framenet-graph](https://github.com/FAR747/framenet-graph).

Status: core data collection implemented. The monitoring interface is not implemented yet.

## Project layout

```text
framenet-graph/
|-- Core/          Addon initialization, configuration, ring buffers, and collectors
|-- UI/            Monitoring window, graphs, settings, and minimap integration
|-- Libs/          Required third-party runtime libraries and license notices
|-- DOCS/          Project documentation
|-- scripts/       Local development and deployment tools
|-- FrameNetGraph.toc   Addon metadata and runtime file load order
|-- .env.example   Example local deployment configuration
|-- .gitattributes
|-- .gitignore
|-- LICENSE
`-- README.md
```

Empty directories contain `.gitkeep` placeholders until implementation files are added.

## Current functionality

- Author: uFARme.
- Development version: 0.1.0.
- Declared client interfaces: Retail `120105` and Forever `16001`.
- `Core/Init.lua` initializes `FrameNetGraphDB` and separate in-memory buffers after the addon's `ADDON_LOADED` event.
- `/fng`, `/fng status`, and `/fng settings` show intervals and buffer counts/capacities.
- Status also shows the latest FPS, Home/World latency, and each measurement's age.
- `/fng set <setting> <value>` changes a setting immediately, without `/reload`.
- Capacity changes retain the newest samples. The two histories remain independent.
- Saved settings survive `/reload`; sample history does not. Invalid saved settings revert to their defaults.

| Setting | Default | Accepted values |
|---|---|---|
| `fpsInterval` | 1 s | Finite numbers >= 1 |
| `networkInterval` | 30 s | Finite numbers >= 30 |
| `fpsCapacity` | 200 | Integers from 2 to 2000 |
| `networkCapacity` | 200 | Integers from 2 to 2000 |

For example, `/fng set fpsCapacity 500` immediately resizes the FPS buffer.

FPS and network collectors take their first samples on entering the world, including after
`/reload`, then use independent `C_Timer.NewTicker` timers. Changing an interval restarts
only its collector's timer; the next sample arrives after the new interval. Setting the
same interval again does not restart it. Existing samples are retained.

Each sample records the actual `GetTime()` timestamp, so delayed callbacks do not create
invented measurements. Collection continues across zone transitions, without restarting
timers or clearing history. No graphical window is required for collection.

Network samples store the Home and World values returned by `GetNetStats()`; polling
does not force the client to perform a fresh latency measurement.

The installed client manifests were inspected during development: Retail `12.1.5.70961`
and Forever `1.60.1.71037`. The user confirmed loading, setting changes, and configuration
persistence across `/reload` in Forever. The collectors still require in-game verification.
Retail has not been tested.

## Initial scope

- Target the current stable Retail and Forever clients, with initial in-game verification on Forever.
- Collect FPS and network latency independently, including while the monitoring window is hidden.
- Use separate ring buffers with configurable capacities, defaulting to 200 samples each.
- Persist configuration through SavedVariables; keep measurement history in memory only.
- Implement the core before graphs, settings UI, and minimap integration.

## Local deployment configuration

`scripts/dev.ps1` reads a local `.env` file. Copy `.env.example` to `.env`
when preparing a new checkout. `.env` is ignored by Git.

| Variable | Purpose | Initial value |
|---|---|---|
| `WOW_PATH` | World of Warcraft installation directory | `M:\BattleNet\World of Warcraft` |
| `WOW_CLIENT` | Client directory inside the installation | `_forever_` |

The intended addon destination is `<WOW_PATH>\<WOW_CLIENT>\Interface\AddOns\FrameNetGraph`.
Only runtime files and required dependencies will be deployed. Development files stay in this repository.

Run from the repository root in PowerShell:

```powershell
Copy-Item .env.example .env
.\scripts\dev.ps1 -WhatIf
.\scripts\dev.ps1
```

Skip the copy command if `.env` already contains your local settings. The script can also
be launched from another directory; relative `-EnvFile` paths resolve from the repository root.
Paths with spaces may be unquoted or enclosed in matching single or double quotes in `.env`.
Only `WOW_PATH` and `WOW_CLIENT` entries and full-line `#` comments are supported.

The selected client's `Interface\AddOns` directory must already exist. The script copies
`FrameNetGraph.toc`, `LICENSE`, and files under `Core/`, `UI/`, and `Libs/`, excluding
`.gitkeep` placeholders. Keep only runtime files and required dependency license notices
in those runtime directories. Existing matching files are overwritten; stale files are not removed.

After the first deployment, restart the client if it was already running so that WoW discovers
the new addon. Enable FrameNet Graph in the AddOns list, enter the world, and run `/fng`.
The expected first line is `FrameNet Graph: collecting.`, followed by history counts
and the latest measurements. Repeat `/fng status` after a sampling interval to check
that history grows. `/reload` starts a new history with the saved settings.
For later changes to existing Lua files, deploy again and use `/reload` in game.

## License

GPL-2.0-or-later. See [LICENSE](LICENSE). Third-party libraries retain their own licenses.
