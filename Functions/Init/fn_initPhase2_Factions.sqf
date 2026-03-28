/*
 * Function: FLO_fnc_initPhase2_Factions
 * Author: Frontline Operations Development Group
 * Description:
 *   Phase 2: Load faction scripts on the server.
 *   This runs init_groups.sqf logic directly on the server.
 *
 * Arguments: None
 * Returns: Boolean - True if factions loaded successfully
 */

if (!isServer) exitWith { false };

diag_log "[FLO_INIT_P2] Loading faction scripts...";

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

// Helper to safely load faction file
private _fnc_loadFaction = {
    params ["_factionName", "_filePath"];
    
    if (!fileExists _filePath) exitWith {
        diag_log format ["[FLO_INIT_P2] WARNING: Faction file not found: %1", _filePath];
        false
    };
    
    try {
        diag_log format ["[FLO_INIT_P2] Loading: %1", _filePath];
        call compileScript [_filePath];
        true
    } catch {
        diag_log format ["[FLO_INIT_P2] ERROR loading %1: %2", _filePath, _exception];
        false
    };
};

// Load friendly faction
private _bluFaction = FLO_FriendlyHandle get "name";
private _bluPath = switch (_bluFaction) do {
    case "NATO _ Desert": { "Scripts\factions\blu_NATODesert.sqf" };
    case "NATO _ Woodland": { "Scripts\factions\blu_NATOWood.sqf" };
    case "BAF _ Desert _ AEW": { "Scripts\factions\blu_BAF_Desert_AEW.sqf" };
    case "BAF _ Woodland _ AEW": { "Scripts\factions\blu_BAF_Wood_AEW.sqf" };
    case "US _ Desert _ AEW": { "Scripts\factions\blu_US_Desert_AEW.sqf" };
    case "US _ Woodland _ AEW": { "Scripts\factions\blu_US_Wood_AEW.sqf" };
    case "US _ Desert _ CUP RHS": { "Scripts\factions\blu_US_Desert_CUP_RHS.sqf" };
    case "US _ Woodland _ CUP RHS": { "Scripts\factions\blu_US_Wood_CUP_RHS.sqf" };
    case "GAF _ Desert _ BW": { "Scripts\factions\blu_GAF_Desert_BW.sqf" };
    case "GAF _ Woodland _ AEW": { "Scripts\factions\blu_GAF_Wood_AEW.sqf" };
    case "GAF _ Woodland _ BW": { "Scripts\factions\blu_GAF_Wood_BW.sqf" };
    case "IAF _ Woodland _ AEW": { "Scripts\factions\blu_IAF_Wood_AEW.sqf" };
    case "LDF _ Woodland _ AEW": { "Scripts\factions\blu_LDF_Wood_AEW.sqf" };
    case "SAF _ Woodland _ FFAA": { "Scripts\factions\blu_SAF_Wood_FFAA.sqf" };
    case "US _ PFSOG": { "Scripts\factions\blu_US_PFSOG.sqf" };
    case "Western Sahara": { "Scripts\factions\blu_WesternSahara.sqf" };
    default { "CUSTOM_PLAYER_FACTION.sqf" };
};
[_bluFaction, _bluPath] call _fnc_loadFaction;

// Load enemy faction
private _opfFaction = FLO_EnemyHandle get "name";
private _opfPath = switch (_opfFaction) do {
    case "CSAT _ Desert": { "Scripts\factions\opf_CSATDesert.sqf" };
    case "CSAT _ Woodland": { "Scripts\factions\opf_CSATWood.sqf" };
    case "AAF _ Woodland": { "Scripts\factions\opf_AAF_Wood.sqf" };
    case "LDF _ Woodland": { "Scripts\factions\opf_LDF_Wood.sqf" };
    case "Syndikat _ Woodland": { "Scripts\factions\opf_Syndikat_Wood.sqf" };
    case "Russia AF _ Desert _ RHS": { "Scripts\factions\opf_RussiaAF_Desert_RHS.sqf" };
    case "Russia AF _ Woodland _ RHS": { "Scripts\factions\opf_RussiaAF_Wood_RHS.sqf" };
    case "Afghan AF _ CUP": { "Scripts\factions\opf_AfghanAF_CUP.sqf" };
    case "Afghan Insurgents _ CUP": { "Scripts\factions\opf_AfghanIns_CUP.sqf" };
    case "African Insurgents _ POF": { "Scripts\factions\opf_AfricaIns_POF.sqf" };
    case "East Europe Insurgents _ Desert _ AEW": { "Scripts\factions\opf_EastEuropeIns_Desert_AEW.sqf" };
    case "East Europe Insurgents _ Woodland _ AEW": { "Scripts\factions\opf_EastEuropeIns_Wood_AEW.sqf" };
    case "ISIS _ POF": { "Scripts\factions\opf_ISIS_POF.sqf" };
    case "Iran AF _ POF": { "Scripts\factions\opf_IranAF_POF.sqf" };
    case "NVA _ PFSOG": { "Scripts\factions\opf_NVA_PFSOG.sqf" };
    case "SFF _ Desert _ Western Sahara": { "Scripts\factions\opf_SFF_Desert_WesternSahara.sqf" };
    case "Syrian AF _ POF": { "Scripts\factions\opf_SyrianAF_POF.sqf" };
    case "TTI _ Desert _ Western Sahara": { "Scripts\factions\opf_TTI_Desert_WesternSahara.sqf" };
    default { "CUSTOM_ENEMY_FACTION.sqf" };
};
[_opfFaction, _opfPath] call _fnc_loadFaction;

