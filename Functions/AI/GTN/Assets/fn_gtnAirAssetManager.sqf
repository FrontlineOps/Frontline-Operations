/*
    Function: FLO_fnc_gtnAirAssetManager

    Description:
    Manages air groups that exist in the virtualization system.
    For target areas inside the shared virtualization activation bubble, the
    manager unvirtualizes and assigns a real aircraft.
    For remote areas, the manager keeps aircraft virtual and applies a
    virtual combat effect instead of spawning real assets.

    Returns:
    HashMap object with methods to request and release air assets.

    Example:
        private _mgr = call FLO_fnc_gtnAirAssetManager;
        private _result = _mgr call ["_requestAirAsset", [getPos player]];
        if (count _result > 0) then {
            private _aircraft = _result select 0;
            // Use the aircraft for support
        };
*/

params [];

if (isNil "FLO_GTNAirAssetManager") then {
    FLO_GTNAirAssetManager = createHashMapObject [[
        ["missions", createHashMap],
        ["_perf", createHashMapFromArray [
            ["requestSlowThresholdMs", 10],
            ["releaseSlowThresholdMs", 5],
            ["liveCheckSlowThresholdMs", 5],
            ["requestsTotal", 0],
            ["requestsReal", 0],
            ["requestsVirtual", 0],
            ["requestsFailed", 0],
            ["releasesTotal", 0],
            ["rtbOrdersTotal", 0],
            ["lastRequestMs", 0],
            ["peakRequestMs", 0],
            ["lastReleaseMs", 0],
            ["peakReleaseMs", 0],
            ["lastLiveCheckMs", 0],
            ["peakLiveCheckMs", 0],
            ["slowRequestCount", 0],
            ["slowReleaseCount", 0],
            ["slowLiveCheckCount", 0],
            ["lastRequestInfo", createHashMap],
            ["lastReleaseInfo", createHashMap],
            ["lastLiveCheckInfo", createHashMap]
        ]],

        ["_getPerf", {
            _self get "_perf"
        }],

        ["_recordRequestPerf", {
            params [
                ["_dtMs", 0],
                ["_missionType", ""],
                ["_requestSide", sideUnknown],
                ["_result", "NONE"],
                ["_liveArea", false],
                ["_candidateCount", 0],
                ["_availableCount", 0],
                ["_activated", false],
                ["_selectedId", ""],
                ["_phaseLiveMs", 0],
                ["_phaseActivateMs", 0],
                ["_phaseVirtualMs", 0]
            ];

            private _perf = _self get "_perf";
            _perf set ["requestsTotal", (_perf get "requestsTotal") + 1];
            _perf set ["lastRequestMs", _dtMs];
            if (_dtMs > (_perf get "peakRequestMs")) then {
                _perf set ["peakRequestMs", _dtMs];
            };

            switch (_result) do {
                case "REAL": { _perf set ["requestsReal", (_perf get "requestsReal") + 1]; };
                case "VIRTUAL": { _perf set ["requestsVirtual", (_perf get "requestsVirtual") + 1]; };
                default { _perf set ["requestsFailed", (_perf get "requestsFailed") + 1]; };
            };

            _perf set ["lastRequestInfo", createHashMapFromArray [
                ["missionType", _missionType],
                ["requestSide", str _requestSide],
                ["result", _result],
                ["liveArea", _liveArea],
                ["candidateCount", _candidateCount],
                ["availableCount", _availableCount],
                ["activated", _activated],
                ["selectedId", _selectedId],
                ["phaseLiveMs", _phaseLiveMs],
                ["phaseActivateMs", _phaseActivateMs],
                ["phaseVirtualMs", _phaseVirtualMs],
                ["missionCount", count keys (_self get "missions")]
            ]];

            if (_dtMs >= (_perf get "requestSlowThresholdMs")) then {
                _perf set ["slowRequestCount", (_perf get "slowRequestCount") + 1];
                diag_log format [
                    "[FLO][PERF] Air asset manager request %1 side=%2 result=%3 live=%4 candidates=%5 available=%6 activated=%7 selected=%8 in %9 ms | liveCheck=%10 activate=%11 virtualEffect=%12 missions=%13",
                    _missionType,
                    _requestSide,
                    _result,
                    _liveArea,
                    _candidateCount,
                    _availableCount,
                    _activated,
                    _selectedId,
                    _dtMs,
                    _phaseLiveMs,
                    _phaseActivateMs,
                    _phaseVirtualMs,
                    count keys (_self get "missions")
                ];
            };
        }],

        ["_recordReleasePerf", {
            params [
                ["_dtMs", 0],
                ["_gid", ""],
                ["_released", false],
                ["_sentRTB", false],
                ["_missionState", ""]
            ];

            private _perf = _self get "_perf";
            _perf set ["releasesTotal", (_perf get "releasesTotal") + 1];
            if (_sentRTB) then {
                _perf set ["rtbOrdersTotal", (_perf get "rtbOrdersTotal") + 1];
            };

            _perf set ["lastReleaseMs", _dtMs];
            if (_dtMs > (_perf get "peakReleaseMs")) then {
                _perf set ["peakReleaseMs", _dtMs];
            };

            _perf set ["lastReleaseInfo", createHashMapFromArray [
                ["groupId", _gid],
                ["released", _released],
                ["sentRTB", _sentRTB],
                ["missionState", _missionState],
                ["missionCount", count keys (_self get "missions")]
            ]];

            if (_dtMs >= (_perf get "releaseSlowThresholdMs")) then {
                _perf set ["slowReleaseCount", (_perf get "slowReleaseCount") + 1];
                diag_log format [
                    "[FLO][PERF] Air asset manager release gid=%1 released=%2 sentRTB=%3 state=%4 in %5 ms | missions=%6",
                    _gid,
                    _released,
                    _sentRTB,
                    _missionState,
                    _dtMs,
                    count keys (_self get "missions")
                ];
            };
        }],

        // A target area is "live" only when it is inside the shared player
        // activation bubble. Remote air support stays virtual.
        ["_isLiveArea", {
            params ["_targetPos", ["_radius", -1]];

            private _t0 = diag_tickTime;
            if (_radius < 0) then {
                _radius = FLO_virtualGroups get "_activationDistance";
            };
            if ((FLO_VirtUpdate get "lastPlayerCacheTime") <= 0) then {
                call FLO_fnc_virtualizationCachePlayers;
            };

            private _nearestPlayerDist = [_targetPos] call FLO_fnc_virtualizationGetNearestCachedPlayerDistance;
            private _result = [_targetPos, _radius] call FLO_fnc_virtualizationIsPositionWithinActivationRange;

            private _dtMs = (diag_tickTime - _t0) * 1000;
            private _perf = _self get "_perf";
            _perf set ["lastLiveCheckMs", _dtMs];
            if (_dtMs > (_perf get "peakLiveCheckMs")) then {
                _perf set ["peakLiveCheckMs", _dtMs];
            };

            _perf set ["lastLiveCheckInfo", createHashMapFromArray [
                ["radius", _radius],
                ["nearestPlayerDist", _nearestPlayerDist],
                ["result", _result]
            ]];

            if (_dtMs >= (_perf get "liveCheckSlowThresholdMs")) then {
                _perf set ["slowLiveCheckCount", (_perf get "slowLiveCheckCount") + 1];
                diag_log format [
                    "[FLO][PERF] Air asset manager liveArea nearestPlayer=%1 radius=%2 result=%3 in %4 ms",
                    round _nearestPlayerDist,
                    _radius,
                    _result,
                    _dtMs
                ];
            };

            _result
        }],

        ["_getVirtualMissionDuration", {
            params ["_missionType"];
            switch (toUpper _missionType) do {
                case "CAP": { 600 };
                case "RECON": { 180 };
                case "CAS": { 300 };
                default { 300 };
            };
        }],

        ["_applyVirtualAirEffect", {
            params ["_airSide", "_targetPos", "_missionType"];

            private _enemySide = if (_airSide isEqualTo east) then { west } else { east };
            private _groups = FLO_virtualGroups get "_groups";
            private _radius = switch (toUpper _missionType) do {
                case "CAP": { 1800 };
                default { 800 };
            };

            private _candidates = [];
            {
                private _gid = _x;
                private _gData = _y;
                if ((_gData get "side") != _enemySide) then { continue };
                if (_gData get "isActive") then { continue };

                private _dist = (_gData get "position") distance2D _targetPos;
                if (_dist <= _radius) then {
                    _candidates pushBack [_dist, _gid, _gData];
                };
            } forEach _groups;

            if (count _candidates == 0) exitWith { 0 };

            _candidates sort true;

            private _targetsToHit = switch (toUpper _missionType) do {
                case "CAP": { 1 };
                default { 1 };
            };

            private _lossFactor = switch (toUpper _missionType) do {
                case "CAP": { 0.20 };
                default { 0.25 };
            };

            private _totalLosses = 0;
            for "_i" from 0 to ((_targetsToHit min (count _candidates)) - 1) do {
                private _entry = _candidates select _i;
                _entry params ["_dist", "_gid", "_gData"];

                private _currentCount = _gData get "unitCount";
                if (_currentCount <= 0) then { continue };

                private _falloff = 1 - ((_dist / _radius) * 0.5);
                private _loss = ceil ((_currentCount * _lossFactor * _falloff) max 1);
                if (_loss > _currentCount) then { _loss = _currentCount; };

                private _newCount = _currentCount - _loss;
                if (_newCount <= 0) then {
                    _gData set ["unitCount", 0];
                    [FLO_virtualGroups, _gid] call FLO_fnc_virtualizationRemoveGroup;
                } else {
                    _gData set ["unitCount", _newCount];
                    _groups set [_gid, _gData];
                };

                _totalLosses = _totalLosses + _loss;
            };

            _totalLosses
        }],

        ["_scheduleVirtualMissionRelease", {
            params ["_gid", "_duration"];

            [_gid, _duration] spawn {
                params ["_gid", "_duration"];
                sleep _duration;

                if (!isNil "FLO_virtualGroups") then {
                    private _groups = FLO_virtualGroups get "_groups";
                    if (_gid in _groups) then {
                        private _gData = _groups get _gid;
                        [_gData] call FLO_fnc_virtualizationClearMissionLock;
                        [_gData] call FLO_fnc_virtualizationClearExecutionState;
                    };
                };

                if (!isNil "FLO_GTNAirAssetManager") then {
                    (FLO_GTNAirAssetManager get "missions") deleteAt _gid;
                };

                ["GTN Air Asset Manager", 3, format["Virtual air mission complete for %1", _gid]] call FLO_fnc_log;
            };
        }],

        ["_requestAirAsset", {
            params ["_targetPos", ["_missionType", "CAS"], ["_requestSide", sideUnknown]];

            private _tRequest = diag_tickTime;
            private _candidateCount = 0;
            private _availableCount = 0;
            private _activated = false;
            private _selectedId = "";
            private _phaseLiveMs = 0;
            private _phaseActivateMs = 0;
            private _phaseVirtualMs = 0;

            if (isNil "FLO_virtualGroups") exitWith {
                _self call ["_recordRequestPerf", [
                    (diag_tickTime - _tRequest) * 1000,
                    _missionType,
                    _requestSide,
                    "NONE",
                    false,
                    0,
                    0,
                    false,
                    "",
                    0,
                    0,
                    0
                ]];
                []
            };
            private _groups = FLO_virtualGroups get "_groups";
            private _airGroups = [];
            {
                private _gData = _y;
                private _gType = _gData get "groupType";
                if (_gType in ["helicopter", "jet", "air"]) then {
                    if (_requestSide in [east, west] && {(_gData get "side") != _requestSide}) then {
                        continue;
                    };
                    if !([_gData] call FLO_fnc_gtnSupportAssetCanProvideAbstractSupport) then {
                        continue;
                    };
                    _airGroups pushBack [_x, _gData];
                };
            } forEach _groups;

            _candidateCount = count _airGroups;
            if (_candidateCount == 0) exitWith {
                _self call ["_recordRequestPerf", [
                    (diag_tickTime - _tRequest) * 1000,
                    _missionType,
                    _requestSide,
                    "NONE",
                    false,
                    _candidateCount,
                    0,
                    false,
                    "",
                    0,
                    0,
                    0
                ]];
                []
            };

            // Filter out groups already on mission
            private _missions = _self get "missions";
            _airGroups = _airGroups select {
                private _id = _x select 0;
                !(_id in _missions)
            };
            _availableCount = count _airGroups;
            if (_availableCount == 0) exitWith {
                _self call ["_recordRequestPerf", [
                    (diag_tickTime - _tRequest) * 1000,
                    _missionType,
                    _requestSide,
                    "NONE",
                    false,
                    _candidateCount,
                    _availableCount,
                    false,
                    "",
                    0,
                    0,
                    0
                ]];
                []
            };

            // Select nearest group to target (single pass)
            private _sel = [];
            private _bestDist = 1e12;
            {
                _x params ["_gid", "_gData"];
                private _dist = (_gData get "position") distance2D _targetPos;
                if (_dist < _bestDist) then {
                    _bestDist = _dist;
                    _sel = [_gid, _gData];
                };
            } forEach _airGroups;
            if (count _sel == 0) exitWith {
                _self call ["_recordRequestPerf", [
                    (diag_tickTime - _tRequest) * 1000,
                    _missionType,
                    _requestSide,
                    "NONE",
                    false,
                    _candidateCount,
                    _availableCount,
                    false,
                    "",
                    0,
                    0,
                    0
                ]];
                []
            };

            private _gid = _sel select 0;
            private _gdata = _sel select 1;
            _selectedId = _gid;
            private _tLive = diag_tickTime;
            private _isLiveArea = _self call ["_isLiveArea", [_targetPos]];
            _phaseLiveMs = (diag_tickTime - _tLive) * 1000;

            if (_isLiveArea && {!(_gdata get "isActive")}) then {
                private _tActivate = diag_tickTime;
                _activated = [_gid, _gdata] call FLO_fnc_virtualizationTryActivateGroup;
                _phaseActivateMs = (diag_tickTime - _tActivate) * 1000;
                if (!_activated) then {
                    _isLiveArea = false;
                };
            };

            if (!_isLiveArea) exitWith {
                [_gdata, "AIR", toUpper _missionType] call FLO_fnc_virtualizationSetMissionLock;
                (_self get "missions") set [_gid, "VIRTUAL"];

                private _duration = _self call ["_getVirtualMissionDuration", [_missionType]];
                private _tVirtual = diag_tickTime;
                private _losses = _self call ["_applyVirtualAirEffect", [_gdata get "side", _targetPos, _missionType]];
                _phaseVirtualMs = (diag_tickTime - _tVirtual) * 1000;
                _self call ["_scheduleVirtualMissionRelease", [_gid, _duration]];

                ["GTN Air Asset Manager", 3, format[
                    "Virtual-only %1 mission by %2 at %3 (losses=%4, duration=%5s)",
                    toUpper _missionType,
                    _gid,
                    _targetPos,
                    _losses,
                    round _duration
                ]] call FLO_fnc_log;

                _self call ["_recordRequestPerf", [
                    (diag_tickTime - _tRequest) * 1000,
                    _missionType,
                    _requestSide,
                    "VIRTUAL",
                    false,
                    _candidateCount,
                    _availableCount,
                    false,
                    _selectedId,
                    _phaseLiveMs,
                    0,
                    _phaseVirtualMs
                ]];

                [objNull, _gid, "VIRTUAL"]
            };

            private _realGroup = _gdata get "realGroup";
            if (isNull _realGroup) exitWith {
                _self call ["_recordRequestPerf", [
                    (diag_tickTime - _tRequest) * 1000,
                    _missionType,
                    _requestSide,
                    "NONE",
                    true,
                    _candidateCount,
                    _availableCount,
                    _activated,
                    _selectedId,
                    _phaseLiveMs,
                    _phaseActivateMs,
                    0
                ]];
                []
            };
            
            // Mark group as mission-locked to prevent deactivation
            [_gdata, "AIR", toUpper _missionType] call FLO_fnc_virtualizationSetMissionLock;
            ["GTN Air Asset Manager", 3, format["Marked group %1 with AIR mission lock", _gid]] call FLO_fnc_log;

            // Clear any existing waypoints
            [_realGroup] call CBA_fnc_clearWaypoints;
            ["GTN Air Asset Manager", 3, format["Cleared existing waypoints for group %1", _gid]] call FLO_fnc_log;

            // Determine aircraft vehicle
            private _veh = objNull;
            {
                if (vehicle _x != _x) then {
                    private _v = vehicle _x;
                    if (isNull _veh) then { _veh = _v; };
                };
            } forEach units _realGroup;
            if (isNull _veh) then { _veh = vehicle (leader _realGroup); };
            if (isNull _veh) exitWith {
                _self call ["_recordRequestPerf", [
                    (diag_tickTime - _tRequest) * 1000,
                    _missionType,
                    _requestSide,
                    "NONE",
                    true,
                    _candidateCount,
                    _availableCount,
                    _activated,
                    _selectedId,
                    _phaseLiveMs,
                    _phaseActivateMs,
                    0
                ]];
                []
            };

            (_self get "missions") set [_gid, _veh];
            _self call ["_recordRequestPerf", [
                (diag_tickTime - _tRequest) * 1000,
                _missionType,
                _requestSide,
                "REAL",
                true,
                _candidateCount,
                _availableCount,
                _activated,
                _selectedId,
                _phaseLiveMs,
                _phaseActivateMs,
                0
            ]];

            [_veh, _gid, "REAL"]
        }],
        ["_releaseAirAsset", {
            params ["_gid"];
            private _tRelease = diag_tickTime;
            private _missions = _self get "missions";
            private _released = false;
            private _sentRTB = false;
            private _missionState = "";

            ["GTN Air Asset Manager", 4, format["_releaseAirAsset called for: '%1'", _gid]] call FLO_fnc_log;

            if (_gid in _missions) then {
                _missionState = _missions get _gid;
                private _groups = FLO_virtualGroups get "_groups";
                if (_gid in _groups) then {
                    private _data = _groups get _gid;
                    [_data] call FLO_fnc_virtualizationClearMissionLock;
                    if !(_missionState isEqualTo "VIRTUAL") then {
                        _self call ["_sendToRTB", [_gid]];
                        _sentRTB = true;
                    } else {
                        [_data] call FLO_fnc_virtualizationClearExecutionState;
                    };
                    _released = true;
                } else {
                    ["GTN Air Asset Manager", 2, format["Group %1 not found in virtualGroups - may have been destroyed", _gid]] call FLO_fnc_log;
                };
                (_self get "missions") deleteAt _gid;
                ["GTN Air Asset Manager", 3, format["Released air asset %1", _gid]] call FLO_fnc_log;
            };

            _self call ["_recordReleasePerf", [
                (diag_tickTime - _tRelease) * 1000,
                _gid,
                _released,
                _sentRTB,
                str _missionState
            ]];
        }],

        // Get RTB position for an aircraft (returns original spawn position)
        ["_getRTBPosition", {
            params ["_groupId"];
            private _groups = FLO_virtualGroups get "_groups";
            if !(_groupId in _groups) exitWith {
                ["GTN Air Asset Manager", 2, format["_getRTBPosition: Group %1 not in virtualGroups", _groupId]] call FLO_fnc_log;
                [0,0,0]
            };
            private _gData = _groups get _groupId;
            _gData get "spawnPosition"
        }],

        // Send aircraft to RTB - works for both active (real) and virtual groups
        ["_sendToRTB", {
            params ["_groupId"];

            private _groups = FLO_virtualGroups get "_groups";
            if !(_groupId in _groups) exitWith {
                ["GTN Air Asset Manager", 2, format["_sendToRTB: Group %1 not in virtualGroups", _groupId]] call FLO_fnc_log;
            };

            private _rtbPos = _self call ["_getRTBPosition", [_groupId]];
            private _gData = _groups get _groupId;
            private _isActive = _gData get "isActive";
            private _realGroup = _gData get "realGroup";

            if (_isActive && !isNull _realGroup) then {
                // Active group - set real waypoints
                [_realGroup] call CBA_fnc_clearWaypoints;

                _realGroup setBehaviour "SAFE";
                _realGroup setCombatMode "GREEN";
                _realGroup setSpeedMode "NORMAL";

                private _wp = _realGroup addWaypoint [_rtbPos, 50];
                _wp setWaypointType "MOVE";
                _wp setWaypointBehaviour "SAFE";
                _wp setWaypointCombatMode "GREEN";
                _wp setWaypointSpeed "NORMAL";

                private _loiterWp = _realGroup addWaypoint [_rtbPos, 500];
                _loiterWp setWaypointType "LOITER";
                _loiterWp setWaypointLoiterType "CIRCLE";
                _loiterWp setWaypointLoiterRadius 500;

                // _realGroup setCurrentWaypoint [_realGroup, 1];

                ["GTN Air Asset Manager", 3, format["RTB waypoints set for %1 to %2", _groupId, _rtbPos]] call FLO_fnc_log;
            } else {
                // Virtual group - use virtual waypoint system
                private _waypoints = [
                    [_rtbPos, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", 50],
                    [_rtbPos, "LOITER", "SAFE", "LIMITED", "COLUMN", "GREEN", 500]
                ];
                [_groupId, _waypoints, false, true, "GTN_AIR"] call FLO_fnc_updateVirtualGroupWaypoints;

                ["GTN Air Asset Manager", 3, format["Virtual RTB waypoints for %1 to %2", _groupId, _rtbPos]] call FLO_fnc_log;
            };

            [_gData, "RTB"] call FLO_fnc_virtualizationSetExecutionState;
            true
        }],

        // Get available aircraft for missions
        ["_getAvailableAircraft", {
            if (isNil "FLO_virtualGroups") exitWith { [] };
            private _groups = FLO_virtualGroups get "_groups";
            private _missions = _self get "missions";
            private _available = [];

            {
                private _gData = _y;
                private _gType = _gData get "groupType";
                if (_gType in ["helicopter", "jet", "air"]) then {
                    if !(_x in _missions) then {
                        if !([_gData] call FLO_fnc_gtnSupportAssetCanProvideAbstractSupport) then {
                            continue;
                        };
                        _available pushBack _x;
                    };
                };
            } forEach _groups;

            _available
        }]
    ]];
};

FLO_GTNAirAssetManager

