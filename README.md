# FLO: Frontline Operations

FLO is a persistent Arma 3 frontline campaign mission built around dynamic objectives, AI command, virtualization, logistics, civilians, and long-running saves. It is designed for long sessions where one human-controlled side fights a campaign while the rest of the theater keeps moving in the background.

## What FLO Does

- Runs a persistent campaign with save/load support.
- Builds a living frontline instead of one static mission start.
- Uses AI commanders for `EAST` and `WEST` to manage attacks, defense, support, and reserves.
- Virtualizes most of the battlefield so large campaigns can keep running without simulating every unit live all the time.
- Uses logistics and supply networks so destroyed forces are replaced through actual resources and supply chains instead of free respawns.
- Supports custom friendly, enemy, and civilian factions through mission-root faction files.

## Main Features

### Persistent Campaign

- The campaign can be started fresh or loaded from a previous save.
- Objective ownership, virtual groups, logistics state, and mission configuration persist across saves.
- The battlefield keeps evolving instead of resetting every session.

### Dynamic Frontline

- Objectives are linked into a real frontline and rear area network.
- Towns, villages, military sites, and clusters change ownership over time.
- Frontline pressure, contested sectors, and reinforcement needs update during the session.
- Newly captured sectors do not immediately become perfect launchpads. Capture growth is delayed, repeated breakthroughs fatigue the attacking commander, and overextended lanes stage more slowly.

### Dual AI Commanders

- FLO runs one GTN commander for each military side.
- Commanders build a maintained world state, allocate forces, protect threatened sectors, request support, and launch attacks.
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

## What Players Can Expect

- One side is the active human faction for the session.
- The first connected `EAST` or `WEST` player locks the active player side.
- Players on the opposite military side are moved to spectator.
- The campaign is built for multiplayer, hosted MP, dedicated servers, and long-running co-op sessions.
- Support, logistics, and AI pressure continue to matter even when players move away from one area.

## Mission Setup

On a fresh start, the commander configures the campaign through the mission setup flow.

Current setup options include:

- friendly faction
- enemy faction
- civilian faction
- player start position
- difficulty and reputation handles
- separate BLUFOR/WEST and OPFOR/EAST commander posture settings for aggression, tempo, attack coverage, defense coverage, force growth, and baseline garrison
- enemy presence
- objective size threshold
- virtualization distance
- virtualization unit cap
- starting territory ratio from `10/90` up to `90/10`

On a loaded save, the saved configuration is restored automatically and the setup dialog is skipped.

## Requirements

- Arma 3
- CBA
- any faction-specific mods required by the faction files you select

FLO can run in singleplayer, hosted multiplayer, or on a dedicated server, but it is primarily built around multiplayer campaign sessions.

## Quick Start

1. Put the mission source in your Arma 3 profile `missions` folder, or pack it as a PBO for a server.
2. Open the mission in Eden Editor if you want to inspect or customize it.
3. Launch it in multiplayer preview, hosted MP, or on a dedicated server.
4. On a fresh start, complete the mission setup flow as the commander.
5. On a loaded save, let the mission restore the campaign state and continue from there.

## Session Model

| Topic | Behavior |
|------|----------|
| Active human side | One military side per session |
| Opposing military side | Spectator-only for human players |
| Fresh start | Resets campaign state and opens mission setup |
| Loaded save | Restores saved campaign state and skips setup |
| Campaign authority | Server-owned startup and persistent systems |

## Initialization Pipeline

All authoritative startup work runs on the server through [`Functions/Init/fn_initPhaseManager.sqf`](Functions/Init/fn_initPhaseManager.sqf).

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

- [`CUSTOM_PLAYER_FACTION.sqf`](CUSTOM_PLAYER_FACTION.sqf)
- [`CUSTOM_ENEMY_FACTION.sqf`](CUSTOM_ENEMY_FACTION.sqf)
- [`CUSTOM_CIVILIAN_FACTION.sqf`](CUSTOM_CIVILIAN_FACTION.sqf)

Phase 2 builds `FLO_FactionCatalog` from those files, and that catalog feeds:

- commander force pools
- objective seeding
- virtualization spawn pools
- logistics replacements
- transport reserves
- civilian population templates

### Objective Templates

Objective templates control what kind of groups a subtype can seed.

```sqf
OPFOR_Objective_Groups = [
    ["capital", [
        ["infantry", 12],
        ["motorized", 2],
        ["mechanized", 1],
        ["armor", 1],
        ["artillery", 1]
    ]],
    ["city", [
        ["infantry", 7],
        ["motorized", 2]
    ]]
];
```

### Group Counts

Group-count tables control the physical strength of each virtual group type.

```sqf
OPFOR_Group_Counts = [
    ["infantry", 10],
    ["motorized", 2],
    ["mechanized", 2],
    ["armor", 2],
    ["artillery", 1]
];
```

### Side-Wide Objective Caps

Use side-wide caps when an asset type is allowed in templates, but should not appear at every eligible objective.

```sqf
West_Objective_Group_Type_Caps = [
    ["artillery", 5]
];

East_Objective_Group_Type_Caps = [
    ["artillery", 5]
];
```

### Transport Reserve Counts

Dedicated transport reserve pools are configured separately from frontline groups.

```sqf
West_Transport_Reserve_Ground_Count = 20;
West_Transport_Reserve_Air_Count = 10;

East_Transport_Reserve_Ground_Count = 20;
East_Transport_Reserve_Air_Count = 10;
```

### Save/Load Note

Changing faction files does not automatically reseed an old save with newly-added groups. Loaded saves restore saved virtual groups first. If you add new template group types after a save already exists, you usually need either:

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
| `RestrictedArsenal` | Enables the restricted arsenal flow |
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

## Repository Layout

| Path | Purpose |
|------|---------|
| [`Functions/Init`](Functions/Init) | Server phase manager and client finalization |
| [`Functions/AI/GTN`](Functions/AI/GTN) | Commanders, world state, combat, support, alerts, and player support |
| [`Functions/Virtualization`](Functions/Virtualization) | Group registry, activation lifecycle, routing, transport, and seeding |
| [`Functions/Logistics`](Functions/Logistics) | Resources, supply networks, replacement dispatch, and reserve replenishment |
| [`Functions/Objective`](Functions/Objective) | Objective indexing, ownership, graph links, and markers |

## License

FLO is distributed under the GNU General Public License v3.0. See [`LICENSE`](LICENSE).
