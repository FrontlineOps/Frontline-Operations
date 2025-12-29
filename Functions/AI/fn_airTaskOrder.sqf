/*
    Function: FLO_fnc_airTaskOrder

    Description:
    Provides a lightweight Air Tasking Order (ATO) system for the AI Commander.
    Missions only use existing virtual air assets. If no suitable aircraft is
    available the task is skipped.

    Returns:
    HashMap - ATO object with methods:
        _addTask - Add a mission to the queue [position, missionType, aircraftType, altitude]
        _processTasks - Assign aircraft for queued tasks
*/

if (!isServer) exitWith {};

if (isNil "FLO_airTaskOrder") then {
    FLO_airTaskOrder = createHashMapObject [[
        ["_taskQueue", []],
        ["_addTask", {
            params [
                ["_pos", [0,0,0], [[]], [3]],
                ["_missionType", "CAS", [""]],
                ["_aircraftType", "", [""]],
                ["_altitude", 150, [0]]
            ];
            private _queue = _self get "_taskQueue";
            _queue pushBack [_pos, _missionType, _aircraftType, _altitude];
            _self set ["_taskQueue", _queue];
        }],
        ["_processTasks", {
            private _queue = _self get "_taskQueue";
            private _mgr = call FLO_fnc_airAssetManager;

            ["ATO", 3, format["Processing %1 queued air tasks", count _queue]] call FLO_fnc_log;

            {
                _x params ["_pos", "_mission", "_airType", "_alt"];
                ["ATO", 3, format["Task %1: %2 mission at %3, alt %4m", _forEachIndex + 1, _mission, _pos, _alt]] call FLO_fnc_log;

                private _asset = _mgr call ["_requestAirAsset", [_pos, _mission]];
                private _air = objNull;
                private _gid = -1;
                private _grp = grpNull;

                if (_asset isNotEqualTo objNull) then {
                    _asset params ["_air", "_gid"];
                    _grp = group _air;
                    _air flyInHeight _alt;
                    ["ATO", 3, format["Aircraft assigned: %1 (type: %2), group ID: %3", _air, typeOf _air, _gid]] call FLO_fnc_log;
                } else {
                    ["ATO", 2, "No available virtual air asset for task - skipping"] call FLO_fnc_log;
                };

                if (!isNull _air) then {
                    if (_mission in ["BOMB", "LASER", "CAS"]) then {
                        ["ATO", 3, format["Spawning precision strike: %1 -> %2", typeOf _air, _pos]] call FLO_fnc_log;
                        [_air, _pos, _mission, _alt] spawn FLO_fnc_precisionStrike;
                    } else {
                        ["ATO", 3, format["Setting SAD waypoint for %1", _air]] call FLO_fnc_log;
                        private _wp = _grp addWaypoint [_pos, 0];
                        _wp setWaypointType "SAD";
                        _wp setWaypointBehaviour "COMBAT";
                        _wp setWaypointCombatMode "RED";
                    };
                    [_air, time + 300, _gid] spawn {
                        params ["_a", "_t", "_gid"];
                        waitUntil {sleep 5; time > _t || !alive _a};
                        ["ATO", 3, format["Mission timer expired or aircraft destroyed for group %1", _gid]] call FLO_fnc_log;
                        if (!isNull _a && alive _a && isNull (_a getVariable ["FLO_virtualGroupId", objNull])) then {
                            deleteVehicle _a;
                        };
                        // Release the air asset (clears onMission flag and deactivates)
                        if (!isNil "_gid" && {_gid isNotEqualTo ""}) then {
                            (call FLO_fnc_airAssetManager) call ["_releaseAirAsset", [_gid]];
                        };
                    };
                };
            } forEach _queue;
            _self set ["_taskQueue", []];
        }]
    ]];
};

FLO_airTaskOrder
