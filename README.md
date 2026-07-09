# FLO: Frontline Operations

*Project overview and operator reference.*

FLO is a persistent Arma 3 combined-arms campaign packaged as a HEMTT addon. The server owns campaign startup and runtime systems, so the campaign can continue after all players log off. A logged-in admin is still required to configure a fresh campaign, and saved progress is loaded only when explicitly selected.

## Features

- Dynamic objectives, frontline ownership, staged capture, and strategic links.
- Independent EAST and WEST GTN commanders for attacks, defense, reserves, and support.
- Persistent virtual groups that activate near players and return to simulation-safe virtual state.
- Resource-backed logistics, supply nodes, replacements, transport, artillery, and air support.
- Civilian population, reputation, local intel, missions, and reactions to combat.
- A Store for gear, vehicles, and recruitable AI; the legacy Arsenal and request menu are removed.
- UI-based FOB/COP deployment; physical deployment containers are no longer required.
- Explicit save, continue, and reset flows for long-running hosted or dedicated campaigns.

## Requirements

Runtime:

- Arma 3 version `2.18` or newer.
- [CBA_A3](https://steamcommunity.com/sharedfiles/filedetails/?id=450814997).
- Any mods required by the selected faction presets.

Development:

- The bundled HEMTT executable at `.tools/hemtt/hemtt.exe`, or a compatible HEMTT installation.

Faction-specific dependencies are listed in [the faction preset guide](addons/main/Scripts/factions/README.md).

## Build and Test

Run from the repository root:

```powershell
.\.tools\hemtt\hemtt.exe check
.\.tools\hemtt\hemtt.exe build
.\.tools\hemtt\hemtt.exe launch
```

- `check` validates config and SQF without packaging.
- `build` writes `flo_main.pbo` to `.hemttout/build/addons/`.
- `launch` starts the configured `missions/FLO_Test.Altis` development mission with CBA.

HEMTT diagnostics must be fixed at the source; do not suppress them. For a manual mod layout, place the built PBO at `@FLO/addons/flo_main.pbo` and load both CBA and FLO on every server and client.

## Start a Campaign

Set `FLO > Campaign > Campaign launch mode` in CBA settings before mission initialization:

| Mode | Behavior |
| --- | --- |
| `Fresh setup` | Ignores saved progress and waits for an admin to complete setup. |
| `Continue saved progress` | Loads a valid FLO save; otherwise starts fresh. |
| `Reset saved progress` | Deletes the current FLO save and starts fresh. |

Fresh setup configures factions, commander posture, player start, starting territory, enemy presence, objective filtering, virtualization limits, reputation, and resources. Starting money defaults to `5000`.

The setup dialog opens only for a hosted server or a client logged in as admin. Once initialization completes, no player commander or occupied slot is required to keep server-owned campaign systems running. Clients remain on the deployment screen until the server publishes `FLO_MissionReady`, then receive one cleanup respawn at the campaign start.

## Player Controls

- Open the FOB/COP Deployment Panel with `Ctrl+Shift+D`. Deployment requires an admin, officer, or group leader and is validated by the server.
- Use the Store action at a FOB or COP to buy gear and vehicles or recruit AI.
- Commander support, civilian interactions, tasking, and map intel appear through their in-game actions and notifications.

## Persistence and Admin Tools

FLO stores campaign data in the server profile namespace. Saves never auto-load: select `Continue saved progress` for the next session. Changes to faction pools or objective templates do not retroactively reseed groups already stored in an old save.

Add money from the admin debug console:

```sqf
[5000] remoteExecCall ["FLO_fnc_addMoney", 2];
```

The amount is added to the server-authoritative balance and synchronized to clients.

## Factions

Curated or custom factions define the unit, vehicle, air, support, and Store pools used throughout the campaign. The primary customization files are:

- [`CUSTOM_PLAYER_FACTION.sqf`](addons/main/CUSTOM_PLAYER_FACTION.sqf)
- [`CUSTOM_ENEMY_FACTION.sqf`](addons/main/CUSTOM_ENEMY_FACTION.sqf)
- [`CUSTOM_CIVILIAN_FACTION.sqf`](addons/main/CUSTOM_CIVILIAN_FACTION.sqf)

The setup UI also discovers compatible loaded `CfgFactionClasses` entries. Auto-generated factions are a compatibility path; curated presets remain the place for deliberate class selection, pricing, and balance. Numeric force composition is configured in the setup UI rather than duplicated in faction files.

## Initialization

[`fn_addonPostInit.sqf`](addons/main/Functions/Init/fn_addonPostInit.sqf) starts the addon on server and clients. The server then runs [`fn_initPhaseManager.sqf`](addons/main/Functions/Init/fn_initPhaseManager.sqf) in this order:

1. Detect or reset saved progress.
2. Load saved configuration or wait for fresh setup.
3. Build faction catalogs.
4. Index or restore objectives.
5. Seed or restore virtual forces.
6. Start commanders, logistics, civilians, support, and client systems.

Clients finalize only after the server marks the mission ready.

## Repository Layout

| Path | Purpose |
| --- | --- |
| [`addons/main`](addons/main) | Authoritative addon source and config. |
| [`addons/main/Functions`](addons/main/Functions) | FLO gameplay and framework systems. |
| [`addons/main/UI`](addons/main/UI) | Store, deployment, setup, and HUD definitions. |
| [`addons/main/Scripts/factions`](addons/main/Scripts/factions) | Curated faction presets and dependency guide. |
| [`missions/FLO_Test.Altis`](missions/FLO_Test.Altis) | HEMTT launch and integration-test mission. |
| [`.hemtt/project.toml`](.hemtt/project.toml) | Build and launch configuration. |

Runtime systems belong under `addons/main`; the test mission should remain a thin shell.

## Diagnostics

Use the Arma RPT and search for these prefixes:

| Prefix | Meaning |
| --- | --- |
| `[FLO_INIT]` | Server initialization phases and failures. |
| `[FLO_INIT_CLIENT]` | Client readiness and finalization. |
| `[FLO_SETTINGS]` | CBA setting registration. |
| `[FLO][PERF]` | Startup and heavy-system timing diagnostics. |
| `[FLO][MONEY]` | Authoritative balance changes. |

Phases 3 and 4 emit startup-only `[FLO][PERF]` measurements for objective indexing, graph construction, save restoration, virtualization setup, and group seeding. Compare logs only under similar map, faction, save, and objective conditions.

Common checks:

- Missing CBA settings: confirm CBA and FLO are both loaded, then inspect `[FLO_SETTINGS]` lines.
- Setup dialog does not open: select `Fresh setup` and log in as admin or host the session.
- Continue mode starts fresh: inspect `[FLO_INIT]` for a missing, incomplete, or incompatible save.
- Initialization stalls or fails: find the last completed phase and the reported `FLO_InitError`.
- Build problems: run `hemtt check` first and fix every reported source issue.

## Contributing

Use [CONTRIBUTING.md](CONTRIBUTING.md) for commit-message requirements. Keep transient handoff state and implementation-specific design notes out of this operator guide.

## License

FLO is distributed under the [GNU General Public License v3.0](LICENSE).
