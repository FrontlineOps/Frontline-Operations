/*
 * Function: FLO_fnc_initPhase2_Factions
 * Author: Frontline Operations Development Group
 * Description:
 *   Phase 2: Load custom or auto-discovered faction data on the server.
 *
 * Arguments: None
 * Returns: Boolean - True if factions loaded successfully
 */

if (!isServer) exitWith { false };

diag_log "[FLO_INIT_P2] Loading faction definitions...";

// Check if already loaded (saved game)
private _hasSavedFactionState = !isNil "F_Init" && {F_Init}
    && {!isNil "FLO_FactionCatalog"}
    && {(!isNil "East_Ground_Infantry") || {!isNil "East_Groups"} || {!isNil "East_Units"}}
    && {(!isNil "East_Ground_Motorized") || {!isNil "East_Ground_Vehicles_Light"}}
    && {!isNil "East_Air_Transport"};

if (_hasSavedFactionState) exitWith {
    diag_log "[FLO_INIT_P2] Factions already loaded (saved game)";
    true
};

if (!isNil "F_Init" && {F_Init}) then {
    diag_log "[FLO_INIT_P2] Factions already loaded (saved game)";
    diag_log "[FLO_INIT_P2] WARNING: Faction state incomplete despite F_Init=true, reloading...";
};

// Ensure handles exist
if (isNil "FLO_FriendlyHandle" || isNil "FLO_EnemyHandle" || isNil "FLO_CivilianHandle") exitWith {
    FLO_InitError = "Faction handles not set - Phase 1 may have failed";
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P2] ERROR: %1", FLO_InitError];
    false
};

// Set F_Init to false before loading
F_Init = false;
publicVariable "F_Init";

private _loadedOk = true;

// Load friendly faction
private _bluHandle = FLO_FriendlyHandle;
private _bluFaction = _bluHandle get "name";
_loadedOk = [_bluHandle, "friendly"] call FLO_fnc_initLoadFactionSelection;
if (!_loadedOk) exitWith {
    FLO_InitError = format ["Friendly faction loading failed: %1", _bluFaction];
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P2] ERROR: %1", FLO_InitError];
    false
};

// Load enemy faction
private _opfHandle = FLO_EnemyHandle;
private _opfFaction = _opfHandle get "name";
_loadedOk = [_opfHandle, "enemy"] call FLO_fnc_initLoadFactionSelection;
if (!_loadedOk) exitWith {
    FLO_InitError = format ["Enemy faction loading failed: %1", _opfFaction];
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P2] ERROR: %1", FLO_InitError];
    false
};

// Load civilian faction
private _civHandle = FLO_CivilianHandle;
private _civFaction = _civHandle get "name";
_loadedOk = [_civHandle, "civilian"] call FLO_fnc_initLoadFactionSelection;
if (!_loadedOk) exitWith {
    FLO_InitError = format ["Civilian faction loading failed: %1", _civFaction];
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P2] ERROR: %1", FLO_InitError];
    false
};

// Verify critical arrays exist
private _missingArrays = [];
if (isNil "East_Air_Transport") then {
    _missingArrays pushBack "East_Air_Transport";
};
if (isNil "East_Ground_Infantry" && {isNil "East_Groups"} && {isNil "East_Units"}) then {
    _missingArrays pushBack "East_Ground_Infantry/East_Groups/East_Units";
};
if (isNil "East_Ground_Motorized" && {isNil "East_Ground_Vehicles_Light"}) then {
    _missingArrays pushBack "East_Ground_Motorized/East_Ground_Vehicles_Light";
};

if (_missingArrays isNotEqualTo []) exitWith {
    FLO_InitError = format ["Faction loading failed - missing arrays: %1", _missingArrays];
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P2] ERROR: %1", FLO_InitError];
    false
};

// ============================================================================
// Broadcast faction data to clients for client-side catalog and UI systems.
// ============================================================================

// Player faction unit types (needed for permission checks)
private _playerFactionVars = [
    "F_Officer", "F_Assault_Eng", "F_Assault_TL", "F_Assault_SL", "F_Assault_Eod",
    "F_Assault_Mrk", "F_Assault_AT", "F_Assault_Amm", "F_Assault_Mg", "F_Assault_Med",
    "F_Assault_Uav", "F_Recon_Snp", "F_Recon_Sct", "F_Recon_TL", "F_Recon_Mrk",
    "F_Recon_AT", "F_Recon_Mg", "F_Recon_Eod", "F_Recon_Med", "F_Recon_Eng",
    "F_Diver_TL", "F_Diver_Eod", "F_Diver_Rfl"
];