// Load civilian faction
private _civFaction = FLO_CivilianHandle get "name";
private _civPath = switch (_civFaction) do {
    case "Greek Civilians": { "Scripts\factions\civ_Greek.sqf" };
    case "Asian Civilians": { "Scripts\factions\civ_Asia.sqf" };
    case "East Europe Civilians": { "Scripts\factions\civ_EastEurope.sqf" };
    case "East Europe Civilians _ CUP": { "Scripts\factions\civ_EastEuropeCUP.sqf" };
    case "Middle East Civilians _ CUP": { "Scripts\factions\civ_MiddleEastCUP.sqf" };
    case "Tanoan Civilians": { "Scripts\factions\civ_Tanoa.sqf" };
    case "Vietnamese Civilians": { "Scripts\factions\civ_Vietnam.sqf" };
    case "Western Sahara Civilians": { "Scripts\factions\civ_WesternSahara.sqf" };
    default { "CUSTOM_CIVILIAN_FACTION.sqf" };
};
[_civFaction, _civPath] call _fnc_loadFaction;

// Default civilian vehicles if not set by faction
if (isNil "CivVehArray") then {
    CivVehArray = [
        "C_Truck_02_covered_F", "C_Truck_02_transport_F", "C_Van_02_vehicle_F",
        "C_Hatchback_01_F", "C_Offroad_01_F", "C_SUV_01_F"
    ];
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

if (count _missingArrays > 0) exitWith {
    FLO_InitError = format ["Faction loading failed - missing arrays: %1", _missingArrays];
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P2] ERROR: %1", FLO_InitError];
    false
};

// ============================================================================
// BROADCAST FACTION DATA TO CLIENTS (for Request Menu UI and other client needs)
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
private _buildingVars = ["F_HQ_01", "F_HQ_C_01", "F_OP_01", "F_OP_C_01", "F_RADAR"];

// Request menu vehicle/equipment lists
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

private _fnc_extractVehicleClasses = {
    params [["_list", []]];
    if (_list isEqualType "") then {
        _list = [_list];
    };
    if !(_list isEqualType []) exitWith { [] };

    private _result = [];
    {
        if (_x isEqualType []) then {
            if (count _x > 0) then {
                private _cls = _x select 0;
                if (_cls isEqualType "") then {
                    _result pushBackUnique _cls;
                };
            };
        } else {
            if (_x isEqualType "") then {
                _result pushBackUnique _x;
            };
        };
    } forEach _list;
    _result
};

private _fnc_getVarArray = {
    params [["_varName", ""]];
    if (_varName == "") exitWith { [] };
    if (isNil _varName) exitWith { [] };
    private _value = missionNamespace getVariable [_varName, []];
    if (_value isEqualType "") exitWith { [_value] };
    if !(_value isEqualType []) exitWith { [] };
    _value
};

private _fnc_buildPoolFromVars = {
    params [["_varNames", []]];
    private _merged = [];
    {
        _merged append ([_x] call _fnc_getVarArray);
    } forEach _varNames;
    [_merged] call _fnc_extractVehicleClasses
};

