/*
 * Function: FLO_fnc_sideMissionEntityTracker
 * Author: Frontline Operations Development Group
 * Description:
 *   Tracks and manages entities (units, vehicles, objects, markers, triggers)
 *   spawned by side missions for proper cleanup.
 *
 * Arguments:
 *   0: Operation (STRING)
 *   1: Arguments (ARRAY)
 *
 * Operations:
 *   "addEntity"   - Add an entity to mission tracking
 *   "addMarker"   - Add a marker name to mission tracking
 *   "addTrigger"  - Add a trigger to mission tracking
 *   "addGroup"    - Add all units of a group to tracking
 *   "getEntities" - Get all entities for a mission
 *   "cleanup"     - Delete all tracked entities for a mission
 *
 * Returns: Varies by operation
 */

params [["_operation", ""], ["_args", []]];

private _result = nil;

// Helper to get mission instance
private _getInstance = {
    params ["_missionId"];
    ["get", [_missionId]] call FLO_fnc_sideMissionRegistry
};

switch (toLower _operation) do {
    // Add an entity (unit, vehicle, object) to tracking
    case "addentity": {
        _args params [["_missionId", ""], ["_entity", objNull]];
        
        private _instance = [_missionId] call _getInstance;
        if (isNil "_instance") exitWith { _result = false; };
        if (isNull _entity) exitWith { _result = false; };
        
        private _entities = _instance getOrDefault ["entities", []];
        _entities pushBackUnique _entity;
        _instance set ["entities", _entities];
        _result = true;
    };
    
    // Add multiple entities at once
    case "addentities": {
        _args params [["_missionId", ""], ["_entityArray", []]];
        
        private _instance = [_missionId] call _getInstance;
        if (isNil "_instance") exitWith { _result = false; };
        
        private _entities = _instance getOrDefault ["entities", []];
        {
            if (!isNull _x) then { _entities pushBackUnique _x; };
        } forEach _entityArray;
        _instance set ["entities", _entities];
        _result = true;
    };
    
    // Add a group's units to tracking
    case "addgroup": {
        _args params [["_missionId", ""], ["_group", grpNull]];
        
        if (isNull _group) exitWith { _result = false; };
        ["addEntities", [_missionId, units _group]] call FLO_fnc_sideMissionEntityTracker;
        _result = true;
    };

    // Remove a tracked entity so mission cleanup does not delete it.
    case "removeentity": {
        _args params [["_missionId", ""], ["_entity", objNull]];

        private _instance = [_missionId] call _getInstance;
        if (isNil "_instance") exitWith { _result = false; };
        if (isNull _entity) exitWith { _result = false; };

        private _entities = _instance get "entities";
        _instance set ["entities", _entities - [_entity]];
        _result = true;
    };
    
    // Add a marker to tracking
    case "addmarker": {
        _args params [["_missionId", ""], ["_markerName", ""]];
        
        private _instance = [_missionId] call _getInstance;
        if (isNil "_instance") exitWith { _result = false; };
        if (_markerName == "") exitWith { _result = false; };
        
        private _markers = _instance getOrDefault ["markers", []];
        _markers pushBackUnique _markerName;
        _instance set ["markers", _markers];
        _result = true;
    };
    
    // Add a trigger to tracking
    case "addtrigger": {
        _args params [["_missionId", ""], ["_trigger", objNull]];
        
        private _instance = [_missionId] call _getInstance;
        if (isNil "_instance") exitWith { _result = false; };
        if (isNull _trigger) exitWith { _result = false; };
        
        private _triggers = _instance getOrDefault ["triggers", []];
        _triggers pushBackUnique _trigger;
        _instance set ["triggers", _triggers];
        _result = true;
    };
    
    // Get all entities for a mission
    case "getentities": {
        _args params [["_missionId", ""]];
        private _instance = [_missionId] call _getInstance;
        if (isNil "_instance") exitWith { _result = []; };
        _result = _instance getOrDefault ["entities", []];
    };
    
    // Cleanup all tracked items for a mission
    case "cleanup": {
        _args params [["_missionId", ""], ["_deleteUnits", true]];
        
        private _instance = [_missionId] call _getInstance;
        if (isNil "_instance") exitWith { _result = false; };
        
        // Delete markers
        private _markers = _instance getOrDefault ["markers", []];
        { deleteMarker _x; } forEach _markers;
        _instance set ["markers", []];
        
        // Delete triggers
        private _triggers = _instance getOrDefault ["triggers", []];
        { if (!isNull _x) then { deleteVehicle _x; }; } forEach _triggers;
        _instance set ["triggers", []];
        
        // Delete entities if requested
        if (_deleteUnits) then {
            private _entities = _instance getOrDefault ["entities", []];
            {
                if (!isNull _x) then {
                    if (_x isKindOf "Man") then {
                        private _grp = group _x;
                        deleteVehicle _x;
                        if (count units _grp == 0) then { deleteGroup _grp; };
                    } else {
                        deleteVehicle _x;
                    };
                };
            } forEach _entities;
            _instance set ["entities", []];
        };
        
        diag_log format ["[FLO_SM] Cleaned up mission: %1", _missionId];
        _result = true;
    };
    
    // Count alive entities for a mission
    case "countalive": {
        _args params [["_missionId", ""]];
        private _entities = ["getEntities", [_missionId]] call FLO_fnc_sideMissionEntityTracker;
        _result = { alive _x } count _entities;
    };
    
    default {
        diag_log format ["[FLO_SM] EntityTracker: Unknown operation: %1", _operation];
        _result = nil;
    };
};

_result
