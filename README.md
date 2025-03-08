# FLO: Frontline Operations - Altis

**Current Version**: 1.5.1

A dynamic frontline operations mission for Arma 3 that creates an evolving battlefield with intelligent OPFOR forces, logistics systems, and garrison management.

## Features
- Dynamic frontline system with intelligent OPFOR forces
- Advanced logistics and supply network
- Garrison management system
- Intel gathering and radio tower control mechanics
- Automated resource management for OPFOR forces
- Dynamic vehicle spawning system
- Customizable faction loadouts and equipment

## Setup Instructions

### Basic Mission Setup
1. Download the mission files (MAKE SURE YOU UNPACK THE PBO)
2. Place in your Arma 3 missions folder: `Documents/Arma 3 (Or Other Profile)/missions/`
3. Load the mission in the Arma 3 editor to customize settings

### Faction Customization

#### OPFOR Forces Setup
- There are two ways to make factions. 
1. For people using it for individual Unit/Community Usage. I recommend using the files:
- `CUSTOM_CIVILIAN_FACTION, CUSTOM_FRIENDLY_FACTION, CUSTOM_ENEMY_FACTION`
2. Create a new faction file in `Scripts/factions/` (e.g., `opf_custom.sqf`) with the following structure. This is useful for people wanting to contribute to the Github by adding new factions that be used by everyone.

```sqf
// Vehicle Arrays
East_Ground_Vehicles_Light = [
    "O_MRAP_02_F",
    "O_MRAP_02_hmg_F"
];

East_Ground_Vehicles_Heavy = [
    "O_MBT_02_cannon_F",
    "O_APC_Tracked_02_cannon_F"
];

East_Air_Heli = [
    "O_Heli_Attack_02_F",
    "O_Heli_Light_02_F"
];

// Infantry Arrays
East_Units = [
    "O_Soldier_F",
    "O_Soldier_GL_F",
    "O_Soldier_AR_F"
];

// ... other arrays
```

#### CAS Aircraft Pylon Setup
To configure CAS aircraft pylons, find the Function called fn_AirSupport.sqf

```sqf
private _pylonMags = [
    "PylonRack_4Rnd_LG_scalpel",  // SCALPEL missiles
    "PylonRack_4Rnd_ACE_Hellfire_AGM114K",  // AGM-114K Hellfire
    "PylonRack_4Rnd_ACE_Hellfire_AGM114N",  // AGM-114N Hellfire
    "PylonRack_12Rnd_ACE_DAGR", // DAGR missiles 12x
    "PylonRack_24Rnd_ACE_DAGR", // DAGR missiles 24x
    "ace_hot_3_PylonRack_3Rnd", // HOT missiles 3x
    "ace_hot_3_PylonRack_4Rnd" // HOT missiles 4x
];
```

#### Artillery Configuration
Configure artillery munitions in fn_ArtilleryPrep.sqf

```sqf
private _artilleryMagazines = [
    "32Rnd_155mm_Mo_shells_O",
    "2Rnd_155mm_Mo_Cluster_O"
];
```

### Map Configuration

The mission uses both automatic and manual marker placement systems for setting up the battlefield. You have two options:

#### Option 1: Automatic Marker System
The mission includes an automatic marker system (`init_Markers.sqf`) that:
1. Places markers based on map features and objects
2. Scales marker density based on `EnemyPrec` parameter
3. Automatically identifies and marks:
   - Radio Towers (`loc_Transmitter`) near `LocationEvacPoint_F`
   - Support locations (`o_support`) near factories and military structures
   - Installations (`o_installation`, `n_installation`) in cities and capitals
   - Barracks (`loc_Ruin`) near military buildings
   - Radar sites (`loc_Power`) near radar structures
   - AA positions (`o_antiair`) on high ground
   - Infantry positions (`o_inf`) in villages

Key features of the automatic system:
- Centers around `LocationEvacPoint_F` objects
- Uses terrain features like mountains for placement
- Maintains minimum distances between markers
- Adjusts marker density based on map size
- Automatically places military infrastructure

#### Map Conversion Tips
When converting the mission to a new map:

