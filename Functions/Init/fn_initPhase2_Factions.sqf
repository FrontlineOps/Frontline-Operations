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
if (!isNil "F_Init" && {F_Init}) exitWith {
    diag_log "[FLO_INIT_P2] Factions already loaded (saved game)";
    
    // Verify critical arrays exist
    if (isNil "East_Units" || isNil "East_Ground_Vehicles_Light") then {
        diag_log "[FLO_INIT_P2] WARNING: Faction arrays missing despite F_Init=true, reloading...";
    } else {
        true
    };
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
private _criticalArrays = ["East_Units", "East_Ground_Vehicles_Light", "East_Air_Transport"];
private _missingArrays = _criticalArrays select { isNil _x };

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

// Mark factions as loaded
F_Init = true;
publicVariable "F_Init";

diag_log format ["[FLO_INIT_P2] Factions loaded successfully: BLU=%1, OPF=%2, CIV=%3", _bluFaction, _opfFaction, _civFaction];
true

