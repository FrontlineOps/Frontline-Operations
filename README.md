# FLO: Frontline Operations

FLO is a persistent Arma 3 frontline campaign mission built around dynamic objectives, AI command, virtualization, logistics, civilians, player logistics, and long-running saves. This branch is also structured as a HEMTT-built addon-backed project so the mission systems can move out of one loose mission folder over time.

## What FLO Does

- Runs a persistent campaign with save/load support.
- Builds a living frontline instead of one static mission start.
- Uses AI commanders for `EAST` and `WEST` to manage attacks, defense, support, and reserves.
- Virtualizes most of the battlefield so large campaigns can keep running without simulating every unit live all the time.
- Uses logistics and supply networks so destroyed forces are replaced through actual resources and supply chains instead of free respawns.
- Replaces the legacy request-menu and Arsenal supply flow with a browser-based Store.
- Provides a dedicated FOB/COP Deployment Panel so forward bases can be placed from UI instead of by moving physical containers.
- Supports custom friendly, enemy, and civilian factions through mission-root faction files.

## Main Features

### Persistent Campaign

- The campaign can be started fresh or loaded from a previous save.
- Objective ownership, virtual groups, logistics state, and mission configuration persist across saves.
- The battlefield keeps evolving instead of resetting every session.

### Dynamic Frontline

- Objectives are linked into a real frontline and rear area network.
- Towns, villages, military sites, and clusters change ownership over time.
- Objective capture now moves through explicit states: held, contested, clearing, securing, integrating, and integrated.
- Ownership only flips after attackers finish normal capture progress and hold the sector through a securing timer.
- The capture UI reads the server-owned objective state directly, so players can see whether they are clearing resistance, securing the area, or watching a newly captured sector integrate.
- Frontline pressure, contested sectors, and reinforcement needs update during the session.
- Newly captured sectors do not immediately become perfect launchpads. Capture growth is delayed, repeated breakthroughs fatigue the attacking commander, and overextended lanes stage more slowly.

### Dual AI Commanders

- FLO runs one GTN commander for each military side.
- Commanders build a maintained world state, allocate forces, protect threatened sectors, request support, and launch attacks.
- New ATTACK, DEFEND, and GARRISON route orders are budgeted per commander cycle so large reallocations spread out instead of generating one large burst. Defaults are 4 total new strategic route orders per commander cycle, with attack, defense, and garrison each capped at 2.
- Enemy commander minefields are player-facing: new fields are only queued on hostile frontline objectives within the virtualization activation distance plus 500m of active-side players, and queued builds cancel if players leave before the field is committed.
- The enemy side is not just a pile of spawned patrols. It is managed as a campaign opponent.

### Virtualized Battlefield

- Ground, air, artillery, and transport groups exist in a persistent virtual registry.
- Groups become real near players and return to virtual state when they safely leave the activation range.
- Orders, routes, transport attachments, mission locks, and runtime state are preserved across activation cycles.
- This lets the mission run large theaters without having to keep every unit fully simulated.

### Logistics and Reinforcements

- Each side has its own logistics network and supply chain.
- The network selects an HQ, promotes forward supply nodes, and dispatches replacements from rear areas.
- Replacements spend side resources instead of appearing for free.
- Capturing territory only expands long-term force growth after the new owner actually holds and consolidates the sector.
- Rear-area support assets such as artillery and aircraft are only considered available when they are actually secure.
- Transport reserve pools are maintained separately from frontline combat forces.

### Custom Transport System

- Infantry can be assigned ground or air transport for longer operational moves.
- Live dismounts are staged more safely for trucks, APCs, and helicopters.
- Carriers can revirtualize after transport work instead of being held active forever.

### Civilian Population and Behavior

- Civilians are no longer just random walkers.
- Civilian groups are seeded with roles such as residents, vendors, workers, watchers, wanderers, and drivers.
- Settlements can have moving civilians, anchored building civilians, market activity, and parked civilian vehicles.
- Civilian behavior changes with local control, threat, recent combat, and reputation.
- Civilians can flee, shelter, protest, or return to normal routines depending on local conditions.

### Civilian Intel and Interaction

- Players can ask civilians about local activity.
- Civilian reports can cover patrol sightings, vehicle movement, checkpoint rumors, safe routes, and hostile reports.
- Civilian intel is local and uncertain rather than omniscient.
- Civilians can also offer missions, react to detention, and support interrogation gameplay.

