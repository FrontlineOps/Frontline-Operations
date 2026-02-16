/*
 * Function: FLO_fnc_MissionStartup
 * Author: Frontline Operations Development Group
 * Description:
 *   Initializes FOBs, OPs, and support systems.
 *   Called from Phase 5 AFTER factions are loaded.
 *
 * Dependencies:
 *   - Faction variables (F_HQ_01, F_OP_01, etc.) must be set
 *   - Called after Phase 2 (Factions) completes
 *
 * Returns: Nothing
 */

if (!isServer) exitWith {};

["STARTUP", 3, "MissionStartup beginning..."] call FLO_fnc_log;

// ============================================================================
// DEFAULTS AND VALIDATION
// ============================================================================

// Set defaults for missing faction variables
if (isNil "F_HQ_01") then { F_HQ_01 = "Land_Cargo_HQ_V3_F"; ["STARTUP", 2, "F_HQ_01 not set, using default"] call FLO_fnc_log; };
if (isNil "F_HQ_C_01") then { F_HQ_C_01 = "Land_Cargo20_military_green_F"; };
if (isNil "F_OP_01") then { F_OP_01 = "Land_Cargo_Patrol_V3_F"; ["STARTUP", 2, "F_OP_01 not set, using default"] call FLO_fnc_log; };
if (isNil "F_OP_C_01") then { F_OP_C_01 = "Land_Cargo10_military_green_F"; };

// Ensure vehicle lists exist
if (isNil "F_Truck_Respawn_List") then { F_Truck_Respawn_List = []; };
if (isNil "F_Heli_Respawn_List") then { F_Heli_Respawn_List = []; };
if (isNil "F_Truck_Construction_List") then { F_Truck_Construction_List = []; };
if (isNil "F_Truck_Ammo_List") then { F_Truck_Ammo_List = []; };

// Unique ID counter for markers
private _markerCounter = 0;

// ============================================================================
// INITIALIZE FOBs
// ============================================================================

["STARTUP", 3, "Initializing FOBs..."] call FLO_fnc_log;

// Use allMissionObjects for efficient world-wide search (no duplicates needed)
private _fobTypes = [F_HQ_01, "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V1_F"] arrayIntersect [F_HQ_01, "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V1_F"];
private _allFobBuildings = [];
{ _allFobBuildings append (allMissionObjects _x); } forEach _fobTypes;
FOBB = _allFobBuildings arrayIntersect _allFobBuildings;

// Cache all FOB containers once
private _allFobContainers = allMissionObjects F_HQ_C_01;

private _fobCount = 0;
{
    private _building = _x;
    private _hasContainer = (_allFobContainers findIf { _x distance _building < 20 }) > -1;
    if (_hasContainer) then {
        // Check if this FOB was restored from save (preserve marker)
        private _isRestored = _building getVariable ["FLO_FOB_MarkersRestored", false];
        [_building, _isRestored] call FLO_fnc_initializeFOB;
        _fobCount = _fobCount + 1;
    };
} forEach FOBB;

["STARTUP", 3, format ["Initialized %1 FOBs", _fobCount]] call FLO_fnc_log;

// ============================================================================
// INITIALIZE OPs
// ============================================================================

["STARTUP", 3, "Initializing OPs..."] call FLO_fnc_log;

private _opBuildings = allMissionObjects F_OP_01;
private _allOpContainers = allMissionObjects F_OP_C_01;

["STARTUP", 4, format ["Found %1 OP buildings (type %2) and %3 OP containers (type %4)",
    count _opBuildings, F_OP_01, count _allOpContainers, F_OP_C_01]] call FLO_fnc_log;

private _opCount = 0;
{
    private _building = _x;
    private _hasContainer = (_allOpContainers findIf { _x distance _building < 15 }) > -1;

    if (_hasContainer) then {
        // Check if this OP was restored from save (preserve marker)
        private _isRestored = _building getVariable ["FLO_OP_MarkersRestored", false];
        [_building, _isRestored] call FLO_fnc_initializeOP;
        _opCount = _opCount + 1;
    } else {
        ["STARTUP", 2, format ["OP at %1 has no container within 15m - skipping initialization", getPos _building]] call FLO_fnc_log;
    };
} forEach _opBuildings;

