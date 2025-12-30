# FLO: Frontline Operations

**Current Version**: 2.0 - Alpha 5

A dynamic frontline operations mission for Arma 3 featuring intelligent AI commanders, virtualized forces, resource-based logistics, and persistent save states.

---

## Table of Contents

1. [Features](#features)
2. [Quick Start](#quick-start)
3. [Mission Setup](#mission-setup)
4. [Faction Configuration](#faction-configuration)
5. [Parameter Reference](#parameter-reference)
6. [Systems Overview](#systems-overview)
7. [Server Administration](#server-administration)
8. [Contributing](#contributing)

---

## Features

### Core Systems
- **Dynamic Frontline** - Evolving battlefield with OPFOR forces that defend, reinforce, and counterattack
- **Virtualization System** - Thousands of units simulated with minimal performance impact; only spawn when players approach
- **AI Commander (GTN)** - Goal Task Network-based AI that plans operations, calls fire support, and coordinates reinforcements
- **Persistent Save System** - Full mission state saved including objectives, resources, intel, and all virtual groups

### Combat & Operations
- **Virtual Artillery** - OPFOR artillery with shoot-and-scoot behavior, counterbattery avoidance
- **Air Tasking Orders** - AI Commander requests CAS and strike missions from available aircraft
- **Convoy Systems** - Supply convoys, HVT convoys, and convoy interdiction missions
- **Side Mission Framework** - Modular system for rescue, sabotage, intel gathering, and patrol missions

### Logistics & Resources
- **OPFOR Resource System** - Enemy forces consume resources to reinforce, resupply, and execute operations
- **Intel System** - BLUFOR intel generation based on controlled territory; affects notification visibility
- **Logistics Network** - Automated replacement of destroyed OPFOR groups using resource pools

### Player Features
- **FOB & OP Construction** - Build forward operating bases with full logistics support
- **Restricted Arsenal** - Configurable loadout restrictions (ACE compatible)
- **Civilian Relations** - Reputation system affecting intel and guerrilla activity

---

## Quick Start

1. **Download** the mission files and **unpack the PBO**
2. Place in: `Documents/Arma 3/missions/` (or your profile's missions folder)
3. Load in Eden Editor, place player units, and export/play
4. On first launch, the **Commander** selects factions and starting parameters

---

## Mission Setup

### Initialization Flow

The mission uses a phased initialization system:

| Phase | Name | Description |
|-------|------|-------------|
| 0 | Save Detection | Check for existing save, load config if present |
| 1 | Mission Config | Wait for Commander's faction dialog (or use saved config) |
| 2 | Factions | Load faction scripts (units, vehicles, groups) |
| 3 | Objectives | Index map locations or restore from save |
| 4 | Virtualization | Create virtual OPFOR groups at objectives |
| 5 | Mission Systems | Start AI Commander, side missions, logistics |

### Required Editor Setup

Follow these steps to set up the mission in Eden Editor:

1. **Open the Mission**
   - Launch Arma 3 and open Eden Editor
   - Load the FLO mission from your missions folder

2. **Place Player Units**
   - Place at least one playable unit (BLUFOR recommended)
   - Position units at a safe starting location (away from OPFOR objectives)

3. **Designate the Commander**
   - Select ONE player unit who will be the mission commander
   - In the unit's init field, add: `TheCommander = this;`
   - This player will configure factions and mission parameters at start

4. **Configure Respawn (Optional)**
   - Place a respawn marker named `respawn_west` for BLUFOR respawn
   - Or use the FOB system for dynamic respawn points

5. **Test the Mission**
   - Preview the mission in multiplayer mode (even for single player testing)
   - The Commander will see the faction selection dialog on first load

### Starting the Mission

- **Fresh Start**: Commander gets faction selection dialog to choose BLUFOR, OPFOR, and civilian factions
- **Saved Game**: Automatically loads previous state (controlled by lobby parameter)
- **Tip**: Use the "Reset" option in lobby parameters to force a fresh start

---

## Faction Configuration

### Quick Setup (Recommended for Communities)

Edit the three CUSTOM faction files in the mission root:

| File | Purpose |
|------|---------|
| `CUSTOM_ENEMY_FACTION.sqf` | OPFOR units, vehicles, and garrison configuration |
| `CUSTOM_PLAYER_FACTION.sqf` | BLUFOR units, vehicles, and purchasable assets |
| `CUSTOM_CIVILIAN_FACTION.sqf` | Civilian and guerrilla populations |

### Creating a New OPFOR Faction

```sqf
// === VEHICLE ARRAYS ===
East_Ground_Vehicles_Ambient = ["classname1", "classname2"];  // Patrol/ambient vehicles
East_Ground_Vehicles_Light = ["armed_mrap", "armed_lsv"];     // Light combat vehicles
East_Ground_Vehicles_Heavy = ["tank", "apc"];                  // Heavy armor
East_Ground_Transport = ["truck", "unarmed_mrap"];            // Transport vehicles
East_Air_Transport = ["transport_heli"];                       // Transport helicopters
East_Air_Heli = ["attack_heli"];                               // Attack helicopters
East_Air_Jet = ["fighter", "cas_plane"];                       // Fixed-wing aircraft
East_Ground_Artillery = ["howitzer"];                          // Artillery pieces
East_Air_Drone = ["uav"];                                      // Drones

// === INFANTRY ARRAYS ===
East_Units = [
    "rifleman", "rifleman", "rifleman",  // Higher frequency = more common
    "autorifleman", "autorifleman",
    "grenadier",
    "at_specialist",                      // Lower frequency = less common
    "aa_specialist"
];
East_Units_Officers = ["officer"];
East_FireObserver = ["forward_observer"];

// === GROUP DEFINITIONS ===
East_Groups = [
    (configfile >> "CfgGroups" >> "East" >> "FACTION" >> "Infantry" >> "GroupClass1"),
    (configfile >> "CfgGroups" >> "East" >> "FACTION" >> "Infantry" >> "GroupClass2")
];
```

### Garrison Configuration

Define how many groups spawn at each objective type:

```sqf
OPFOR_Objective_Groups = [
    // [objective_subtype, [[group_type, count], ...]]
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
    ]],
    ["village", [
        ["infantry", 3]
    ]],
    ["local", [           // Military bases, infrastructure
        ["infantry", 6],
        ["motorized", 2],
        ["mechanized", 1]
    ]],
    ["marine", [          // Ports, coastal facilities
        ["infantry", 3],
        ["motorized", 1]
    ]],
    ["cluster", [         // Auto-generated areas
        ["infantry", 2]
    ]]
];
```

### Group Size Configuration

```sqf
OPFOR_Group_Counts = [
    ["infantry", 10],      // Soldiers per infantry group
    ["motorized", 2],      // Vehicles per motorized group
    ["mechanized", 2],     // APCs per mechanized group
    ["armor", 2],          // Tanks per armor group
    ["helicopter", 1],     // Helicopters per air group
    ["jet", 1],            // Jets per air group
    ["artillery", 1]       // Guns per artillery group
];
```

### Performance Tuning

```sqf
// Objective density (fewer = better performance)
OPFOR_Objective_Size_Threshold = "Medium";  // "Small", "Medium", "Large", "Huge"

// Spawn distance (lower = better performance, less immersion)
OPFOR_Virtualization_Distance = 2000;  // Meters from player to spawn groups
```

### BLUFOR Faction Setup

Configure purchasable vehicles and their costs in `CUSTOM_PLAYER_FACTION.sqf`:

```sqf
F_Car_List = [
    ["B_LSV_01_unarmed_F", 25],    // [classname, cost]
    ["B_MRAP_01_F", 50]
];

F_Tank_List = [
    ["B_MBT_01_cannon_F", 500],
    ["B_MBT_01_TUSK_F", 650]
];

// Available categories:
// F_Bike_List, F_Car_List, F_MRAP_List, F_Truck_List
// F_APC_List, F_Tank_List, F_Artillery_List
// F_Heli_List, F_Heli_Gunship_List, F_Plane_List
// F_Boat_List, F_UAV_List, F_UGV_List
// F_Container_List, F_Turret_List, F_SAM_List
```

---

## Parameter Reference

### Lobby Parameters (description.ext)

| Parameter | Options | Default | Description |
|-----------|---------|---------|-------------|
| AutoSaveSwitch | Activate/Deactivate | Activate | Enable automatic saving |
| AutoSaveInterval | 5/10/20 minutes | 5 min | Time between auto-saves |
| FreshStart | Load/Reset | Load | Load saved progress or start fresh |
| RestrictedArsenal | Enable/Disable | Disable | Limit available arsenal items |
| RagequitBlocker | Enable/Disable | Disable | Block abort while unconscious |
| DisableSystemChat | Enable/Disable | Disable | Hide system messages |

### Runtime Configuration

**Server Restart Timer** (`Functions/Utilities/fn_heartBeat.sqf`):
```sqf
private _restartIntervalHours = 8;  // Hours between restarts
private _notificationThresholds = [60, 30, 15, 10, 5, 2, 1];  // Minutes before restart
```

**OPFOR Resources** (`Functions/Logistics/fn_opforResources.sqf`):
```sqf
["BASE_GENERATION", 10],      // Base resources per cycle
["GENERATION_INTERVAL", 300], // Seconds between generation
["EFFICIENCY_DECAY", 0.02],   // Decay rate per cycle
```

**Intel System** (`Functions/Logistics/fn_intelSystem.sqf`):
```sqf
["BASE_DECAY", 5],           // Intel lost per cycle
["UPDATE_INTERVAL", 300],    // Seconds between updates
// Intel per objective type:
["INTEL_VALUES", createHashMapFromArray [
    ["capital", 15],
    ["city", 10],
    ["marine", 8],
    ["local", 6],
    ["village", 3],
    ["cluster", 1]
]]
```

---

## Systems Overview

### Virtualization System

Groups exist in two states:
- **Virtual**: Position tracked, no physical entities, minimal performance cost
- **Active**: Physical units spawned when players within `OPFOR_Virtualization_Distance`

Groups automatically:
- Spawn when players approach
- Despawn when players leave (if not in combat)
- Preserve state (health, ammo, waypoints) between activations

### AI Commander (GTN)

The Goal Task Network system enables intelligent OPFOR behavior:

1. **World State** - Tracks threats, resources, objectives
2. **Goal Library** - Defines available actions (defend, reinforce, attack)
3. **Planner** - Decomposes goals into executable tasks
4. **Executor** - Runs primitive actions (move group, call artillery)
5. **Monitor** - Detects when replanning is needed

### Resource System

OPFOR resources affect:
- Group replacement cost
- Artillery availability
- Air support frequency
- Reinforcement speed

Resource efficiency decreases as:
- More objectives are lost
- Resources are spent rapidly
- Territory shrinks

### Logistics Network

Automatically replaces destroyed OPFOR groups:
- Monitors group composition vs. initial state
- Spawns replacements from map edges or rear objectives
- Prioritizes objectives under BLUFOR pressure
- Consumes OPFOR resources

---

## Server Administration

### Save System

Saves are stored in the server's profile namespace. Key data includes:
- Objective ownership and garrison state
- All virtual group positions and compositions
- Resource levels and efficiency ratings
- Intel levels and bonuses

### Restart Notifications

The heartbeat system notifies players before restart:
- Notifications at 60, 30, 15, 10, 5, 2, 1 minutes
- Urgency colors increase (white → yellow → orange → red)
- Based on server uptime, not wall clock

---

## Side Missions

Available mission templates:

| Mission | Description |
|---------|-------------|
| Pilot Rescue | Rescue downed pilot before OPFOR captures them |
| Squad Rescue | Extract stranded friendly squad |
| POW Rescue | Free prisoners from OPFOR facility |
| Convoy Interdiction | Destroy OPFOR supply convoy |
| HVT Convoy | Intercept high-value target convoy |
| Intel Gathering | Retrieve intel from enemy location |
| Patrol Sweep | Clear enemy patrol from area |

---

## Contributing

We welcome contributions! Here's how to get started:

### Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally
3. **Create a feature branch**: `git checkout -b feature/my-new-feature`
4. **Make your changes** following the code style guidelines below
5. **Test your changes** in-game
6. **Commit with clear messages**: `git commit -m "Add: New feature description"`
7. **Push to your fork**: `git push origin feature/my-new-feature`
8. **Submit a Pull Request** to the `Develop` branch

### Code Style Guidelines

- **Indentation**: Use tabs for SQF files
- **Variable Naming**:
  - Local variables: `_camelCase`
  - Global variables: `FLO_PascalCase`
  - Parameters: `_paramName`
- **Comments**: Add header comments to functions explaining purpose, parameters, and return values
- **File Headers**: Include faction name, mod requirements, and author in faction files

### Adding New Factions

#### Faction File Naming Convention

Format: `{side}_{faction}_{camo}_{mod}.sqf`

| Component | Description | Examples |
|-----------|-------------|----------|
| `side` | Game side | `blu` (BLUFOR), `opf` (OPFOR), `ind` (Independent), `civ` (Civilian) |
| `faction` | Military force | `NATO`, `US`, `BAF`, `GAF`, `CSAT`, `Russia` |
| `camo` | Camouflage variant | `Desert`, `Wood`, `Winter`, `Urban` |
| `mod` | Required mod(s) | `Vanilla`, `AEW`, `RHS`, `CUP`, `BW`, `FFAA` |

**Examples:**
- `blu_NATO_Desert_Vanilla.sqf` - Vanilla NATO in desert camo
- `blu_US_Wood_CUP_RHS.sqf` - US forces requiring CUP and RHS mods
- `opf_CSAT_Desert_Vanilla.sqf` - Vanilla CSAT in desert camo
- `blu_GAF_Wood_BW.sqf` - German Armed Forces with Bundeswehr mod

#### BLUFOR Faction Structure

```sqf
// ============================================================================
// FACTION NAME - SIDE (Required Mods)
// Description of the faction
// ============================================================================

// INFANTRY UNITS
F_Officer = "classname";
F_Assault_TL = "classname";
// ... other unit definitions

// SQUAD COMPOSITIONS
F_ASSLT_TEAM = [F_Assault_TL, F_Assault_Eod, F_Assault_AT, ...];
F_RCN_TEAM = [F_Recon_TL, F_Recon_AT, F_Recon_Mrk, ...];

// VEHICLE LISTS - Format: [[classname, price], ...]
F_Car_List = [
    ["classname", 25],
    ["classname", 50]
];
```

#### OPFOR Faction Structure

See the `CUSTOM_ENEMY_FACTION.sqf` template for the complete structure including:
- Vehicle arrays by type
- Infantry unit arrays
- Group definitions
- Garrison configuration

### Testing Your Changes

1. **Load in Eden Editor** and preview the mission
2. **Test faction selection** - Verify your faction appears in the dialog
3. **Test unit spawning** - Check that units spawn correctly at objectives
4. **Test vehicle purchasing** - Verify vehicles can be purchased with correct prices
5. **Test with required mods** - Ensure the faction works with its required mods

### Pull Request Guidelines

- Target the `Develop` branch, not `Release`
- Include a clear description of changes
- List any new mod dependencies
- Include screenshots for visual changes
- Ensure no merge conflicts

---

## License

GNU General Public License v3.0

## Credits

- Created by **Frontline Operations Development Group**
- Special thanks to our early supporters and community contributors
