/*
 * Function: FLO_fnc_sideMissionState
 * Author: Frontline Operations Development Group
 * Description:
 *   Mission State Machine for the side mission system.
 *   Handles state definitions, transitions, and validation.
 *
 * Mission States:
 *   0 - QUEUED:    Mission selected but not yet offered to players
 *   1 - PENDING:   Awaiting player acceptance/rejection
 *   2 - ACTIVE:    Mission accepted and in progress
 *   3 - SUCCESS:   Mission completed successfully
 *   4 - FAILED:    Mission failed (timeout, objectives destroyed, etc.)
 *   5 - CANCELLED: Mission cancelled (declined or system cleanup)
 *
 * Arguments:
 *   0: Operation (STRING) - "init", "get", "set", "canTransition", "getStateName"
 *   1: Arguments (ARRAY) - Operation-specific arguments
 *
 * Returns:
 *   Varies by operation
 *
 * Examples:
 *   ["init"] call FLO_fnc_sideMissionState;
 *   ["get", [_missionId]] call FLO_fnc_sideMissionState;
 *   ["set", [_missionId, 2]] call FLO_fnc_sideMissionState; // Set to ACTIVE
 *   ["canTransition", [_currentState, _newState]] call FLO_fnc_sideMissionState;
 *   ["getStateName", [2]] call FLO_fnc_sideMissionState; // Returns "ACTIVE"
 */

params [["_operation", ""], ["_args", []]];

// State constants (for documentation - use numeric values in code)
// MISSION_STATE_QUEUED     = 0
// MISSION_STATE_PENDING    = 1
// MISSION_STATE_ACTIVE     = 2
// MISSION_STATE_SUCCESS    = 3
// MISSION_STATE_FAILED     = 4
// MISSION_STATE_CANCELLED  = 5

// Auto-initialize globals on first call
if (isNil "FLO_SM_States") then { FLO_SM_States = createHashMap; };
if (isNil "FLO_SM_ValidTransitions") then {
    FLO_SM_ValidTransitions = createHashMapFromArray [
        [0, [1, 5]],        // QUEUED -> PENDING, CANCELLED
        [1, [2, 5]],        // PENDING -> ACTIVE, CANCELLED
        [2, [3, 4, 5]],     // ACTIVE -> SUCCESS, FAILED, CANCELLED
        [3, []],            // SUCCESS -> (terminal)
        [4, []],            // FAILED -> (terminal)
        [5, []]             // CANCELLED -> (terminal)
    ];
};

private _result = nil;

// Also auto-init state names
if (isNil "FLO_SM_StateNames") then {
    FLO_SM_StateNames = createHashMapFromArray [
        [0, "QUEUED"],
        [1, "PENDING"],
        [2, "ACTIVE"],
        [3, "SUCCESS"],
        [4, "FAILED"],
        [5, "CANCELLED"]
    ];
};

switch (toLower _operation) do {
    // Initialize the state system
    case "init": {
        _result = true;
    };
    
    // Get current state of a mission
    case "get": {
        _args params [["_missionId", ""]];
        if (_missionId == "") exitWith { _result = -1; };
        _result = FLO_SM_States getOrDefault [_missionId, -1];
    };
    
    // Set state of a mission
    case "set": {
        _args params [["_missionId", ""], ["_newState", -1], ["_force", false]];
        if (_missionId == "" || _newState < 0 || _newState > 5) exitWith { _result = false; };
        
        private _currentState = FLO_SM_States getOrDefault [_missionId, -1];
        
        // If no current state, allow setting initial state (should be QUEUED)
        if (_currentState == -1) then {
            FLO_SM_States set [_missionId, _newState];
            _result = true;
        } else {
            // Validate transition
            private _validNext = FLO_SM_ValidTransitions getOrDefault [_currentState, []];
            if (_force || {_newState in _validNext}) then {
                FLO_SM_States set [_missionId, _newState];
                _result = true;
                
                // Log state transition for debugging
                private _oldName = FLO_SM_StateNames getOrDefault [_currentState, "UNKNOWN"];
                private _newName = FLO_SM_StateNames getOrDefault [_newState, "UNKNOWN"];
                diag_log format ["[FLO_SM] Mission %1: %2 -> %3", _missionId, _oldName, _newName];
            } else {
                diag_log format ["[FLO_SM] Invalid transition for %1: %2 -> %3", 
                    _missionId, _currentState, _newState];
                _result = false;
            };
        };
    };
    
    // Check if a transition is valid
    case "cantransition": {
        _args params [["_currentState", -1], ["_newState", -1]];
        private _validNext = FLO_SM_ValidTransitions getOrDefault [_currentState, []];
        _result = _newState in _validNext;
    };
    
    // Get human-readable state name
    case "getstatename": {
        _args params [["_state", -1]];
        _result = FLO_SM_StateNames getOrDefault [_state, "UNKNOWN"];
    };
    
    // Check if state is terminal (SUCCESS, FAILED, CANCELLED)
    case "isterminal": {
        _args params [["_state", -1]];
        _result = _state >= 3;
    };
    
    // Remove a mission from state tracking
    case "remove": {
        _args params [["_missionId", ""]];
        if (_missionId != "") then {
            FLO_SM_States deleteAt _missionId;
            _result = true;
        } else {
            _result = false;
        };
    };
    
    // Get all missions in a specific state
    case "getbystate": {
        _args params [["_state", -1]];
        private _missions = [];
        {
            if (_y == _state) then { _missions pushBack _x; };
        } forEach FLO_SM_States;
        _result = _missions;
    };
    
    default {
        diag_log format ["[FLO_SM] Unknown operation: %1", _operation];
        _result = nil;
    };
};

_result