["STARTUP", 3, format ["Initialized %1 OPs", _opCount]] call FLO_fnc_log;
[] call FLO_fnc_refreshRespawnMarkersByTerritory;

[] spawn {
    while {true} do {
        [] call FLO_fnc_refreshRespawnMarkersByTerritory;
        sleep 5;
    };
};


// ============================================================================
// FOB SCREEN ACTIONS - Now handled by fn_initializeFOB
// ============================================================================
// Commander actions (Skip Time, Weather, Save, Reset, Bribe) are now added
// in fn_initializeFOB via _fnc_addContainerActions. This ensures actions are
// added both at startup AND when FOBs are deployed via FOBUNPACK.

// ============================================================================
// DEPLOYABLE CONTAINERS (Slingload FOB/OP)
// ============================================================================

["STARTUP", 3, "Initializing deployable containers..."] call FLO_fnc_log;

// FOB slingload containers
private _fobSlingloads = allMissionObjects "B_Slingload_01_Cargo_F";
{
    [_x, [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>UnPack FOB",
        "Scripts\PObjectives\FOBUNPACK.sqf", nil, 0, true, true, "", "true", 40, false, "", ""
    ]] remoteExec ["addAction", 0, true];
    _x setVariable ["IDS_Logistics_isPlacedEntity", true, true];
    [_x, [
        "<t font='PuristaBold' color='#FF0000' size='1.15'>Move FOB</t>",
        { [player, true] call IDS_Logistics_fnc_initBuildCamera; }, nil, 1.4, false, true, "", "!IDS_Logistics_isHolding"
    ]] remoteExec ["addAction", 0, true];
} forEach _fobSlingloads;

// OP slingload containers
private _opSlingloads = allMissionObjects "B_Slingload_01_Repair_F";
{
    [_x, [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>UnPack OP",
        "Scripts\PObjectives\OPUNPACK.sqf", nil, 0, true, true, "", "true", 40, false, "", ""
    ]] remoteExec ["addAction", 0, true];
    _x setVariable ["IDS_Logistics_isPlacedEntity", true, true];
    [_x, [
        "<t font='PuristaBold' color='#FF0000' size='1.15'>Move OP</t>",
        { [player, true] call IDS_Logistics_fnc_initBuildCamera; }, nil, 1.4, false, true, "", "!IDS_Logistics_isHolding"
    ]] remoteExec ["addAction", 0, true];
} forEach _opSlingloads;

["STARTUP", 3, format ["Initialized %1 FOB and %2 OP slingloads", count _fobSlingloads, count _opSlingloads]] call FLO_fnc_log;

// ============================================================================
// MOBILE RESPAWN MARKER SYSTEM
// ============================================================================

["STARTUP", 3, "Starting mobile respawn marker system..."] call FLO_fnc_log;

