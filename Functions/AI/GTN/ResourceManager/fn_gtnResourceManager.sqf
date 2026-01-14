/*
 * Function: FLO_fnc_gtnResourceManager
 * Author: Frontline Operations Development Group
 * Description:
 * Initializes and manages the GTN (Goal Task Network) Commander lifecycle.
 *
 * Arguments: None
 * Return Value: GTN Resource Manager HashMap Object <HASHMAP>
 *
 * Example:
 * [] call FLO_fnc_gtnResourceManager;
 */

["GTN Resource Manager", 3, "Starting GTN Resource Manager"] call FLO_fnc_log;

private _config = call FLO_fnc_gtnConfig;

private _resourceManager = createHashMapObject [[
    ["_config", _config],
    ["_gtnCommander", nil],

    ["_initializeGTN", {
        ["GTN Resource Manager", 3, "Initializing GTN subsystem"] call FLO_fnc_log;

        private _gtn = [_self] call FLO_fnc_gtnCommander;
        _self set ["_gtnCommander", _gtn];

        if (!isNil "_gtn") then {
            _gtn call ["_start", []];
            
            [_gtn] spawn {
                params ["_commander"];
                
                private _interval = (call FLO_fnc_gtnConfig) get "gtnUpdateInterval";
                ["GTN", 3, format["Starting execution loop (%1s interval)", _interval]] call FLO_fnc_log;
                
                while {(_commander get "_isRunning") == 1} do {
                    _commander call ["_update", []];
                    sleep _interval;
                };
            };
            
            ["GTN Resource Manager", 2, "GTN Commander started"] call FLO_fnc_log;
        } else {
            ["GTN Resource Manager", 1, "Failed to initialize GTN Commander"] call FLO_fnc_log;
        };
    }]
]];

// Start GTN immediately
[_resourceManager] spawn {
    params ["_mgr"];
    _mgr call ["_initializeGTN", []];
};

_resourceManager
