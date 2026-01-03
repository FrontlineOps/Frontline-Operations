/*
    Function: FLO_fnc_gtnAirTaskOrder

    Description:
    Provides a lightweight Air Tasking Order (ATO) system for the GTN Resource Manager.
    Missions only use existing virtual air assets. If no suitable aircraft is
    available the task is skipped.

    Mission Types and Durations:
    - CAS/BOMB/LASER: 5 minutes (combat missions, engage and leave)
    - CAP: 10 minutes (patrol missions, sustained presence)
    - SAD: 8 minutes (search and destroy, extended engagement)

    Returns:
    HashMap - ATO object with methods:
        _addTask - Add a mission to the queue [position, missionType, aircraftType, altitude]
        _processTasks - Assign aircraft for queued tasks
*/

if (!isServer) exitWith {};

if (isNil "FLO_GTNAirTaskOrder") then {
    FLO_GTNAirTaskOrder = createHashMapObject [[
        ["_taskQueue", []],

        // Get mission duration based on type
        ["_getMissionDuration", {
            params ["_missionType"];
            switch (toUpper _missionType) do {
                case "CAP": { 600 };      // 10 minutes for patrol
                case "SAD": { 480 };      // 8 minutes for search & destroy
                case "CAS": { 300 };      // 5 minutes for close air support
                case "BOMB": { 300 };     // 5 minutes for bombing runs
                case "LASER": { 300 };    // 5 minutes for precision strikes
                default { 300 };          // 5 minutes default
            };
        }],

        ["_addTask", {
            params [
                ["_pos", [0,0,0], [[]], [3]],
                ["_missionType", "CAS", [""]],
                ["_aircraftType", "", [""]],
                ["_altitude", 50, [0]]
            ];
            private _queue = _self get "_taskQueue";
            _queue pushBack [_pos, _missionType, _aircraftType, _altitude];
            _self set ["_taskQueue", _queue];
        }],

        ["_processTasks", {
            private _queue = _self get "_taskQueue";
            private _mgr = call FLO_fnc_gtnAirAssetManager;

            ["GTN ATO", 3, format["Processing %1 queued air tasks", count _queue]] call FLO_fnc_log;

            {
                _x params ["_pos", "_mission", "_airType", "_alt"];
                ["GTN ATO", 3, format["Task %1: %2 mission at %3, alt %4m", _forEachIndex + 1, _mission, _pos, _alt]] call FLO_fnc_log;

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
                    ["GTN ATO", 3, format["Aircraft assigned: %1 (type: %2), group ID: %3", _air, typeOf _air, _gid]] call FLO_fnc_log;
                } else {
                    ["GTN ATO", 2, "No available virtual air asset for task - skipping"] call FLO_fnc_log;
                };

                if (!isNull _air) then {
                    // Get mission duration based on type
                    private _missionDuration = _self call ["_getMissionDuration", [_mission]];

                    // Determine waypoint pattern based on mission type
                    private _waypointType = if (toUpper _mission == "CAP") then { "MOVE" } else { "SAD" };
                    private _patrolRadius = if (toUpper _mission == "CAP") then { 2000 } else { 500 };
                    private _waypointCount = if (toUpper _mission == "CAP") then { 4 } else { 3 };

                    ["GTN ATO", 3, format["Setting %1 waypoints for %2 at %3 (duration: %4s)", _waypointType, typeOf _air, _pos, _missionDuration]] call FLO_fnc_log;

                    // Clear existing waypoints
                    [_grp] call CBA_fnc_clearWaypoints;

                    // Set combat behavior
                    _grp setBehaviour "COMBAT";
                    _grp setCombatMode "RED";
                    _grp setSpeedMode "FULL";

                    // Create waypoints in a pattern around the target
                    private _angleStep = 360 / _waypointCount;
                    for "_i" from 0 to (_waypointCount - 1) do {
                        private _angle = _i * _angleStep;
                        private _wpPos = _pos getPos [_patrolRadius, _angle];
                        private _wp = _grp addWaypoint [_wpPos, 100];
                        _wp setWaypointType _waypointType;
                        _wp setWaypointBehaviour "COMBAT";
                        _wp setWaypointCombatMode "RED";
                        _wp setWaypointSpeed "FULL";
                        if (_waypointType == "MOVE") then {
                            _wp setWaypointTimeout [60, 90, 120];
                        } else {
                            _wp setWaypointTimeout [30, 45, 60];
                        };
                    };

                    // Add a CYCLE waypoint to loop back
                    private _cycleWp = _grp addWaypoint [_pos, 100];
                    _cycleWp setWaypointType "CYCLE";

                    _grp setCurrentWaypoint [_grp, 1];

                    // Mission timer: wait for aircraft to reach target, then run mission duration
                    [_air, _gid, _missionDuration, _mission, _pos] spawn {
                        params ["_a", "_gid", "_duration", "_missionType", "_targetPos"];

                        private _arrivalRadius = 1000; // Consider "arrived" within 1km
                        private _maxTravelTime = 600;  // Max 10 min to reach target
                        private _travelStart = time;

                        // Wait for aircraft to reach target area (or timeout/destroyed)
                        waitUntil {
                            sleep 5;
                            if (!alive _a) exitWith { true };
                            private _dist = (getPos _a) distance2D _targetPos;
                            (_dist < _arrivalRadius) || (time - _travelStart > _maxTravelTime)
                        };

                        if (!alive _a) exitWith {
                            ["GTN ATO", 3, format["Aircraft %1 destroyed en route", _gid]] call FLO_fnc_log;
                            if (!isNil "_gid" && {_gid != ""}) then {
                                (call FLO_fnc_gtnAirAssetManager) call ["_releaseAirAsset", [_gid]];
                            };
                        };

                        ["GTN ATO", 3, format["Aircraft %1 on station, mission timer started: %2s", _gid, _duration]] call FLO_fnc_log;

                        // Now run the actual mission duration
                        private _missionStart = time;
                        private _missionEnd = _missionStart + _duration;

                        waitUntil {
                            sleep 10;
                            !alive _a || time >= _missionEnd
                        };

                        private _reason = if (!alive _a) then {
                            "aircraft destroyed"
                        } else {
                            format["mission complete (%1s on station)", _duration]
                        };
                        ["GTN ATO", 3, format["Mission ended for %1: %2", _gid, _reason]] call FLO_fnc_log;

                        // Release the air asset
                        if (!isNil "_gid" && {_gid != ""}) then {
                            (call FLO_fnc_gtnAirAssetManager) call ["_releaseAirAsset", [_gid]];
                        };
                    };
                };
            } forEach _queue;
            _self set ["_taskQueue", []];
        }]
    ]];
};

FLO_GTNAirTaskOrder

