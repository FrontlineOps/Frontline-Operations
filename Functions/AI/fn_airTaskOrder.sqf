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
    FLO_airTaskOrder = createHashMapObject [
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
            {
                _x params ["_pos", "_mission", "_airType", "_alt"];
                private _asset = _mgr call ["_requestAirAsset", [_pos, _mission]];
                private _air = objNull;
                private _gid = -1;
                private _grp = grpNull;

                if (_asset isNotEqualTo objNull) then {
                    _asset params ["_air", "_gid"];
                    _grp = group _air;
                    _air flyInHeight _alt;
                } else {
                    diag_log "[FLO][AirTaskOrder] No available virtual air asset for task";
                };

                if (!isNull _air) then {
                    if (_mission in ["BOMB", "LASER", "CAS"]) then {
                        [_air, _pos, _mission, _alt] spawn FLO_fnc_precisionStrike;
                    } else {
                        private _wp = _grp addWaypoint [_pos, 0];
                        _wp setWaypointType "SAD";
                        _wp setWaypointBehaviour "COMBAT";
                        _wp setWaypointCombatMode "RED";
                    };
                    [_air, time + 300, _gid] spawn {
                        params ["_a", "_t", "_gid"];
                        waitUntil {sleep 5; time > _t || !alive _a};
                        if (!isNull _a && alive _a && isNull (_a getVariable ["FLO_virtualGroupId", objNull])) then {
                            deleteVehicle _a;
                        };
                        if (_gid >= 0) then {
                            (call FLO_fnc_airAssetManager) call ["_releaseAirAsset", [_gid]];
                        };
                    };
                };
            } forEach _queue;
            _self set ["_taskQueue", []];
        }]
    ];
};

FLO_airTaskOrder
