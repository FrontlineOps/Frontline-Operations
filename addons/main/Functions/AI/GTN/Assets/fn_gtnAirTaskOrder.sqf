/*
    Function: FLO_fnc_gtnAirTaskOrder

    Description:
    Provides a lightweight Air Tasking Order (ATO) system for the GTN Resource Manager.
    Missions only use existing virtual air assets. If no suitable aircraft is
    available the task is skipped.

    Mission Types and Durations:
    - CAS: 5 minutes (combat missions, engage and leave)
    - CAP: 10 minutes (patrol missions, sustained presence)

    Returns:
    HashMap - ATO object with methods:
        _addTask - Add a mission to the queue [position, missionType, aircraftType, altitude, requestSide]
        _processTasks - Assign aircraft for queued tasks and return assigned count
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
                case "CAS": { 300 };      // 5 minutes for close air support
                default { 300 };          // 5 minutes default
            };
        }],

        ["_addTask", {
            params [
                ["_pos", [0,0,0], [[]], [3]],
                ["_missionType", "CAS", [""]],
                ["_aircraftType", "", [""]],
                ["_altitude", 50, [0]],
                ["_requestSide", sideUnknown],
                ["_meta", createHashMap]
            ];
            private _queue = _self get "_taskQueue";
            _queue pushBack [_pos, _missionType, _aircraftType, _altitude, _requestSide, _meta];
            _self set ["_taskQueue", _queue];
        }],

        ["_processTasks", {
            private _queue = _self get "_taskQueue";
            private _mgr = call FLO_fnc_gtnAirAssetManager;
            private _assignedCount = 0;

            ["GTN ATO", 3, format["Processing %1 queued air tasks", count _queue]] call FLO_fnc_log;

            {
                _x params ["_pos", "_mission", "_airType", "_alt", "_requestSide", ["_meta", createHashMap]];
                ["GTN ATO", 3, format["Task %1: %2 mission at %3, alt %4m", _forEachIndex + 1, _mission, _pos, _alt]] call FLO_fnc_log;
                private _hasPlayerSupportMeta = ("playerSupport" in _meta) && {_meta get "playerSupport"};
                private _targetLabel = if ("targetLabel" in _meta) then { _meta get "targetLabel" } else { mapGridPosition _pos };

                private _asset = _mgr call ["_requestAirAsset", [_pos, _mission, _requestSide, _meta]];
                private _air = objNull;
                private _gid = "";
                private _mode = "";
                private _targetSide = sideUnknown;

                // Extract aircraft and group ID from asset result
                if (_asset isNotEqualTo []) then {
                    _air = _asset select 0;
                    _gid = _asset select 1;
                    _mode = _asset select 2;
                    _assignedCount = _assignedCount + 1;

                    _targetSide = if (_requestSide isEqualTo east) then {
                        west
                    } else {
                        if (_requestSide isEqualTo west) then { east } else { sideUnknown };
                    };

                    if (_mode isEqualTo "REAL") then {
                        _air flyInHeight _alt;
                        ["GTN ATO", 3, format["Aircraft assigned: %1 (type: %2), group ID: %3", _air, typeOf _air, _gid]] call FLO_fnc_log;
                        
                        // Reveal intel to aircraft crew so they can engage targets
                        // Uses knowsAbout 4 for immediate engagement capability
                        if (!isNil "FLO_GTN_CapabilityAnalyzer") then {
                            private _enemySide = if (_requestSide isEqualTo east) then { west } else { east };
                            private _revealed = FLO_GTN_CapabilityAnalyzer call ["_revealIntelToUnits", [_pos, 1500, crew _air, _enemySide]];
                            ["GTN ATO", 3, format["Revealed %1 targets to CAS aircraft crew", _revealed]] call FLO_fnc_log;
                        };
                    } else {
                        ["GTN ATO", 3, format["Virtual-only %1 mission assigned to %2 at %3 (no unvirtualize)", _mission, _gid, _pos]] call FLO_fnc_log;
                        if (_hasPlayerSupportMeta) then {
                            [_requestSide, "HQ", format ["%1 active over %2.", toUpper _mission, _targetLabel]] call FLO_fnc_gtnBroadcastCommanderRadioMessage;
                        };
                    };
                } else {
                    ["GTN ATO", 2, "No available virtual air asset for task - skipping"] call FLO_fnc_log;
                };

                if (_mode isEqualTo "VIRTUAL") then { continue };

                if (!isNull _air) then {
                    // Get mission duration based on type
                    private _missionDuration = _self call ["_getMissionDuration", [_mission]];

                    // Determine waypoint pattern based on mission type
                    private _waypointType = ["SAD", "MOVE"] select (toUpper _mission == "CAP");
                    private _patrolRadius = [500, 2000] select (toUpper _mission == "CAP");

                    ["GTN ATO", 3, format["Setting %1 waypoint for %2 at %3 (duration: %4s)", _waypointType, typeOf _air, _pos, _missionDuration]] call FLO_fnc_log;

                    // Delay waypoint setup to ensure crew is fully in vehicle after unvirtualization
                    [{
                        params ["_args"];
                        _args params ["_gid", "_air", "_pos", "_mission", "_patrolRadius"];
                        
                        // Get group from virtualGroups data
                        private _groups = call FLO_fnc_virtualizationGetGroupMap;
                        private _gData = _groups get _gid;
                        if (isNil "_gData") exitWith {
                            ["GTN ATO", 2, format["ATO waypoint setup failed - group %1 not found in virtualGroups", _gid]] call FLO_fnc_log;
                        };
                        
                        private _grp = _gData get "realGroup";
                        if (isNull _grp) exitWith {
                            ["GTN ATO", 2, format["ATO waypoint setup failed - realGroup is null for %1", _gid]] call FLO_fnc_log;
                        };
                        
                        ["GTN ATO", 3, format["ATO Setup: Group=%1, Local=%2, Units=%3", _gid, local _grp, count units _grp]] call FLO_fnc_log;
                        
                        // Clear existing waypoints
                        [_grp] call CBA_fnc_clearWaypoints;

                        // Set combat behavior
                        _grp setBehaviour "COMBAT";
                        _grp setCombatMode "RED";
                        _grp setSpeedMode "FULL";

                        if (toUpper _mission == "CAP") then {
                            // CAP: Multiple patrol waypoints in a pattern
                            private _waypointCount = 4;
                            private _angleStep = 360 / _waypointCount;
                            for "_i" from 0 to (_waypointCount - 1) do {
                                private _angle = _i * _angleStep;
                                private _wpPos = _pos getPos [_patrolRadius, _angle];
                                private _wp = _grp addWaypoint [_wpPos, 100];
                                _wp setWaypointType "MOVE";
                                _wp setWaypointBehaviour "COMBAT";
                                _wp setWaypointCombatMode "RED";
                                _wp setWaypointSpeed "FULL";
                                _wp setWaypointTimeout [60, 90, 120];
                            };

                            // Add a CYCLE waypoint to loop back
                            private _cycleWp = _grp addWaypoint [_pos, 100];
                            _cycleWp setWaypointType "CYCLE";
                        } else {
                            // CAS: Single seek and destroy waypoint on target
                            private _wp = _grp addWaypoint [_pos, 100];
                            _wp setWaypointType "SAD";
                            _wp setWaypointBehaviour "COMBAT";
                            _wp setWaypointCombatMode "RED";
                            _wp setWaypointSpeed "FULL";
                            _wp setWaypointTimeout [30, 45, 60];
                        };

                        // _grp setCurrentWaypoint [_grp, 1];
                        
                        ["GTN ATO", 3, format["Waypoints set for aircraft group %1", _gid]] call FLO_fnc_log;
                    }, [[_gid, _air, _pos, _mission, _patrolRadius]], 1] call CBA_fnc_waitAndExecute;

                    // Mission timer: wait for aircraft to reach target, then run mission duration
                    [_air, _gid, _missionDuration, _mission, _pos, _targetSide, _requestSide, _hasPlayerSupportMeta, _targetLabel] spawn {
                        params ["_a", "_gid", "_duration", "_missionType", "_targetPos", "_targetSide", "_requestSide", "_hasPlayerSupportMeta", "_targetLabel"];

                        private _arrivalRadius = 1000; // Consider "arrived" within 1km
                        private _maxTravelTime = 600;  // Max 10 min to reach target
                        private _travelStart = time;
                        private _alertSent = false;
                        private _noPlayerSince = -1;
                        private _revirtualized = false;

                        // Wait for aircraft to reach target area (or timeout/destroyed)
                        waitUntil {
                            sleep 5;
                            if (!alive _a) exitWith { true };

                            private _remainingMissionSeconds = ((_maxTravelTime - (time - _travelStart)) max 0) + _duration;
                            private _presenceResult = [
                                _a,
                                _gid,
                                _missionType,
                                _targetPos,
                                _remainingMissionSeconds,
                                _noPlayerSince
                            ] call FLO_fnc_gtnAirTryRevirtualizeLiveMission;
                            _presenceResult params ["_transitioned", "_nextNoPlayerSince"];
                            _noPlayerSince = _nextNoPlayerSince;
                            if (_transitioned) exitWith {
                                _revirtualized = true;
                                true
                            };

                            if (
                                !_alertSent &&
                                {_targetSide in [east, west]} &&
                                {[_a, _targetPos, _targetSide] call FLO_fnc_gtnCanSideDetectAirThreat}
                            ) then {
                                [_targetPos, _missionType, _targetSide] call FLO_fnc_gtnAlertIncomingAircraft;
                                _alertSent = true;
                            };

                            private _dist = (getPos _a) distance2D _targetPos;
                            (_dist < _arrivalRadius) || (time - _travelStart > _maxTravelTime)
                        };

                        if (_revirtualized) exitWith {};
                        if (!alive _a) exitWith {
                            ["GTN ATO", 3, format["Aircraft %1 destroyed en route", _gid]] call FLO_fnc_log;
                            if (!isNil "_gid" && {_gid != ""}) then {
                                (call FLO_fnc_gtnAirAssetManager) call ["_releaseAirAsset", [_gid]];
                            };
                        };

                        if (
                            !_alertSent &&
                            {_targetSide in [east, west]} &&
                            {[_a, _targetPos, _targetSide] call FLO_fnc_gtnCanSideDetectAirThreat}
                        ) then {
                            [_targetPos, _missionType, _targetSide] call FLO_fnc_gtnAlertIncomingAircraft;
                            _alertSent = true;
                        };

                        ["GTN ATO", 3, format["Aircraft %1 on station, mission timer started: %2s", _gid, _duration]] call FLO_fnc_log;
                        if (_hasPlayerSupportMeta) then {
                            [_requestSide, "HQ", format ["%1 on station over %2.", toUpper _missionType, _targetLabel]] call FLO_fnc_gtnBroadcastCommanderRadioMessage;
                        };

                        // Refresh intel reveal now that aircraft is on station
                        // Targets may have moved since initial reveal
                        if (!isNil "FLO_GTN_CapabilityAnalyzer" && alive _a) then {
                            private _gData = (call FLO_fnc_virtualizationGetGroupMap) get _gid;
                            private _airSide = _gData get "side";
                            private _enemySide = if (_airSide isEqualTo east) then { west } else { east };
                            private _revealed = FLO_GTN_CapabilityAnalyzer call ["_revealIntelToUnits", [_targetPos, 1500, crew _a, _enemySide]];
                            ["GTN ATO", 4, format["Refreshed intel on station: %1 targets revealed", _revealed]] call FLO_fnc_log;
                        };

                        // Now run the actual mission duration
                        private _missionStart = time;
                        private _missionEnd = _missionStart + _duration;

                        waitUntil {
                            sleep 10;
                            if (!alive _a) exitWith { true };

                            private _remainingMissionSeconds = (_missionEnd - time) max 0;
                            private _presenceResult = [
                                _a,
                                _gid,
                                _missionType,
                                _targetPos,
                                _remainingMissionSeconds,
                                _noPlayerSince
                            ] call FLO_fnc_gtnAirTryRevirtualizeLiveMission;
                            _presenceResult params ["_transitioned", "_nextNoPlayerSince"];
                            _noPlayerSince = _nextNoPlayerSince;
                            if (_transitioned) exitWith {
                                _revirtualized = true;
                                true
                            };

                            time >= _missionEnd
                        };

                        if (_revirtualized) exitWith {};
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
            _assignedCount
        }]
    ]];
};

FLO_GTNAirTaskOrder
