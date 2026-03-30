# FLO: Frontline Operations

FLO is a persistent Arma 3 frontline mission source built around phased server initialization, dual-side GTN commanders, force virtualization, resource-driven logistics, and long-running save states. The mission is designed for one human-controlled side per session while the opposing theater is managed by AI systems and virtualized assets.

## What FLO Is

- Persistent campaign mission with save/load support.
- Objective-driven frontline with dynamic ownership, pressure, and reinforcement.
- Virtualized ground, air, artillery, and transport groups that only unvirtualize near players.
- Dual GTN commanders for `EAST` and `WEST`, with the active human side locked at runtime.
- Side-scoped logistics networks with HQ selection, active supply nodes, and automated replacement dispatch.
- Custom faction catalogs driven from mission-root faction files instead of hardcoded pools.

## Requirements

- Arma 3.
- CBA. FLO uses CBA events and PFHs throughout the mission.
- Any faction-specific mod sets required by the faction files you choose.
- Singleplayer, Multiplayer, hosted MP, or a dedicated server.

## Quick Start

1. Put the mission source in your Arma 3 profile `missions` folder, or pack it as a PBO for a server.
2. Open the mission in Eden Editor.
5. Launch in multiplayer preview or host/dedicated MP.
6. On a fresh start, the commander configures factions and world settings through the faction dialog.
7. On a loaded save, the saved mission config is restored and the faction dialog is skipped.

## Session Model

- FLO runs one active human side per session.
- The first connected `EAST` or `WEST` player locks `FLO_ActivePlayerSide`.
- Players on the opposite military side are moved to spectator.
- The `FreshStart` lobby parameter controls whether the mission loads saved progress or resets campaign state.

## Initialization Pipeline

All authoritative startup work runs on the server through [`Functions/Init/fn_initPhaseManager.sqf`](Functions/Init/fn_initPhaseManager.sqf).

| Phase | Name | Purpose |
|-------|------|---------|
| 0 | Save Detection | Detects existing save data and restores saved mission config when present |
| 1 | Mission Config | Waits for commander setup on fresh start, or restores saved handles and world settings |
| 2 | Factions | Loads faction scripts and builds the runtime faction catalog |
| 3 | Objectives | Indexes map objectives or restores saved objective state |
| 4 | Virtualization | Seeds or restores virtual groups, reserves, and registry state |
| 5 | Mission Systems | Starts GTN, logistics, routing, civilian, and client-facing systems |

Clients do not run parallel startup logic. They wait for `FLO_MissionReady` and then finalize local UI/state.

## Repository Layout

| Path | Purpose |
|------|---------|
| [`Functions/Init`](Functions/Init) | Server phase manager and client finalization |
| [`Functions/AI/GTN`](Functions/AI/GTN) | Commanders, world state, virtual combat, tasks, alerts, support assets |
| [`Functions/Virtualization`](Functions/Virtualization) | Group registry, spawn/deactivate lifecycle, routing, transport, seeding |
| [`Functions/Logistics`](Functions/Logistics) | Side resources, supply network, replacement dispatch, reserve replenishment |
| [`Functions/Objective`](Functions/Objective) | Objective indexing, ownership, graph links, markers |
| [`CUSTOM_PLAYER_FACTION.sqf`](CUSTOM_PLAYER_FACTION.sqf) | Player-side faction source data |
| [`CUSTOM_ENEMY_FACTION.sqf`](CUSTOM_ENEMY_FACTION.sqf) | Enemy-side faction source data |
| [`CUSTOM_CIVILIAN_FACTION.sqf`](CUSTOM_CIVILIAN_FACTION.sqf) | Civilian faction source data |

## Core Systems

### GTN Commanders

- FLO runs one GTN commander per military side.
- Commanders build maintained world state, assign strategic attack and defense tracks, publish player-facing commander intel, and request support assets.
- Virtual combat is cell- and cache-driven rather than full world simulation for every group every frame.
- Artillery and air support are only abstractly available while those assets are secure; overrun support assets can now be attrited by virtual combat like other vulnerable groups.

### Virtualization

- The virtual registry is the authoritative source for campaign groups.
- Groups unvirtualize near players and revirtualize when they safely leave the activation envelope.
- Orders, routes, attachments, mission locks, and saved runtime state are preserved across activation changes.
- Objective seeding and save backfill both use the same faction-template-driven spawn logic.

### Logistics and Supply

- Each side has a separate logistics network object.
- The network elects an HQ objective, grows an active supply-node chain, and dispatches replacements from controlled rear areas.
- Replacement creation uses group composition costs and current side resources instead of free respawns.
- Transport reserve pools are replenished separately from frontline combat groups.

### Routing

- Routing is currently water-aware, not road-graph based.
- Ground path resolution is effectively "direct if land, coarse detour if water."

### Transport

- Transport is a custom virtualization transport system.
- Active unloads are staged to stop ground carriers and land helicopters before dismount.
- Transport carriers can revirtualize after leaving player range; they are not held active forever by transport state.

### Player Intel Pickups

- Non-civilian spawned soldiers can carry battlefield intel items such as phones, secret files, and flash drives.
- Picking one up now reveals maintained enemy strategic intel instead of doing nothing.
- Phones prefer enemy commander target reveals, files prefer supply-node reveals, and flash drives prefer enemy HQ reveals.
- These reveals are temporary side-only GTN alert markers, not permanent omniscient map knowledge.

## Faction Customization

The authoritative customization entry points are the three mission-root faction files:

- [`CUSTOM_PLAYER_FACTION.sqf`](CUSTOM_PLAYER_FACTION.sqf)
- [`CUSTOM_ENEMY_FACTION.sqf`](CUSTOM_ENEMY_FACTION.sqf)
- [`CUSTOM_CIVILIAN_FACTION.sqf`](CUSTOM_CIVILIAN_FACTION.sqf)

Phase 2 reads those files and builds `FLO_FactionCatalog`, which then feeds commander pools, virtualization spawn pools, objective seeding, logistics replacements, and transport reserves.

### Objective Templates

Objective seeding is defined by subtype templates such as `capital`, `city`, `village`, `local`, `marine`, and `cluster`.

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

Physical strength per virtual group type is configured separately:

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

Use side-wide caps when a subtype template is allowed to request an asset, but you do not want one spawned at every eligible objective.

```sqf
West_Objective_Group_Type_Caps = [
    ["artillery", 5]
];

East_Objective_Group_Type_Caps = [
    ["artillery", 5]
];
```

These caps apply across all owned seeded objectives combined, not per objective.

### Transport Reserve Counts

Dedicated transport reserve pools are configured separately from frontline objective groups:

```sqf
West_Transport_Reserve_Ground_Count = 20;
West_Transport_Reserve_Air_Count = 10;

East_Transport_Reserve_Ground_Count = 20;
East_Transport_Reserve_Air_Count = 10;
```

### Important Save/Load Note

Changing faction files does not automatically reseed missing groups into an old save. Loaded saves restore saved virtual groups first. If you add new objective-template group types after a save already exists, you usually need either:

- a mission reset via the `FreshStart` lobby parameter, or
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

### Commander Mission Config

On a fresh start, the commander dialog sets and publishes:

- friendly, enemy, and civilian faction handles
- reputation and difficulty handles
- GTN attack coverage, defense coverage, tempo, force growth, and garrison handles
- enemy presence
- objective size threshold
- virtualization distance
- virtualization unit cap
- player start position

## License

FLO is distributed under the GNU General Public License v3.0. See [`LICENSE`](LICENSE).