#### 1. Adjust Enemy Presence:
- Default scale is based on map size: `worldSize / 2` (This determines how dense the map will be with objectives besides the Dialog Menu % of Map Playable.)
- Edit `EnemyPrec` parameter to control overall enemy density (higher values = fewer markers)

#### 2. Infrastructure and Marker System Setup
The mission uses `init_Markers.sqf` to automatically place strategic objectives based on map features and editor-placed objects.

##### Location Marker Objects
Place the following objects in the editor to help the marker system create objectives:

| Object Type | Purpose | Marker Type | Notes |
|-------------|---------|-------------|-------|
| `LocationEvacPoint_F` | Core distribution points | Various | Main reference points for all marker generation |
| `LocationBase_F` | Military bases | `n_support` | Primary military installations |
| `LocationFOB_F` | Forward Operating Bases | `o_support` | Converted to enemy outposts |
| `LocationResupplyPoint_F` | Factory/Supply points | `o_support` | Industrial/factory areas |
| `LocationCamp_F` | Barracks | `loc_Ruin` | Military barracks areas |
| `LocationCityCapital_F` | Capital cities | `n_installation` | Major urban centers |
| `LocationCity_F` | Cities | `o_installation` | Urban centers |
| `LocationVillage_F` | Villages | `o_inf` | Insurgent infantry positions |

##### Using Variable Names on Logic Objects
You can also use Logic objects with specific variable names:

| Variable Name | Creates | Example Use |
|---------------|---------|-------------|
| `"RadioTower"` | Radio towers | Place on high terrain |
| `"ResupplyPoint"` | Supply points | Place in industrial areas |
| `"FOB"` | Forward bases | Place in strategic locations |
| `"BaseLocation"` | Military bases | Alternative to LocationBase_F |
| `"Capital"` | Capital markers | Alternative to LocationCityCapital_F |
| `"City"` | City markers | Alternative to LocationCity_F |
| `"Village"` | Village markers | Alternative to LocationVillage_F |
| `"Barracks"` | Barracks markers | Place near military areas |
| `"RadarS"` | Radar stations | Place on high terrain |
| `"AASite"` | Anti-Air positions | Place on mountaintops |

##### Physical Objects Detection and Variable System
The script primarily relies on Location objects and variables rather than detecting physical structures. Here's a more accurate explanation of how it works:

1. **Location Objects**: The script first tries to find specific location type objects like `LocationBase_F`, `LocationCity_F`, etc.

2. **Variable-Tagged Objects**: If location objects aren't found, it looks for objects (often Logic) with specific variable names (e.g., "RadioTower", "FOB")

3. **Fallback Mechanism**: If neither of these are found, for most marker types it will:
   - Find a nearby Mount location 
   - Create a marker there
   - For radio towers specifically, it will also create a physical tower object

The script does **not** automatically detect physical structures like barracks buildings or radar installations by default. Instead, you need to:
- Place the appropriate location objects (`LocationBase_F`, etc.)
- OR add variables to objects (including Logic objects)
- OR let the script use its fallback mechanisms (generally placing on mountains)

For example, placing a `Land_Radar_F` by itself won't automatically create a radar marker unless you:
- Add the "RadarS" variable to it, OR
- Place a `LocationEvacPoint_F` nearby that will use it as a reference point

##### Best Practices for Marker Setup

1. **Start with LocationEvacPoint_F objects:**
   - Place these at key strategic points around the map
   - These act as reference points for placing other markers
   - Should be distributed evenly, avoid clustering

2. **Add specialized location objects:**
   - Place `LocationBase_F` at main military installations
   - Place `LocationCity_F` or `LocationCityCapital_F` at urban centers
   - Place `LocationFOB_F` at strategic minor military points
   - Place `LocationCamp_F` for smaller military installations

3. **Add physical structures:**
   - Place radio towers on high terrain
   - Add military structures to give the map more detail
   - Use terrain features to your advantage (mountains for AA, etc.)

4. **Fine-tune with Logic markers:**
   - Use Logic objects with variables to add specific markers
   - Useful for adding exact positions that don't correspond to physical structures

5. **Adjust safe positioning for water maps:**
   - For maps with lots of water, the script uses `BIS_fnc_findSafePos` to ensure markers are on land
   - The default safe radius is set, but can be adjusted for specific map topography

