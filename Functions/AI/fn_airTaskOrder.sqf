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
                private _gid = "";
                private _grp = grpNull;

                // Extract aircraft and group ID from asset result
                if (_asset isNotEqualTo objNull) then {
                    _air = _asset select 0;
                    _gid = _asset select 1;
                    _grp = group _air;
                    _air flyInHeight _alt;
                    ["ATO", 3, format["Aircraft assigned: %1 (type: %2), group ID: %3", _air, typeOf _air, _gid]] call FLO_fnc_log;
                } else {
                    ["ATO", 2, "No available virtual air asset for task - skipping"] call FLO_fnc_log;
                };

                if (!isNull _air) then {
                    // All air missions use SAD waypoints - simple and reliable
                    // Create multiple SAD waypoints around the target area
                    ["ATO", 3, format["Setting SAD waypoints for %1 at %2", typeOf _air, _pos]] call FLO_fnc_log;

                    // Clear existing waypoints
                    while {count waypoints _grp > 0} do {
                        deleteWaypoint [_grp, 0];
                    };

                    // Set combat behavior
                    _grp setBehaviour "COMBAT";
                    _grp setCombatMode "RED";
                    _grp setSpeedMode "FULL";

                    // Create 3 SAD waypoints in a triangle around the target
                    // This keeps the aircraft circling and engaging in the area
                    private _sadRadius = 500; // Search radius around target

                    for "_i" from 0 to 2 do {
                        private _angle = _i * 120; // 0, 120, 240 degrees
                        private _wpPos = _pos getPos [_sadRadius, _angle];
                        private _wp = _grp addWaypoint [_wpPos, 100];
                        _wp setWaypointType "SAD";
                        _wp setWaypointBehaviour "COMBAT";
                        _wp setWaypointCombatMode "RED";
                        _wp setWaypointSpeed "FULL";
                        _wp setWaypointTimeout [30, 45, 60]; // Stay in area 30-60 seconds
                    };

                    // Add a CYCLE waypoint to loop back
                    private _cycleWp = _grp addWaypoint [_pos, 100];
                    _cycleWp setWaypointType "CYCLE";

                    _grp setCurrentWaypoint [_grp, 1];
                    // Set initial activity timestamp
                    _air setVariable ["FLO_lastActivityTime", time, true];

                    // Activity-based timeout: release aircraft if inactive for 120 seconds
                    // This allows multi-pass attacks to extend the mission duration
                    [_air, _gid] spawn {
                        params ["_a", "_gid"];
                        private _inactivityTimeout = 120; // seconds of inactivity before release
                        private _maxMissionTime = 900;    // absolute max mission time (15 min)
                        private _startTime = time;

                        waitUntil {
                            sleep 5;
                            if (!alive _a) exitWith { true };

                            private _lastActivity = _a getVariable ["FLO_lastActivityTime", _startTime];
                            private _inactive = (time - _lastActivity) > _inactivityTimeout;
                            private _timedOut = (time - _startTime) > _maxMissionTime;

                            _inactive || _timedOut
                        };

                        private _reason = if (!alive _a) then { "destroyed" } else {
                            if ((time - (_a getVariable ["FLO_lastActivityTime", 0])) > _inactivityTimeout) then {
                                "inactivity timeout"
                            } else {
                                "max mission time exceeded"
                            };
                        };
                        ["ATO", 3, format["Mission ended for group %1: %2", _gid, _reason]] call FLO_fnc_log;

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
