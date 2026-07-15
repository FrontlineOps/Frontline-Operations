/*
 * Function: FLO_fnc_MissionStartup
 * Author: Frontline Operations Development Group
 * Description:
 *   Initializes FOBs, OPs, and support systems.
 *   Called from Phase 5 AFTER factions are loaded.
 *
 * Dependencies:
 *   - Faction variables (FLO_FactionFobType, FLO_FactionCopType, etc.) must be set
 *   - Called after Phase 2 (Factions) completes
 *
 * Returns: Nothing
 */

if (!isServer) exitWith {};

["STARTUP", 3, "MissionStartup beginning..."] call FLO_fnc_log;

{
    if (isNil _x) then {
        ["STARTUP", 1, format ["Missing required faction base asset %1", _x]] call FLO_fnc_log;
        throw format ["Mission startup requires faction base asset %1", _x];
    };
    private _className = missionNamespace getVariable _x;
    if !(_className isEqualType "" && {_className != ""}) then {
        ["STARTUP", 1, format ["Invalid faction base asset %1=%2", _x, _className]] call FLO_fnc_log;
        throw format ["Mission startup requires non-empty faction base asset %1", _x];
    };
} forEach [
    "FLO_FactionFobType",
    "FLO_FactionFobTerminalType",
    "FLO_FactionCopType",
    "FLO_FactionCopTerminalType"
];

// Unique ID counter for markers
private _markerCounter = 0;

// ============================================================================
// INITIALIZE FOBs
// ============================================================================

["STARTUP", 3, "Initializing FOBs..."] call FLO_fnc_log;

// Use allMissionObjects for efficient world-wide search (no duplicates needed)
private _fobTypes = [FLO_FactionFobType, "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V1_F"] arrayIntersect [FLO_FactionFobType, "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V1_F"];
private _allFobBuildings = [];
{ _allFobBuildings append (allMissionObjects _x); } forEach _fobTypes;
private _fobBuildings = _allFobBuildings arrayIntersect _allFobBuildings;

// Cache all FOB containers once
private _allFobContainers = allMissionObjects FLO_FactionFobTerminalType;

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
} forEach _fobBuildings;

["STARTUP", 3, format ["Initialized %1 FOBs", _fobCount]] call FLO_fnc_log;

// ============================================================================
// INITIALIZE OPs
// ============================================================================

["STARTUP", 3, "Initializing OPs..."] call FLO_fnc_log;

private _opBuildings = allMissionObjects FLO_FactionCopType;
private _allOpContainers = allMissionObjects FLO_FactionCopTerminalType;

["STARTUP", 4, format ["Found %1 OP buildings (type %2) and %3 OP containers (type %4)",
    count _opBuildings, FLO_FactionCopType, count _allOpContainers, FLO_FactionCopTerminalType]] call FLO_fnc_log;

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
// MOBILE RESPAWN MARKER SYSTEM
// ============================================================================

["STARTUP", 3, "Starting mobile respawn marker system..."] call FLO_fnc_log;

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

            // Find requested mobile respawn vehicles and create markers
            private _respawnVehs = vehicles select { alive _x && { _x getVariable ["FLO_MobileRespawnVehicle", false] } };
            private _activeSide = FLO_ActivePlayerSide;
            private _respawnKey = ["west", "east"] select (_activeSide isEqualTo east);
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
                _marker setMarkerTypeLocal "b_unknown";
                _marker setMarkerColorLocal "ColorYellow";
                _marker setMarkerSizeLocal [1, 1];
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

["STARTUP", 3, "Initializing Store support vehicles..."] call FLO_fnc_log;

private _supportVehicles = vehicles select { _x getVariable ["FLO_StoreVehicle", false] };

{
    if (!isNull _x) then {
        [_x, typeOf _x] call FLO_fnc_vehicleConfigureRequestedVehicle;
    };
} forEach _supportVehicles;

["STARTUP", 3, format ["Initialized %1 Store support vehicles", count _supportVehicles]] call FLO_fnc_log;

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
