/*
 * Function: FLO_fnc_sideMissionRegistry
 * Author: Frontline Operations Development Group
 * Description:
 *   Central registry for active side mission instances.
 *   Tracks mission data, spawned entities, and provides CRUD operations.
 *
 * Mission Instance Structure:
 *   [missionId] -> HashMap {
 *     "type":        STRING  - Mission type name (e.g., "pilotRescue")
 *     "state":       NUMBER  - Current state (managed via fn_sideMissionState)
 *     "position":    ARRAY   - Mission center position [x,y,z]
 *     "startTime":   NUMBER  - serverTime when mission started
 *     "timeout":     NUMBER  - Seconds until auto-fail (-1 = no timeout)
 *     "taskId":      STRING  - BIS task ID if created
 *     "entities":    ARRAY   - Tracked entities (units, vehicles, objects)
 *     "markers":     ARRAY   - Marker names created for this mission
 *     "triggers":    ARRAY   - Trigger objects created
 *     "data":        HASHMAP - Mission-specific custom data
 *   }
 *
 * Arguments:
 *   0: Operation (STRING)
 *   1: Arguments (ARRAY)
 *
 * Returns: Varies by operation
 */

params [["_operation", ""], ["_args", []]];

// Auto-initialize globals on first call
if (isNil "FLO_SM_Registry") then { FLO_SM_Registry = createHashMap; };
if (isNil "FLO_SM_MissionCounter") then { FLO_SM_MissionCounter = 0; };

private _result = nil;

switch (toLower _operation) do {
    // Initialize the registry
    case "init": {
        _result = true;
    };
    
    // Create a new mission instance, returns mission ID
    case "create": {
        _args params [
            ["_type", ""],
            ["_position", [0,0,0]],
            ["_timeout", -1]
        ];
        
        if (_type == "") exitWith { _result = ""; };
        
        // Generate unique mission ID
        FLO_SM_MissionCounter = FLO_SM_MissionCounter + 1;
        private _missionId = format ["SM_%1_%2", _type, FLO_SM_MissionCounter];
        
        // Create mission instance data
        private _instance = createHashMapFromArray [
            ["type", _type],
            ["state", 0],
            ["position", _position],
            ["startTime", serverTime],
            ["timeout", _timeout],
            ["taskId", ""],
            ["entities", []],
            ["markers", []],
            ["triggers", []],
            ["data", createHashMap]
        ];
        
        FLO_SM_Registry set [_missionId, _instance];
        
        // Set initial state in state machine
        ["set", [_missionId, 0]] call FLO_fnc_sideMissionState;
        
        diag_log format ["[FLO_SM] Created mission: %1 (type: %2)", _missionId, _type];
        _result = _missionId;
    };
    
    // Get mission instance data
    case "get": {
        _args params [["_missionId", ""]];
        _result = FLO_SM_Registry getOrDefault [_missionId, nil];
    };
    
    // Update mission data field
    case "update": {
        _args params [["_missionId", ""], ["_field", ""], ["_value", nil]];
        private _instance = FLO_SM_Registry getOrDefault [_missionId, nil];
        if (!isNil "_instance" && _field != "") then {
            _instance set [_field, _value];
            _result = true;
        } else {
            _result = false;
        };
    };
    
    // Get all active missions (non-terminal state)
    case "getactive": {
        private _active = [];
        {
            private _state = ["get", [_x]] call FLO_fnc_sideMissionState;
            if (_state >= 0 && _state < 3) then {
                _active pushBack _x;
            };
        } forEach (keys FLO_SM_Registry);
        _result = _active;
    };
    
    // Get missions by type
    case "getbytype": {
        _args params [["_type", ""]];
        private _matching = [];
        {
            private _instance = _y;
            if ((_instance get "type") == _type) then {
                _matching pushBack _x;
            };
        } forEach FLO_SM_Registry;
        _result = _matching;
    };
    
    // Count active missions
    case "countactive": {
        _result = count (["getActive"] call FLO_fnc_sideMissionRegistry);
    };
    
    // Check if mission exists
    case "exists": {
        _args params [["_missionId", ""]];
        _result = _missionId in FLO_SM_Registry;
    };
    
    // Delete mission from registry (cleanup should be called first)
    case "delete": {
        _args params [["_missionId", ""]];
        if (_missionId in FLO_SM_Registry) then {
            FLO_SM_Registry deleteAt _missionId;
            ["remove", [_missionId]] call FLO_fnc_sideMissionState;
            _result = true;
        } else {
            _result = false;
        };
    };
    
    // Get all mission IDs
    case "getall": {
        _result = keys FLO_SM_Registry;
    };
    
    default {
        diag_log format ["[FLO_SM] Registry: Unknown operation: %1", _operation];
        _result = nil;
    };
};

_result