// Build respawn vehicle type set and store globally for spawned code
private _respawnVehicleTypes = [];
if (count F_Truck_Respawn_List > 0) then { _respawnVehicleTypes append (F_Truck_Respawn_List apply { _x # 0 }); };
if (count F_Heli_Respawn_List > 0) then { _respawnVehicleTypes append (F_Heli_Respawn_List apply { _x # 0 }); };
FLO_RespawnVehicleTypeSet = createHashMapFromArray (_respawnVehicleTypes apply { [_x, true] });

// Spawn respawn marker loop with error handling
[] spawn {
    private _counter = 0;

    while { true } do {
        try {
            // Clean up old respawn markers
            private _oldMarkers = allMapMarkers select {
                markerType _x == "b_unknown" && markerColor _x == "ColorYellow" && markerAlpha _x == 0.7
            };
            { deleteMarker _x } forEach _oldMarkers;

            // Find alive respawn vehicles and create markers
            private _respawnVehs = vehicles select { alive _x && { (FLO_RespawnVehicleTypeSet getOrDefault [typeOf _x, false]) } };
            private _activeSide = FLO_ActivePlayerSide;
            private _respawnKey = if (_activeSide isEqualTo east) then { "east" } else { "west" };
            private _enemySide = if (_activeSide isEqualTo east) then { west } else { east };

            {
                private _vehPos = getPosATL _x;
                private _owner = sideUnknown;
                {
                    private _objData = FLO_Objectives get _x;
                    if ([_vehPos, _objData] call FLO_fnc_isPositionInObjective) exitWith {
                        _owner = _objData get "owner";
                    };
                } forEach (keys FLO_Objectives);
                if (_owner isEqualType "") then {
                    private _ownerKey = toUpper _owner;
                    if (_ownerKey isEqualTo "EAST") then { _owner = east; };
                    if (_ownerKey isEqualTo "WEST") then { _owner = west; };
                };
                if (_owner isEqualTo _enemySide) then { continue };

                private _markerName = format ["respawn_%1_%2", _respawnKey, _counter];
                _counter = _counter + 1;
                private _marker = createMarker [_markerName, _vehPos];
                _marker setMarkerType "b_unknown";
                _marker setMarkerColor "ColorYellow";
                _marker setMarkerSize [1, 1];
                _marker setMarkerAlpha 0.7;
            } forEach _respawnVehs;
        } catch {
            ["STARTUP", 1, format ["Respawn marker error: %1", _exception]] call FLO_fnc_log;
        };

        sleep 5;
    };
};

// ============================================================================
// MOBILE SERVICE STATIONS
// ============================================================================

["STARTUP", 3, "Initializing mobile service stations..."] call FLO_fnc_log;

// Construction vehicles - find by type
private _constructionVehicles = [];
{ _constructionVehicles append (allMissionObjects (_x # 0)); } forEach F_Truck_Construction_List;

{
    if (!isNull _x) then {
        [_x, [
            "<img size=2 color='#FF0000' image='\a3\ui_f\data\igui\cfg\simpletasks\types\Use_ca.paa'/><t font='PuristaBold' color='#FF0000'>Build Mode",
            { [player] call IDS_Logistics_fnc_initBuildCamera; }, nil, 1.4, false, true, "", "!IDS_Logistics_isHolding"
        ]] remoteExec ["addAction", 0, true];
    };
} forEach _constructionVehicles;

// Arsenal vehicles
private _arsenalVehicles = [];
{ _arsenalVehicles append (allMissionObjects (_x # 0)); } forEach F_Truck_Ammo_List;

{
    [_x, [
        "<img size=2 color='#FFE258' image='Screens\FOBA\mg_ca.paa'/><t font='PuristaBold' color='#FFE258'>ARSENAL",
        {
            if (isClass (configFile >> "ace_arsenal_loadoutsDisplay")) then {
                [player, player, true] call ace_arsenal_fnc_openBox;
            } else {
                ["Open", true] spawn BIS_fnc_arsenal;
            };
        },
        nil, 1, true, true, "", "_this distance _target < 10"
    ]] remoteExec ["addAction", 0, true];
} forEach _arsenalVehicles;

["STARTUP", 3, format ["Initialized %1 construction and %2 arsenal vehicles", count _constructionVehicles, count _arsenalVehicles]] call FLO_fnc_log;

// ============================================================================
// CLEANUP MAP OBJECTS
// ============================================================================

["STARTUP", 3, "Cleaning up map objects..."] call FLO_fnc_log;

private _cleanupTypes = ["Sign_Pointer_Blue_F", "Land_InvisibleBarrier_F", "LocationCityCapital_F", "LocationCity_F"];
private _objectsToDelete = [];
{ _objectsToDelete append (allMissionObjects _x); } forEach _cleanupTypes;

// Delete on server only
{ deleteVehicle _x } forEach _objectsToDelete;

["STARTUP", 3, format ["Cleaned up %1 map objects", count _objectsToDelete]] call FLO_fnc_log;

// ============================================================================
// COMPLETION
// ============================================================================

["STARTUP", 3, "Mission startup completed successfully"] call FLO_fnc_log;