### Player-Requested Commander Support

- Players can request commander-managed artillery, CAS, and CAP.
- Requests go through the side commander instead of directly spawning support effects.
- Support requests use map clicks, cooldowns, queueing, and HQ radio messages.
- Approved support reuses the real GTN artillery and air systems.

### Commander Player Tasks

- The GTN commander publishes one primary and one secondary side-wide task for the active human faction.
- Player tasking is intentionally sticky so the current order is held for a minimum window instead of being replaced on every scoring wobble.
- Defend tasks only close after the sector stays calm for a sustained window, instead of succeeding on a single quiet sample.
- Task scoring follows the main player concentration more than a single distant outlier, so one scout or pilot does not yank the whole side's orders as easily.

### Battlefield Intel Pickups

- Enemy units can carry intel items such as phones, secret files, and flash drives.
- Picking these up can reveal enemy commander targets, supply nodes, or HQ information on the map for a limited time.
- These reveals are temporary and side-only rather than permanent full-map knowledge.

### Commander Intel and Supply Visibility

- The commander COP publishes friendly support and supply information.
- Friendly supply nodes and HQ markers can be shown on the map.
- Players can locally toggle supply-node visibility so the map does not have to stay cluttered.

### Store and Recruitable AI

- The Store UI is available from FOB/COP actions and uses the runtime faction catalog.
- Players can buy gear, vehicles, and recruitable AI from the same supply surface.
- Vehicle purchases use the existing vehicle configuration pipeline and Store-specific vehicle handling.
- The old request-menu scripts and dialog are removed.
- The old Arsenal initialization path is removed; base supply is expected to flow through Store systems.

### FOB/COP Deployment Panel

- FOB and COP placement uses a dedicated browser UI instead of slingloading or unpacking physical containers.
- The Deployment Panel has a CBA keybind: `Ctrl+Shift+D`.
- Deployment is server-authoritative and validates player side, authority, placement distance, terrain, and cost before creating the base.
- Fresh bases initialize through the existing FOB/COP initialization functions after placement.

## What Players Can Expect

- The campaign is built for multiplayer, hosted MP, dedicated servers, and long-running sessions.
- Fresh setup still requires an admin-controlled launch flow.
- A saved campaign only continues when the server/admin explicitly launches in the saved-progress mode; valid saves are not auto-loaded just because they exist.
- Store and Deployment Panel systems are now the expected player logistics surfaces.
- Support, logistics, and AI pressure continue to matter even when players move away from one area.

## Mission Setup

On a fresh start, an admin configures the campaign through the mission setup flow.

Current setup options include:

- friendly faction
- enemy faction
- civilian faction
- multiple compatible auto military or civilian factions can be selected for the same side; FLO merges their detected pools into one side catalog
- force composition setup values are capability-gated before virtualization, so unavailable optional categories such as armor, mobile AA, static AA, artillery, jets, or helicopters are skipped with a warning instead of hard-failing Phase 4
- player start position
- difficulty and reputation handles
- separate BLUFOR/WEST and OPFOR/EAST commander posture settings for aggression, tempo, attack coverage, defense coverage, force growth, and baseline garrison
- enemy presence
- objective size threshold
- virtualization distance
- virtualization unit cap
- starting money, defaulting to `5000`
- starting territory ratio from `10/90` up to `90/10`

On an explicitly loaded save, the saved configuration is restored and the setup dialog is skipped.

## Requirements

- Arma 3
- CBA
- any faction-specific mods required by the faction files you select
- HEMTT for addon builds and validation

FLO can run in singleplayer, hosted multiplayer, or on a dedicated server, but it is primarily built around multiplayer campaign sessions.

## Quick Start

1. Build the addon with HEMTT, or launch the HEMTT test mission from `missions/FLO_Test.Altis`.
2. Load the generated `@FLO` addon with CBA.
3. On a fresh start, log in as admin or host the session and complete the mission setup flow.
4. Open the Deployment Panel with `Ctrl+Shift+D` to place FOB/COP infrastructure.
5. Use the Store action at bases for gear, vehicles, and recruitable AI.
6. On a loaded save, explicitly launch saved progress and let the mission restore the campaign state.

## HEMTT Workflow

