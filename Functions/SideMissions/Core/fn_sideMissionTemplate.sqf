/*
 * Function: FLO_fnc_sideMissionTemplate
 * Author: Frontline Operations Development Group
 * Description:
 *   Mission Template system for defining reusable mission types.
 *   Templates define how missions spawn, succeed, fail, and clean up.
 *
 * Template Structure:
 *   [typeName] -> HashMap {
 *     "name":           STRING  - Display name for notifications/tasks
 *     "description":    STRING  - Mission description (can use stringtable)
 *     "icon":           STRING  - Marker/task icon type
 *     "color":          STRING  - Marker color
 *     "cooldown":       NUMBER  - Seconds before same type can spawn again
 *     "timeout":        NUMBER  - Default mission timeout (-1 = none)
 *     "maxActive":      NUMBER  - Max concurrent of this type (-1 = unlimited)
 *     "reward":         NUMBER  - Base reward points on success
 *     "isConvoy":       BOOL    - Special handling for convoy missions
 *     "fnc_setup":      CODE    - Called to find position & validate spawn
 *     "fnc_spawn":      CODE    - Spawns mission entities, returns data
 *     "fnc_checkSuccess": CODE  - Returns true if success conditions met
 *     "fnc_checkFail":  CODE    - Returns true if failure conditions met
 *     "fnc_cleanup":    CODE    - Cleans up mission entities
 *   }
 *
 * Arguments:
 *   0: Operation (STRING)
 *   1: Arguments (ARRAY)
 *
 * Returns: Varies by operation
 */

params [["_operation", ""], ["_args", []]];

// Initialize globals
if (isNil "FLO_SM_Templates") then { FLO_SM_Templates = createHashMap; };
if (isNil "FLO_SM_Cooldowns") then { FLO_SM_Cooldowns = createHashMap; };

private _result = nil;

switch (toLower _operation) do {
    // Initialize template system
    case "init": {
        _result = true;
    };
    
    // Register a mission template
    case "register": {
        _args params [["_typeName", ""], ["_template", createHashMap]];
        
        if (_typeName == "") exitWith { _result = false; };
        
        // Validate required fields
        private _required = ["name", "fnc_spawn"];
        private _valid = true;
        {
            if !(_x in _template) then {
                diag_log format ["[FLO_SM] Template %1 missing required field: %2", _typeName, _x];
                _valid = false;
            };
        } forEach _required;
        
        if (!_valid) exitWith { _result = false; };
        
        // Apply defaults for optional fields
        private _defaults = createHashMapFromArray [
            ["description", ""],
            ["icon", "mil_objective"],
            ["color", "colorOPFOR"],
            ["cooldown", 600],
            ["timeout", 3600],
            ["maxActive", -1],
            ["reward", 50],
            ["isConvoy", false],
            ["fnc_setup", { true }],
            ["fnc_checkSuccess", { false }],
            ["fnc_checkFail", { false }],
            ["fnc_cleanup", {}]
        ];
        
        {
            if !(_x in _template) then {
                _template set [_x, _y];
            };
        } forEach _defaults;
        
        FLO_SM_Templates set [_typeName, _template];
        diag_log format ["[FLO_SM] Registered template: %1", _typeName];
        _result = true;
    };
    
    // Get a template
    case "get": {
        _args params [["_typeName", ""]];
        _result = FLO_SM_Templates getOrDefault [_typeName, nil];
    };
    
    // Check if template exists
    case "exists": {
        _args params [["_typeName", ""]];
        _result = _typeName in FLO_SM_Templates;
    };
    
    // Check if a mission type can spawn (cooldown + maxActive)
    case "canspawn": {
        _args params [["_typeName", ""]];

        private _template = FLO_SM_Templates getOrDefault [_typeName, nil];
        if (isNil "_template") exitWith { _result = false; };

        // Check cooldown
        private _cooldown = _template getOrDefault ["cooldown", 600];
        private _lastSpawn = FLO_SM_Cooldowns getOrDefault [_typeName, 0];
        if (serverTime - _lastSpawn < _cooldown) exitWith { _result = false; };

        // Check max active
        private _maxActive = _template getOrDefault ["maxActive", -1];
        private _canSpawn = true;

        if (_maxActive > 0) then {
            private _activeOfType = ["getByType", [_typeName]] call FLO_fnc_sideMissionRegistry;
            private _activeCount = {
                private _state = ["get", [_x]] call FLO_fnc_sideMissionState;
                _state >= 0 && _state < 3
            } count _activeOfType;
            if (_activeCount >= _maxActive) then { _canSpawn = false; };
        };

        _result = _canSpawn;
    };
    
    // Mark cooldown for a type
    case "markcooldown": {
        _args params [["_typeName", ""]];
        FLO_SM_Cooldowns set [_typeName, serverTime];
        _result = true;
    };
    
    // Get all registered template names
    case "getall": {
        _result = keys FLO_SM_Templates;
    };
    
    // Get all spawnable templates (not on cooldown, under max)
    case "getspawnable": {
        private _spawnable = [];
        {
            if (["canSpawn", [_x]] call FLO_fnc_sideMissionTemplate) then {
                _spawnable pushBack _x;
            };
        } forEach (keys FLO_SM_Templates);
        _result = _spawnable;
    };

    // Spawn a mission instance
    case "spawn": {
        _args params [["_typeName", ""], ["_missionArgs", []]];
        
        private _template = FLO_SM_Templates getOrDefault [_typeName, nil];
        if (isNil "_template") exitWith { 
            diag_log format ["[FLO_SM] Spawn failed: Unknown template %1", _typeName];
            _result = nil; 
        };
        
        // Setup/Validate
        private _fncSetup = _template get "fnc_setup";
        private _canSpawn = [_typeName] call _fncSetup;
        
        if (!_canSpawn) exitWith { 
            diag_log format ["[FLO_SM] Spawn failed: Setup check returned false for %1", _typeName];
            _result = nil; 
        };
        
        // Spawn
        private _fncSpawn = _template get "fnc_spawn";
        _result = [_typeName, _missionArgs] call _fncSpawn;
    };
    
    default {
        diag_log format ["[FLO_SM] Template: Unknown operation: %1", _operation];
        _result = nil;
    };
};

_result