// Player faction building types
private _buildingVars = ["FLO_FactionFobType", "FLO_FactionFobTerminalType", "FLO_FactionCopType", "FLO_FactionCopTerminalType", "FLO_FactionRadar"];

// Store vehicle and equipment lists
private _requestMenuVars = [
    "F_Bike_List", "F_Car_List", "F_MRAP_List", "F_Truck_List",
    "F_Truck_Construction_List", "F_Truck_Ammo_List", "F_Truck_Respawn_List",
    "F_APC_List", "F_Tank_List", "F_Artillery_List",
    "F_Heli_List", "F_Heli_Respawn_List", "F_Heli_Gunship_List",
    "F_Plane_List", "F_Boat_List", "F_UAV_List", "F_UGV_List",
    "F_Container_List", "F_Turret_List", "F_SAM_List"
];

// Squad compositions (for infantry requests)
private _squadCompVars = [
    "F_ASSLT_ENG", "F_ASSLT_TEAM", "F_ASSLT_SQD",
    "F_SNP_TEAM", "F_RCN_TEAM", "F_RCN_SQD",
    "F_DVR_TEAM", "F_OFFICER_TEAM"
];

// Civilian arrays
private _civilianVars = ["CivVehArray", "CivMenArray"];

// Broadcast all faction variables to clients
private _allVarsToPublish = _playerFactionVars + _buildingVars + _requestMenuVars + _squadCompVars + _civilianVars;
private _publishedCount = 0;

{
    if (!isNil _x) then {
        publicVariable _x;
        _publishedCount = _publishedCount + 1;
    };
} forEach _allVarsToPublish;

diag_log format ["[FLO_INIT_P2] Broadcast %1 faction variables to clients", _publishedCount];

// ============================================================================
// SIDE CONTEXT AND FACTION CATALOG
// ============================================================================

FLO_MissionSides = [east, west];
publicVariable "FLO_MissionSides";

if (isNil "FLO_ActivePlayerSide") then {
    FLO_ActivePlayerSide = sideUnknown;
    publicVariable "FLO_ActivePlayerSide";
};

private _eastFactionCompositionDefaults = [_opfHandle, "OPFOR"] call FLO_fnc_factionBuildCompositionDefaultsHandle;
private _westFactionCompositionDefaults = [_bluHandle, "BLUFOR"] call FLO_fnc_factionBuildCompositionDefaultsHandle;

private _eastFactionCompositionHandle = if ("eastFactionTuningHandle" in FLO_MissionConfig) then {
    FLO_MissionConfig get "eastFactionTuningHandle"
} else {
    _eastFactionCompositionDefaults
};

private _westFactionCompositionHandle = if ("westFactionTuningHandle" in FLO_MissionConfig) then {
    FLO_MissionConfig get "westFactionTuningHandle"
} else {
    _westFactionCompositionDefaults
};

private _westInfantryVars = [
    "F_Officer", "F_Assault_Eng", "F_Assault_TL", "F_Assault_SL", "F_Assault_Eod",
    "F_Assault_Mrk", "F_Assault_AT", "F_Assault_Amm", "F_Assault_Mg", "F_Assault_Med",
    "F_Assault_Uav"
];
private _westSpecOpsVars = [
    "F_Recon_Snp", "F_Recon_Sct", "F_Recon_TL", "F_Recon_Mrk",
    "F_Recon_AT", "F_Recon_Mg", "F_Recon_Eod", "F_Recon_Med", "F_Recon_Eng",
    "F_Diver_TL", "F_Diver_Eod", "F_Diver_Rfl"
];

private _westLegacyInfantry = [_westInfantryVars] call FLO_fnc_factionCollectDirectUnitVariables;
private _westLegacySpecOps = [_westSpecOpsVars] call FLO_fnc_factionCollectDirectUnitVariables;