The authoritative source lives under [`addons/main`](addons/main), with HEMTT configuration in [`.hemtt/project.toml`](.hemtt/project.toml). The old loose mission root has been removed; do not add new runtime systems outside the addon tree unless they are part of a dedicated test mission under [`missions`](missions).

Common local commands:

```powershell
.\.tools\hemtt\hemtt.exe check
.\.tools\hemtt\hemtt.exe build
```

`hemtt check` must be clean before changes are considered ready. Do not suppress HEMTT diagnostics; fix the source issue or remove stale content.

## Session Model

| Topic | Behavior |
|------|----------|
| Player logistics | Store UI and Deployment Panel |
| Fresh start | Resets campaign state and opens mission setup |
| Loaded save | Restores saved campaign state only when explicitly launched as saved progress |
| Campaign authority | Server-owned startup and persistent systems |

## Initialization Pipeline

All authoritative startup work runs on the server through [`addons/main/Functions/Init/fn_initPhaseManager.sqf`](addons/main/Functions/Init/fn_initPhaseManager.sqf).

| Phase | Name | Purpose |
|------|------|---------|
| 0 | Save Detection | Detects existing save data and restores saved mission config when present |
| 1 | Mission Config | Waits for commander setup on fresh start, or restores saved mission config |
| 2 | Factions | Loads faction scripts and builds the runtime faction catalog |
| 3 | Objectives | Indexes map objectives or restores saved objective state |
| 4 | Virtualization | Seeds or restores virtual groups, reserves, and registry state |
| 5 | Mission Systems | Starts GTN, logistics, routing, civilians, support systems, and client-facing systems |

Clients wait for `FLO_MissionReady` and then finalize local UI, map intel, and player-side actions.

## Faction Customization

The main customization entry points are:

- [`addons/main/CUSTOM_PLAYER_FACTION.sqf`](addons/main/CUSTOM_PLAYER_FACTION.sqf)
- [`addons/main/CUSTOM_ENEMY_FACTION.sqf`](addons/main/CUSTOM_ENEMY_FACTION.sqf)
- [`addons/main/CUSTOM_CIVILIAN_FACTION.sqf`](addons/main/CUSTOM_CIVILIAN_FACTION.sqf)
- [`addons/main/Scripts/factions/README.md`](addons/main/Scripts/factions/README.md) for built-in preset dependencies and required mods

Phase 2 builds `FLO_FactionCatalog` from those files, and that catalog feeds:

- commander force pools
- objective seeding
- virtualization spawn pools
- logistics replacements
- transport reserves
- civilian population templates

### Auto-Generated Compatible Factions

The mission setup UI also appends `[AUTO]` faction entries generated from the currently loaded `CfgFactionClasses` and `CfgVehicles` config data. These entries do not create new `.sqf` preset files. They build a runtime FLO catalog directly from compatible config classes.

Military auto factions are included when they have spawnable `Man` units. FLO uses any matching all-infantry `CfgGroups` entries when present, then classifies same-faction vehicles into motorized, mechanized, armor, transport, artillery, air, AA, drone, boat, and radar pools. Civilian auto factions use spawnable civilian `Man` units and civilian vehicles.

Auto-faction keep/drop and selected-catalog diagnostics are emitted through `FLO_fnc_log` as `FACTIONS` warning-level logs (`FLO_Debug_Level >= 2`).

Mission setup includes a Per Numeric Force Composition card. Each row is prefilled with default faction values and accepts a non-negative whole number per side. The Composition tab controls ground and air transport reserve counts, objective group type caps, and group counts for `infantry`, `motorized`, `mechanized`, `armor`, `helicopter`, `jet`, `air`, `artillery`, `mobile_aa`, and `static_aa`. The Objective Groups tab controls per-objective subtype templates for `capital`, `city`, `village`, `local`, `marine`, and `cluster` objectives.

Composition values apply by key. For example, setting OPFOR Armor Count to `1` changes only that side's `armor` count; it does not replace the rest of the group count list.

Curated presets remain the preferred path for tuned balance, prices, and exact doctrine. `[AUTO]` entries are a compatibility path for loaded mods that have usable faction config but no FLO preset yet.

### Objective Templates