##### Marker Density Control

The script automatically scales marker density based on:
- `EnemyPrec` global parameter (accessible in mission settings)
- Map size (calculated from `worldSize`)
- Division factors for each marker type

For adding more markers of a specific type, you can:
1. Place more objects of the corresponding type
2. Adjust the division factor in the script (smaller = more markers)
3. Reduce the `EnemyPrec` parameter

##### Troubleshooting Common Issues

- **No markers appearing**: Ensure you have placed `LocationEvacPoint_F` objects
- **Markers in water**: Check the `_useSafePos` parameter and increase `_safeRadius`
- **Too many/few markers**: Adjust `EnemyPrec` or place more/fewer location objects
- **Missing specific marker types**: Ensure you've placed the corresponding location objects

#### 3. Spawn Positions:
- Spawn Positions will be selected when you first join the mission as the Company Commander. You will be prompted with the Dialog Menu in which you can 
select Faction, Starting Aggression levels, Starting Civilian Relations, and More.

## Customization Tips

### Resource System
- Adjust OPFOR resource generation in `Functions/Logistics/fn_opforResources.sqf`

### Intel System
- Modify intel decay rates and bonuses in `Functions/Logistics/fn_intelSystem.sqf`
- Adjust radio tower benefits in the intel system

### Performance Settings
- Configure view distance in `initServer.sqf`
- Adjust dynamic spawning ranges in garrison manager

### Arsenal Customization
The mission uses a restricted arsenal system (`fn_restrictedArsenal.sqf`) that works with both ACE and vanilla arsenals. You can customize available equipment in the following categories:

#### Weapons and Attachments
```sqf
// Modify these arrays in fn_restrictedArsenal.sqf
private _rifles = [
    "arifle_MX_F",
    "arifle_MXC_F",
    // ... add or remove weapons
];

private _launchers = [
    "launch_B_Titan_F",
    // ... add or remove launchers
];

private _attachments = [
    "optic_Hamr",
    "acc_flashlight",
    // ... add or remove attachments
];
```

#### Equipment
```sqf
private _uniforms = [
    "U_B_CombatUniform_mcam",
    // ... add or remove uniforms
];

private _vests = [
    "V_PlateCarrier1_rgr",
    // ... add or remove vests
];

private _headgear = [
    "H_HelmetB",
    // ... add or remove headgear
];

private _backpacks = [
    "B_AssaultPack_mcamo",
    // ... add or remove backpacks
];
```

#### Items and Equipment
```sqf
private _medicalItems = [
    "kat_AFAK",
    // ... add or remove medical items
];

private _toolItems = [
    "ACE_CableTie",
    // ... add or remove tools
];

private _navigationItems = [
    "ItemMap",
    "ItemGPS",
    // ... add or remove navigation items
];
```

#### Ammunition and Explosives
```sqf
private _magazines = [
    "30Rnd_65x39_caseless_mag",
    // ... add or remove magazines
];

private _grenades = [
    "HandGrenade",
    "SmokeShell",
    // ... add or remove grenades
];
```

#### Implementation Notes:
1. The arsenal system automatically:
   - Works with both ACE and vanilla arsenals
   - Applies to all arsenal boxes, FOBs, and OPs
   - Updates dynamically when new FOBs/OPs are created

2. Mod Compatibility:
   - Supports ACE items and medical equipment
   - Compatible with TFAR radio systems
   - Works with KAT Advanced Medical items
   - Supports custom mod items (just add their classnames)

3. To add new items:
   - Find the appropriate category in `fn_restrictedArsenal.sqf`
   - Add the classname to the corresponding array
   - Items will be available in all arsenals automatically

4. Performance Optimization:
   - Arsenal restrictions are applied only once per box
   - Uses efficient event handlers to manage updates
   - Prevents duplicate initialization

## Contributing

Feel free to contribute improvements or report issues on our GitHub repository.

## License

This mission is available under the GNU GENERAL PUBLIC LICENSE.

## Credits

- Created by Frontline Operations Development Group
- Special thanks to the Early Supporters for being there for literal years of support.