private _eastInfantrySource = if (!isNil "East_Ground_Infantry") then {
    East_Ground_Infantry
} else {
    private _legacy = [];
    if (!isNil "East_Groups") then {
        _legacy append East_Groups;
    };
    if (!isNil "East_Units") then {
        _legacy append East_Units;
    };
    _legacy
};
private _eastSpecOpsSource = if (!isNil "East_Ground_SpecOps") then {
    East_Ground_SpecOps
} else {
    []
};
private _westInfantrySource = if (!isNil "West_Ground_Infantry") then {
    West_Ground_Infantry
} else {
    _westLegacyInfantry
};
private _westSpecOpsSource = if (!isNil "West_Ground_SpecOps") then {
    West_Ground_SpecOps
} else {
    _westLegacySpecOps
};

private _eastInfantryPools = [_eastInfantrySource] call FLO_fnc_initFactionSplitMixedInfantryPool;
_eastInfantryPools params ["_eastInfantryGroups", "_eastInfantryUnits"];
private _eastSpecOpsPools = [_eastSpecOpsSource] call FLO_fnc_initFactionSplitMixedInfantryPool;
_eastSpecOpsPools params ["_eastSpecOpsGroups", "_eastSpecOpsUnits"];
private _westInfantryPools = [_westInfantrySource] call FLO_fnc_initFactionSplitMixedInfantryPool;
_westInfantryPools params ["_westInfantryGroups", "_westInfantryUnits"];
private _westSpecOpsPools = [_westSpecOpsSource] call FLO_fnc_initFactionSplitMixedInfantryPool;
_westSpecOpsPools params ["_westSpecOpsGroups", "_westSpecOpsUnits"];

private _eastGroundMotorized = [(if (!isNil "East_Ground_Motorized") then { East_Ground_Motorized } else { if (!isNil "East_Ground_Vehicles_Light") then { East_Ground_Vehicles_Light } else { [] } })] call FLO_fnc_factionExtractVehicleClasses;
private _eastGroundMechanized = [(if (!isNil "East_Ground_Mechanized") then { East_Ground_Mechanized } else { if (!isNil "East_Ground_Vehicles_Heavy") then { East_Ground_Vehicles_Heavy } else { [] } })] call FLO_fnc_factionExtractVehicleClasses;
private _eastGroundArmor = [(if (!isNil "East_Ground_Armor") then { East_Ground_Armor } else { if (!isNil "East_Ground_Vehicles_Heavy") then { East_Ground_Vehicles_Heavy } else { [] } })] call FLO_fnc_factionExtractVehicleClasses;
private _eastGroundTransport = [(if (!isNil "East_Ground_Transport") then { East_Ground_Transport } else { [] })] call FLO_fnc_factionExtractVehicleClasses;
private _eastGroundArtillery = [(if (!isNil "East_Ground_Artillery") then { East_Ground_Artillery } else { [] })] call FLO_fnc_factionExtractVehicleClasses;
private _eastAirHeli = [(if (!isNil "East_Air_Heli") then { East_Air_Heli } else { [] })] call FLO_fnc_factionExtractVehicleClasses;
private _eastAirJet = [(if (!isNil "East_Air_Jet") then { East_Air_Jet } else { [] })] call FLO_fnc_factionExtractVehicleClasses;
private _eastAirTransport = [(if (!isNil "East_Air_Transport") then { East_Air_Transport } else { [] })] call FLO_fnc_factionExtractVehicleClasses;
private _eastAirDrone = [(if (!isNil "East_Air_Drone") then { East_Air_Drone } else { [] })] call FLO_fnc_factionExtractVehicleClasses;
private _eastGroundDrone = [(if (!isNil "East_Ground_Drone") then { East_Ground_Drone } else { [] })] call FLO_fnc_factionExtractVehicleClasses;
private _eastMobileAA = [(if (!isNil "East_Mobile_AA") then { East_Mobile_AA } else { [] })] call FLO_fnc_factionExtractVehicleClasses;
private _eastStaticAA = [(if (!isNil "East_Static_AA") then { East_Static_AA } else { [] })] call FLO_fnc_factionExtractVehicleClasses;
private _eastBoat = [(if (!isNil "East_Boat") then { East_Boat } else { [] })] call FLO_fnc_factionExtractVehicleClasses;
private _eastRadar = [(if (!isNil "East_Radar") then { East_Radar } else { [] })] call FLO_fnc_factionExtractVehicleClasses;