Objective templates control what kind of groups a subtype can seed. Curated, custom, and auto-generated factions use the same standard numeric defaults from `FLO_fnc_factionGetCompositionDefaults`, then mission setup always sends the typed Objective Groups values with the rest of the numeric force composition tuning. Faction `.sqf` files do not define `BLUFOR_Objective_Groups` or `OPFOR_Objective_Groups`.

### Numeric Force Composition

Group counts, objective caps, and transport reserve counts are configured through the mission setup Per Numeric Force Composition card. Faction `.sqf` files define available units and vehicles; they do not need to define `BLUFOR_Group_Counts`, `OPFOR_Group_Counts`, side-wide objective cap globals, or transport reserve count globals.

### Save/Load Note

Changing centralized objective templates or faction vehicle pools does not automatically reseed an old save with newly-added groups. Loaded saves restore saved virtual groups first. If you add new template group types after a save already exists, you usually need either:

- a mission reset with the `FreshStart` lobby parameter, or
- a targeted backfill call such as:

```sqf
[west, ["city"], ["artillery", "jet", "helicopter"]] call FLO_fnc_backfillObjectiveTemplateGroups;
```

## Runtime Configuration

### Lobby Parameters

| Parameter | Meaning |
|-----------|---------|
| `AutoSaveSwitch` | Enables or disables mission auto-save |
| `AutoSaveInterval` | Auto-save cadence |
| `FreshStart` | Load saved progress or reset mission progress |
| `RagequitBlocker` | Prevents abort while unconscious |
| `DisableSystemChat` | Hides system chat |

### Commander Campaign Config

On a fresh start, the commander setup flow publishes:

- faction handles
- difficulty and reputation handles
- GTN attack, defense, tempo, growth, and garrison settings
- enemy presence
- objective size threshold
- virtualization distance
- virtualization unit cap
- player start position
- starting territory ratio

### Admin Money Command

Run this from the admin debug console after mission setup to add money through the server-authoritative money state:

```sqf
[5000] remoteExecCall ["FLO_fnc_addMoney", 2];
```

### Default GTN Order Budgets

The commander authors strategic order caps against the `10s` tempo baseline, then scales them upward with the tempo curve:

- shared strategic order budget: `6` at `10s`, `14` at `14s`, `24` at `20s`, `32` at `28s`
- ATTACK cap: `3` at `10s`, `7` at `14s`, `12` at `20s`, `16` at `28s`
- DEFEND cap: `3` at `10s`, `7` at `14s`, `12` at `20s`, `16` at `28s`
- GARRISON cap: `2` at `10s`, `5` at `14s`, `8` at `20s`, `11` at `28s`

## Repository Layout

| Path | Purpose |
|------|---------|
| [`addons/main`](addons/main) | Source of truth for packaged FLO addon systems |
| [`.hemtt/project.toml`](.hemtt/project.toml) | HEMTT project, launch, and build configuration |
| [`addons/main/Functions/Init`](addons/main/Functions/Init) | Server phase manager and client finalization |
| [`addons/main/Functions/AI/GTN`](addons/main/Functions/AI/GTN) | Commanders, world state, combat, support, alerts, and player support |
| [`addons/main/Functions/Store`](addons/main/Functions/Store) | Store catalog, checkout, gear, vehicle, and recruitable AI handling |
| [`addons/main/Functions/Base`](addons/main/Functions/Base) | FOB/COP Deployment Panel setup and server placement requests |
| [`addons/main/Functions/Factions`](addons/main/Functions/Factions) | Runtime auto-generated faction compatibility and catalog builders |
| [`addons/main/Functions/Virtualization`](addons/main/Functions/Virtualization) | Group registry, activation lifecycle, routing, transport, and seeding |
| [`addons/main/Functions/Logistics`](addons/main/Functions/Logistics) | Resources, supply networks, replacement dispatch, and reserve replenishment |
| [`addons/main/Functions/Objective`](addons/main/Functions/Objective) | Objective indexing, ownership, graph links, and markers |
| [`addons/main/UI/Store`](addons/main/UI/Store) | Browser UI for the Store |
| [`addons/main/UI/Deploy`](addons/main/UI/Deploy) | Browser UI for FOB/COP deployment |
| [`missions/FLO_Test.Altis`](missions/FLO_Test.Altis) | Minimal HEMTT launch/test mission shell |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | GitHub commit message rules and contribution expectations |

## License

FLO is distributed under the GNU General Public License v3.0. See [`LICENSE`](LICENSE).