private _fnc_collectDirectUnitVars = {
    params [["_varNames", []]];

    private _units = [];
    {
        if (!isNil _x) then {
            private _u = missionNamespace getVariable [_x, ""];
            if (_u isEqualType "" && {_u != ""}) then {
                _units pushBack _u;
            };
        };
    } forEach _varNames;

    _units
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

private _westLegacyInfantry = [_westInfantryVars] call _fnc_collectDirectUnitVars;
private _westLegacySpecOps = [_westSpecOpsVars] call _fnc_collectDirectUnitVars;

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

private _eastGroundMotorized = [(if (!isNil "East_Ground_Motorized") then { East_Ground_Motorized } else { if (!isNil "East_Ground_Vehicles_Light") then { East_Ground_Vehicles_Light } else { [] } })] call _fnc_extractVehicleClasses;
private _eastGroundMechanized = [(if (!isNil "East_Ground_Mechanized") then { East_Ground_Mechanized } else { if (!isNil "East_Ground_Vehicles_Heavy") then { East_Ground_Vehicles_Heavy } else { [] } })] call _fnc_extractVehicleClasses;
private _eastGroundArmor = [(if (!isNil "East_Ground_Armor") then { East_Ground_Armor } else { if (!isNil "East_Ground_Vehicles_Heavy") then { East_Ground_Vehicles_Heavy } else { [] } })] call _fnc_extractVehicleClasses;
private _eastGroundTransport = [(if (!isNil "East_Ground_Transport") then { East_Ground_Transport } else { [] })] call _fnc_extractVehicleClasses;
private _eastGroundArtillery = [(if (!isNil "East_Ground_Artillery") then { East_Ground_Artillery } else { [] })] call _fnc_extractVehicleClasses;
private _eastAirHeli = [(if (!isNil "East_Air_Heli") then { East_Air_Heli } else { [] })] call _fnc_extractVehicleClasses;
private _eastAirJet = [(if (!isNil "East_Air_Jet") then { East_Air_Jet } else { [] })] call _fnc_extractVehicleClasses;
private _eastAirTransport = [(if (!isNil "East_Air_Transport") then { East_Air_Transport } else { [] })] call _fnc_extractVehicleClasses;
private _eastAirDrone = [(if (!isNil "East_Air_Drone") then { East_Air_Drone } else { [] })] call _fnc_extractVehicleClasses;
private _eastGroundDrone = [(if (!isNil "East_Ground_Drone") then { East_Ground_Drone } else { [] })] call _fnc_extractVehicleClasses;
private _eastMobileAA = [(if (!isNil "East_Mobile_AA") then { East_Mobile_AA } else { [] })] call _fnc_extractVehicleClasses;
private _eastStaticAA = [(if (!isNil "East_Static_AA") then { East_Static_AA } else { [] })] call _fnc_extractVehicleClasses;
private _eastBoat = [(if (!isNil "East_Boat") then { East_Boat } else { [] })] call _fnc_extractVehicleClasses;
private _eastRadar = [(if (!isNil "East_Radar") then { East_Radar } else { [] })] call _fnc_extractVehicleClasses;
private _eastTransportReserveGroundCount = if (!isNil "East_Transport_Reserve_Ground_Count") then { East_Transport_Reserve_Ground_Count } else { 20 };
private _eastTransportReserveAirCount = if (!isNil "East_Transport_Reserve_Air_Count") then { East_Transport_Reserve_Air_Count } else { 10 };

private _westGroundMotorized = if (!isNil "West_Ground_Motorized") then {
    [West_Ground_Motorized] call _fnc_extractVehicleClasses
} else {
    [["F_Car_List", "F_MRAP_List"]] call _fnc_buildPoolFromVars
};
private _westGroundMechanized = if (!isNil "West_Ground_Mechanized") then {
    [West_Ground_Mechanized] call _fnc_extractVehicleClasses
} else {
    [["F_APC_List"]] call _fnc_buildPoolFromVars
};
private _westGroundArmor = if (!isNil "West_Ground_Armor") then {
    [West_Ground_Armor] call _fnc_extractVehicleClasses
} else {
    [["F_Tank_List"]] call _fnc_buildPoolFromVars
};
private _westGroundTransport = if (!isNil "West_Ground_Transport") then {
    [West_Ground_Transport] call _fnc_extractVehicleClasses
} else {
    [["F_Truck_List"]] call _fnc_buildPoolFromVars
};
private _westGroundArtillery = if (!isNil "West_Ground_Artillery") then {
    [West_Ground_Artillery] call _fnc_extractVehicleClasses
} else {
    [["F_Artillery_List"]] call _fnc_buildPoolFromVars
};
private _westAirHeli = if (!isNil "West_Air_Heli") then {
    [West_Air_Heli] call _fnc_extractVehicleClasses
} else {
    private _legacy = [["F_Heli_Gunship_List"]] call _fnc_buildPoolFromVars;
    if (count _legacy == 0) then {
        _legacy = [["F_Heli_List"]] call _fnc_buildPoolFromVars;
    };
    _legacy
};
private _westAirJet = if (!isNil "West_Air_Jet") then {
    [West_Air_Jet] call _fnc_extractVehicleClasses
} else {
    [["F_Plane_List"]] call _fnc_buildPoolFromVars
};
private _westAirTransport = if (!isNil "West_Air_Transport") then {
    [West_Air_Transport] call _fnc_extractVehicleClasses
} else {
    [["F_Heli_List", "F_Heli_Respawn_List"]] call _fnc_buildPoolFromVars
};
private _westAirDrone = if (!isNil "West_Air_Drone") then {
    [West_Air_Drone] call _fnc_extractVehicleClasses
} else {
    [["F_UAV_List"]] call _fnc_buildPoolFromVars
};
private _westGroundDrone = if (!isNil "West_Ground_Drone") then {
    [West_Ground_Drone] call _fnc_extractVehicleClasses
} else {
    [["F_UGV_List"]] call _fnc_buildPoolFromVars
};
private _westMobileAA = if (!isNil "West_Mobile_AA") then {
    [West_Mobile_AA] call _fnc_extractVehicleClasses
} else {
    [["F_APC_List", "F_Tank_List"]] call _fnc_buildPoolFromVars
};
private _westStaticAA = if (!isNil "West_Static_AA") then {
    [West_Static_AA] call _fnc_extractVehicleClasses
} else {
    [["F_SAM_List"]] call _fnc_buildPoolFromVars
};
private _westRadar = if (!isNil "West_Radar") then {
    [West_Radar] call _fnc_extractVehicleClasses
} else {
    if (!isNil "F_RADAR" && {F_RADAR isEqualType ""}) then { [F_RADAR] } else { [] }
};
private _westBoat = if (!isNil "West_Boat") then {
    [West_Boat] call _fnc_extractVehicleClasses
} else {
    [["F_Boat_List"]] call _fnc_buildPoolFromVars
};
private _westTransportReserveGroundCount = if (!isNil "West_Transport_Reserve_Ground_Count") then { West_Transport_Reserve_Ground_Count } else { 20 };
private _westTransportReserveAirCount = if (!isNil "West_Transport_Reserve_Air_Count") then { West_Transport_Reserve_Air_Count } else { 10 };
private _westLogisticsConstruction = [["F_Truck_Construction_List"]] call _fnc_buildPoolFromVars;
private _westLogisticsAmmo = [["F_Truck_Ammo_List"]] call _fnc_buildPoolFromVars;
private _westLogisticsRespawn = [["F_Truck_Respawn_List"]] call _fnc_buildPoolFromVars;
private _westContainers = [["F_Container_List"]] call _fnc_buildPoolFromVars;

private _eastOfficerUnits = if (!isNil "East_FireObserver") then {
    ["East_FireObserver"] call _fnc_getVarArray
} else {
    if (count _eastInfantryUnits > 0) then { [_eastInfantryUnits select 0] } else { [] }
};
private _westOfficerUnits = if (!isNil "F_Officer") then {
    [F_Officer]
} else {
    if (count _westInfantryUnits > 0) then { [_westInfantryUnits select 0] } else { [] }
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
    ["transportReserveGroundCount", _eastTransportReserveGroundCount],
    ["groundArtillery", _eastGroundArtillery],
    ["airHeli", _eastAirHeli],
    ["airJet", _eastAirJet],
    ["airTransport", _eastAirTransport],
    ["transportReserveAirCount", _eastTransportReserveAirCount],
    ["airDrone", _eastAirDrone],
    ["groundDrone", _eastGroundDrone],
    ["mobileAA", _eastMobileAA],
    ["staticAA", _eastStaticAA],
    ["boat", _eastBoat],
    ["radar", _eastRadar],
    ["objectiveGroups", OPFOR_Objective_Groups],
    ["groupCounts", OPFOR_Group_Counts]
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
    ["transportReserveGroundCount", _westTransportReserveGroundCount],
    ["groundArtillery", _westGroundArtillery],
    ["airHeli", _westAirHeli],
    ["airJet", _westAirJet],
    ["airTransport", _westAirTransport],
    ["transportReserveAirCount", _westTransportReserveAirCount],
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
    ["objectiveGroups", BLUFOR_Objective_Groups],
    ["groupCounts", BLUFOR_Group_Counts]
];

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
