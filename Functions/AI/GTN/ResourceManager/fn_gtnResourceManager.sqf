/*
 * Function: FLO_fnc_gtnResourceManager
 * Author: Frontline Operations Development Group
 * Description:
 *   Initializes and manages dual GTN commanders (EAST/WEST).
 *
 * Arguments: None
 * Return Value: GTN Resource Manager HashMap Object <HASHMAP>
 */

["GTN Resource Manager", 3, "Starting GTN Resource Manager"] call FLO_fnc_log;

private _config = call FLO_fnc_gtnConfig;

private _resourceManager = createHashMapObject [[
    ["_config", _config],
    ["_gtnCommander", nil], // Backward compatibility alias (EAST commander)
    ["_gtnCommandersBySide", createHashMap],

    ["_sideKey", {
        params ["_side"];
        if (_side isEqualTo east) exitWith { "EAST" };
        if (_side isEqualTo west) exitWith { "WEST" };
        "EAST"
    }],

    ["_getCommanderBySide", {
        params [["_side", east]];
        private _key = _self call ["_sideKey", [_side]];
        (_self get "_gtnCommandersBySide") get _key
    }],

    ["_getAllCommanders", {
        _self get "_gtnCommandersBySide"
    }],

    ["_startCommanderLoop", {
        params ["_gtn"];
        if (isNil "_gtn") exitWith {};

        [_gtn] spawn {
            params ["_commander"];

            private _interval = _commander get "_updateInterval";
            private _sideKey = _commander get "_sideKey";
            ["GTN", 3, format["Starting %1 execution loop (%2s)", _sideKey, _interval]] call FLO_fnc_log;

            while {(_commander get "_isRunning") == 1} do {
                _commander call ["_update", []];
                sleep _interval;
            };
        };
    }],

    ["_initializeSideCommander", {
        params ["_side"];

        private _key = _self call ["_sideKey", [_side]];
        private _existing = (_self get "_gtnCommandersBySide") get _key;
        if (!isNil "_existing") exitWith { _existing };

        private _sideCtx = [_side] call FLO_fnc_gtnSideContext;
        private _gtn = [_self, _sideCtx] call FLO_fnc_gtnCommander;

        if (!isNil "_gtn") then {
            (_self get "_gtnCommandersBySide") set [_key, _gtn];
            _gtn call ["_start", []];
            _self call ["_startCommanderLoop", [_gtn]];
            ["GTN Resource Manager", 2, format["%1 commander started", _key]] call FLO_fnc_log;
        } else {
            ["GTN Resource Manager", 1, format["Failed to initialize %1 commander", _key]] call FLO_fnc_log;
        };

        _gtn
    }],

    ["_initializeGTN", {
        ["GTN Resource Manager", 3, "Initializing dual GTN subsystem"] call FLO_fnc_log;

        private _map = _self get "_gtnCommandersBySide";
        if (count (keys _map) > 0) exitWith {
            ["GTN Resource Manager", 3, "Dual GTN already initialized"] call FLO_fnc_log;
        };

        private _sides = FLO_MissionSides;
        {
            if (_x in [east, west]) then {
                _self call ["_initializeSideCommander", [_x]];
            };
        } forEach _sides;

        // Backward compatibility: preserve singleton field as EAST commander.
        _self set ["_gtnCommander", _self call ["_getCommanderBySide", [east]]];

        // Keep commander objects server-local. They contain circular references
        // and are not safe to publicVariable.
        FLO_GTN_CommandersBySide = _self get "_gtnCommandersBySide";

        // Publish only lightweight side status for clients/debug UI.
        private _pubState = createHashMapFromArray [
            ["EAST", !isNil {(_self get "_gtnCommandersBySide") get "EAST"}],
            ["WEST", !isNil {(_self get "_gtnCommandersBySide") get "WEST"}]
        ];
        FLO_GTN_CommandersBySideState = _pubState;
        publicVariable "FLO_GTN_CommandersBySideState";

        ["GTN Resource Manager", 2, format["Dual GTN ready (%1 commanders)", count (keys (_self get "_gtnCommandersBySide"))]] call FLO_fnc_log;
    }]
]];

// Start GTN immediately
[_resourceManager] spawn {
    params ["_mgr"];
    _mgr call ["_initializeGTN", []];
};

_resourceManager
