/*
 * Function: FLO_fnc_vehicleCleanupManager
 * Author: Frontline Operations Development Group
 * Description:
 *   Manages the abandoned derelict vehicle cleanup worker.
 *
 * Arguments:
 * 0: Mode <STRING> - "init", "start", "stop"
 *
 * Return Value:
 * BOOL - True on success
 */

params [["_mode", "start", [""]]];

if (!isServer) exitWith { false };

if (isNil "FLO_VehicleCleanup") then {
    FLO_VehicleCleanup = createHashMapFromArray [
        ["enabled", false],
        ["pfhId", -1],
        ["interval", 60],
        ["graceTime", 600],
        ["playerSafeRadius", 150],
        ["installationSafeRadius", 500],
        ["candidateSince", createHashMap]
    ];
};

private _state = FLO_VehicleCleanup;

switch (toLower _mode) do {
    case "init": {
        ["VEHICLE_CLEANUP", 3, "Vehicle cleanup manager initialized"] call FLO_fnc_log;
        true
    };

    case "start": {
        if (_state get "enabled") exitWith { true };

        _state set ["enabled", true];
        private _interval = _state get "interval";
        private _pfhId = [FLO_fnc_vehicleCleanupRun, _interval, []] call CBA_fnc_addPerFrameHandler;
        _state set ["pfhId", _pfhId];

        ["VEHICLE_CLEANUP", 3, format [
            "Vehicle cleanup started (interval=%1s grace=%2s)",
            _interval,
            _state get "graceTime"
        ]] call FLO_fnc_log;
        true
    };

    case "stop": {
        if !(_state get "enabled") exitWith { true };

        _state set ["enabled", false];
        private _pfhId = _state get "pfhId";
        if (_pfhId >= 0) then {
            [_pfhId] call CBA_fnc_removePerFrameHandler;
            _state set ["pfhId", -1];
        };
        _state set ["candidateSince", createHashMap];

        ["VEHICLE_CLEANUP", 3, "Vehicle cleanup stopped"] call FLO_fnc_log;
        true
    };

    default {
        ["VEHICLE_CLEANUP", 1, format ["Unknown manager mode: %1", _mode]] call FLO_fnc_log;
        false
    };
};