private _westGroundMotorized = if (!isNil "West_Ground_Motorized") then {
    [West_Ground_Motorized] call FLO_fnc_factionExtractVehicleClasses
} else {
    [["F_Car_List", "F_MRAP_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables
};
private _westGroundMechanized = if (!isNil "West_Ground_Mechanized") then {
    [West_Ground_Mechanized] call FLO_fnc_factionExtractVehicleClasses
} else {
    [["F_APC_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables
};
private _westGroundArmor = if (!isNil "West_Ground_Armor") then {
    [West_Ground_Armor] call FLO_fnc_factionExtractVehicleClasses
} else {
    [["F_Tank_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables
};
private _westGroundTransport = if (!isNil "West_Ground_Transport") then {
    [West_Ground_Transport] call FLO_fnc_factionExtractVehicleClasses
} else {
    [["F_Truck_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables
};
private _westGroundArtillery = if (!isNil "West_Ground_Artillery") then {
    [West_Ground_Artillery] call FLO_fnc_factionExtractVehicleClasses
} else {
    [["F_Artillery_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables
};
private _westAirHeli = if (!isNil "West_Air_Heli") then {
    [West_Air_Heli] call FLO_fnc_factionExtractVehicleClasses
} else {
    private _legacy = [["F_Heli_Gunship_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables;
    if (_legacy isEqualTo []) then {
        _legacy = [["F_Heli_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables;
    };
    _legacy
};
private _westAirJet = if (!isNil "West_Air_Jet") then {
    [West_Air_Jet] call FLO_fnc_factionExtractVehicleClasses
} else {
    [["F_Plane_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables
};
private _westAirTransport = if (!isNil "West_Air_Transport") then {
    [West_Air_Transport] call FLO_fnc_factionExtractVehicleClasses
} else {
    [["F_Heli_List", "F_Heli_Respawn_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables
};
private _westAirDrone = if (!isNil "West_Air_Drone") then {
    [West_Air_Drone] call FLO_fnc_factionExtractVehicleClasses
} else {
    [["F_UAV_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables
};
private _westGroundDrone = if (!isNil "West_Ground_Drone") then {
    [West_Ground_Drone] call FLO_fnc_factionExtractVehicleClasses
} else {
    [["F_UGV_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables
};
private _westMobileAA = if (!isNil "West_Mobile_AA") then {
    [West_Mobile_AA] call FLO_fnc_factionExtractVehicleClasses
} else {
    [["F_APC_List", "F_Tank_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables
};
private _westStaticAA = if (!isNil "West_Static_AA") then {
    [West_Static_AA] call FLO_fnc_factionExtractVehicleClasses
} else {
    [["F_SAM_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables
};
private _westRadar = if (!isNil "West_Radar") then {
    [West_Radar] call FLO_fnc_factionExtractVehicleClasses
} else {
    if (!isNil "FLO_FactionRadar" && {FLO_FactionRadar isEqualType ""}) then { [FLO_FactionRadar] } else { [] }
};
private _westBoat = if (!isNil "West_Boat") then {
    [West_Boat] call FLO_fnc_factionExtractVehicleClasses
} else {
    [["F_Boat_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables
};
private _westLogisticsConstruction = [["F_Truck_Construction_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables;
private _westLogisticsAmmo = [["F_Truck_Ammo_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables;
private _westLogisticsRespawn = [["F_Truck_Respawn_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables;
private _westContainers = [["F_Container_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables;

private _eastOfficerUnits = if (!isNil "East_FireObserver") then {
    ["East_FireObserver"] call FLO_fnc_factionGetVariableArray
} else {
    if (_eastInfantryUnits isNotEqualTo []) then { [_eastInfantryUnits select 0] } else { [] }
};
private _westOfficerUnits = if (!isNil "F_Officer") then {
    [F_Officer]
} else {
    if (_westInfantryUnits isNotEqualTo []) then { [_westInfantryUnits select 0] } else { [] }
};

diag_log format [
    "[FLO_INIT_P2] WEST pool sizes: infUnits=%1 specOpsUnits=%2 motorized=%3 mechanized=%4 armor=%5 transport=%6 artillery=%7 heli=%8 airTransport=%9 jet=%10 mobileAA=%11 staticAA=%12 radar=%13 uav=%14 ugv=%15 boat=%16",
    count _westInfantryUnits,
    count _westSpecOpsUnits,
    count _westGroundMotorized,
    count _westGroundMechanized,
    count _westGroundArmor,
    count _westGroundTransport,
    count _westGroundArtillery,
    count _westAirHeli,
    count _westAirTransport,
    count _westAirJet,
    count _westMobileAA,
    count _westStaticAA,
    count _westRadar,
    count _westAirDrone,
    count _westGroundDrone,
    count _westBoat
];

private _eastCatalog = createHashMapFromArray [
    ["groups", _eastInfantryGroups],
    ["units", _eastInfantryUnits],
    ["officers", _eastOfficerUnits],
    ["groundInfantryGroups", _eastInfantryGroups],
    ["groundInfantryUnits", _eastInfantryUnits],
    ["groundSpecOpsGroups", _eastSpecOpsGroups],
    ["groundSpecOpsUnits", _eastSpecOpsUnits],
    ["groundMotorized", _eastGroundMotorized],
    ["groundMechanized", _eastGroundMechanized],
    ["groundArmor", _eastGroundArmor],
    ["groundTransport", _eastGroundTransport],
    ["transportReserveGroundCount", _eastFactionCompositionDefaults get "transportReserveGroundCount"],
    ["groundArtillery", _eastGroundArtillery],
    ["airHeli", _eastAirHeli],
    ["airJet", _eastAirJet],
    ["airTransport", _eastAirTransport],
    ["transportReserveAirCount", _eastFactionCompositionDefaults get "transportReserveAirCount"],
    ["airDrone", _eastAirDrone],
    ["groundDrone", _eastGroundDrone],
    ["mobileAA", _eastMobileAA],
    ["staticAA", _eastStaticAA],
    ["boat", _eastBoat],
    ["radar", _eastRadar],
    ["objectiveGroups", _eastFactionCompositionDefaults get "objectiveGroups"],
    ["objectiveGroupTypeCaps", _eastFactionCompositionDefaults get "objectiveGroupTypeCaps"],
    ["groupCounts", _eastFactionCompositionDefaults get "groupCounts"]
];

private _westCatalog = createHashMapFromArray [
    ["groups", _westInfantryGroups],
    ["units", _westInfantryUnits],
    ["officers", _westOfficerUnits],
    ["groundInfantryGroups", _westInfantryGroups],
    ["groundInfantryUnits", _westInfantryUnits],
    ["groundSpecOpsGroups", _westSpecOpsGroups],
    ["groundSpecOpsUnits", _westSpecOpsUnits],
    ["groundMotorized", _westGroundMotorized],
    ["groundMechanized", _westGroundMechanized],
    ["groundArmor", _westGroundArmor],
    ["groundTransport", _westGroundTransport],
    ["transportReserveGroundCount", _westFactionCompositionDefaults get "transportReserveGroundCount"],
    ["groundArtillery", _westGroundArtillery],
    ["airHeli", _westAirHeli],
    ["airJet", _westAirJet],
    ["airTransport", _westAirTransport],
    ["transportReserveAirCount", _westFactionCompositionDefaults get "transportReserveAirCount"],
    ["airDrone", _westAirDrone],
    ["groundDrone", _westGroundDrone],
    ["mobileAA", _westMobileAA],
    ["staticAA", _westStaticAA],
    ["boat", _westBoat],
    ["logisticsConstruction", _westLogisticsConstruction],
    ["logisticsAmmo", _westLogisticsAmmo],
    ["logisticsRespawn", _westLogisticsRespawn],
    ["containers", _westContainers],
    ["radar", _westRadar],
    ["objectiveGroups", _westFactionCompositionDefaults get "objectiveGroups"],
    ["objectiveGroupTypeCaps", _westFactionCompositionDefaults get "objectiveGroupTypeCaps"],
    ["groupCounts", _westFactionCompositionDefaults get "groupCounts"]
];

[_eastCatalog, _eastFactionCompositionHandle, "OPFOR"] call FLO_fnc_factionApplyTuningOverrides;
[_westCatalog, _westFactionCompositionHandle, "BLUFOR"] call FLO_fnc_factionApplyTuningOverrides;

FLO_FactionCatalog = createHashMapFromArray [
    ["EAST", _eastCatalog],
    ["WEST", _westCatalog]
];
publicVariable "FLO_FactionCatalog";

// Mark factions as loaded
F_Init = true;
publicVariable "F_Init";

diag_log format ["[FLO_INIT_P2] Factions loaded successfully: BLU=%1, OPF=%2, CIV=%3", _bluFaction, _opfFaction, _civFaction];
true
