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
        if (_result isNotEqualTo []) then {
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
                _radius = (["activationDistance"] call FLO_fnc_virtualizationGetConfigValue) * FLO_AirActivationDistanceMultiplier;
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

        ["_scheduleVirtualMissionRelease", {
            params ["_gid", "_duration"];

            [_gid, _duration] spawn {
                params ["_gid", "_duration"];
                sleep _duration;

                if (!isNil "FLO_VirtualForceRegistry") then {
                    private _groups = call FLO_fnc_virtualizationGetGroupMap;
                    if (_gid in _groups) then {
                        private _gData = _groups get _gid;
                        [_gData] call FLO_fnc_virtualizationClearMissionLock;
                        [_gData] call FLO_fnc_virtualizationClearExecutionState;
                        [_gid] call FLO_fnc_gtnAirParkCombatGroupOffMap;
                    };
                };

                if (!isNil "FLO_GTNAirAssetManager") then {
                    (FLO_GTNAirAssetManager get "missions") deleteAt _gid;
                };

                ["GTN Air Asset Manager", 3, format["Virtual air mission complete for %1", _gid]] call FLO_fnc_log;
            };
        }],

        ["_scheduleRTBCompletion", {
            params ["_gid", "_rtbPos", ["_timeoutSeconds", 900]];

            [_gid, +_rtbPos, _timeoutSeconds] spawn {
                params ["_gid", "_rtbPos", "_timeoutSeconds"];

                private _deadline = diag_tickTime + _timeoutSeconds;
                private _arrivalRadius = 300;

                waitUntil {
                    sleep 10;

                    if (isNil "FLO_GTNAirAssetManager") exitWith { true };
                    if (isNil "FLO_VirtualForceRegistry") exitWith { true };

                    private _missions = FLO_GTNAirAssetManager get "missions";
                    if !(_gid in _missions) exitWith { true };

                    private _groups = call FLO_fnc_virtualizationGetGroupMap;
                    if !(_gid in _groups) exitWith { true };

                    private _gData = _groups get _gid;
                    ((_gData get "position") distance2D _rtbPos <= _arrivalRadius) || {diag_tickTime >= _deadline}
                };

                if (isNil "FLO_GTNAirAssetManager" || {isNil "FLO_VirtualForceRegistry"}) exitWith {};

                private _missions = FLO_GTNAirAssetManager get "missions";
                if !(_gid in _missions) exitWith {};

                private _groups = call FLO_fnc_virtualizationGetGroupMap;
                if (_gid in _groups) then {
                    private _gData = _groups get _gid;
                    [_gData] call FLO_fnc_virtualizationClearMissionLock;
                    [_gData] call FLO_fnc_virtualizationClearExecutionState;

                    if (((_gData get "position") distance2D _rtbPos) <= _arrivalRadius) then {
                        ["GTN Air Asset Manager", 3, format["Air asset %1 completed RTB", _gid]] call FLO_fnc_log;
                    } else {
                        ["GTN Air Asset Manager", 2, format["Air asset %1 RTB timed out before reaching base", _gid]] call FLO_fnc_log;
                    };
                    [_gid] call FLO_fnc_gtnAirParkCombatGroupOffMap;
                };

                _missions deleteAt _gid;
            };
        }],

        ["_requestAirAsset", {
            params ["_targetPos", ["_missionType", "CAS"], ["_requestSide", sideUnknown], ["_meta", createHashMap]];

            private _tRequest = diag_tickTime;
            private _candidateCount = 0;
            private _availableCount = 0;
            private _activated = false;
            private _selectedId = "";
            private _phaseLiveMs = 0;
            private _phaseActivateMs = 0;
            private _phaseVirtualMs = 0;

            if (isNil "FLO_VirtualForceRegistry") exitWith { [] };
            if !(_requestSide in [east, west]) exitWith { [] };
            _missionType = toUpper _missionType;

            private _groups = call FLO_fnc_virtualizationGetGroupMap;
            private _airGroups = [];
            {
                private _gData = _y;
                private _gType = _gData get "groupType";
                if (_gType in ["helicopter", "jet", "air"]) then {
                    if ((_gData get "side") != _requestSide) then {
                        continue;
                    };
                    if (_gData get "isActive") then { continue };
                    if !([_gData] call FLO_fnc_gtnSupportAssetCanProvideAbstractSupport) then {
                        continue;
                    };
                    _airGroups pushBack [_x, _gData];
                };
            } forEach _groups;

            _candidateCount = count _airGroups;
            if (_candidateCount == 0) exitWith { [] };

            private _missions = _self get "missions";
            _airGroups = _airGroups select {
                private _id = _x select 0;
                !(_id in _missions)
            };
            if (_missionType == "CAP") then {
                private _fighters = _airGroups select { ((_x select 1) get "groupType") == "jet" };
                if (_fighters isNotEqualTo []) then { _airGroups = _fighters; };
            };
            _availableCount = count _airGroups;
            if (_availableCount == 0) exitWith { [] };

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
            if (_sel isEqualTo []) exitWith { [] };

            private _gid = _sel select 0;
            private _gdata = _sel select 1;
            _selectedId = _gid;
            private _forceLive = ("forceLive" in _meta) && {_meta get "forceLive"};
            private _playerRequested = ("playerSupport" in _meta) && {_meta get "playerSupport"};
            private _targetGroupIds = if ("targetGroupIds" in _meta) then { +(_meta get "targetGroupIds") } else { [] };
            private _areaContact = ("areaContact" in _meta) && {_meta get "areaContact"};
            if (_missionType == "CAS" && {!_forceLive} && {_targetGroupIds isEqualTo []} && {!_areaContact}) exitWith {
                ["GTN Air Asset Manager", 2, format ["Rejected virtual CAS by %1 without reported target intelligence", _gid]] call FLO_fnc_log;
                []
            };

            private _tLive = diag_tickTime;
            private _isLiveArea = if (_forceLive) then {
                true
            } else {
                _self call ["_isLiveArea", [_targetPos]]
            };
            _phaseLiveMs = (diag_tickTime - _tLive) * 1000;

            private _routePositions = [_requestSide, _targetPos] call FLO_fnc_gtnAirResolveReserveRoutePositions;
            _routePositions params ["_reservePos", "_ingressPos", "_egressPos"];
            private _missionId = format ["AIR_%1_%2_%3", [_requestSide] call FLO_fnc_sideKey, _gid, round (diag_tickTime * 1000)];
            private _missionRecord = createHashMapFromArray [
                ["missionId", _missionId],
                ["groupId", _gid],
                ["side", _requestSide],
                ["missionType", _missionType],
                ["aircraftGroupType", _gdata get "groupType"],
                ["targetPos", +_targetPos],
                ["targetGroupIds", _targetGroupIds],
                ["targetObjectiveId", if ("targetObjectiveId" in _meta) then { _meta get "targetObjectiveId" } else { "" }],
                ["areaContact", _areaContact],
                ["contactConfidence", if ("contactConfidence" in _meta) then { _meta get "contactConfidence" } else { 1 }],
                ["contactAgeSeconds", if ("contactAgeSeconds" in _meta) then { _meta get "contactAgeSeconds" } else { 0 }],
                ["uncertaintyRadius", if ("uncertaintyRadius" in _meta) then { _meta get "uncertaintyRadius" } else { 0 }],
                ["reservePos", _reservePos],
                ["ingressPos", _ingressPos],
                ["egressPos", _egressPos],
                ["mode", ""],
                ["treasuryCost", 0],
                ["localSupplyCost", 0],
                ["supplyNodeId", ""],
                ["supplyObjectiveId", ""],
                ["virtualLosses", 0],
                ["virtualGroupsHit", 0],
                ["virtualGroupsDestroyed", 0]
            ];

            if (_isLiveArea) then {
                [_gid, _ingressPos] call FLO_fnc_virtualizationUpdateGroupPosition;
                [_gid, createHashMapFromArray [["forceVirtual", false], ["noWaypoints", false], ["direction", _ingressPos getDir _targetPos]]] call FLO_fnc_virtualizationPatchGroup;
                private _tActivate = diag_tickTime;
                _activated = [_gid] call FLO_fnc_virtualizationTryActivateGroup;
                _phaseActivateMs = (diag_tickTime - _tActivate) * 1000;
                if (!_activated) then {
                    [_gid] call FLO_fnc_gtnAirParkCombatGroupOffMap;
                };
            };

            if (_isLiveArea && {!_activated}) exitWith {
                ["GTN Air Asset Manager", 2, format [
                    "Live %1 request failed - unable to activate air group %2",
                    _missionType,
                    _selectedId
                ]] call FLO_fnc_log;
                []
            };

            if (!_isLiveArea) exitWith {
                if !([_gid, _gdata, _missionRecord, _playerRequested] call FLO_fnc_gtnAirAuthorizeSortie) exitWith { [] };
                [_gdata, "AIR", _missionType] call FLO_fnc_virtualizationSetMissionLock;
                _missionRecord set ["mode", "VIRTUAL"];
                _missions set [_gid, _missionRecord];
                private _duration = _self call ["_getVirtualMissionDuration", [_missionType]];
                private _tVirtual = diag_tickTime;
                private _intercept = [_gid, _ingressPos, _targetPos] call FLO_fnc_gtnAirDefenseResolveVirtualEngagement;
                private _interceptStatus = _intercept get "status";

                if (_interceptStatus == "PHYSICAL") exitWith {
                    private _realGroup = _gdata get "realGroup";
                    if (isNull _realGroup) then { throw format ["Physical air-defense handoff left aircraft %1 without a real group", _gid]; };
                    private _vehicles = [_realGroup] call FLO_fnc_virtualizationCollectRealGroupVehicles;
                    if (_vehicles isEqualTo []) then { throw format ["Physical air-defense handoff left aircraft %1 without a vehicle", _gid]; };
                    private _vehicle = _vehicles select 0;
                    _missionRecord set ["mode", "REAL"];
                    _missions set [_gid, _missionRecord];
                    [_vehicle, _requestSide] call FLO_fnc_gtnAirDefenseActivateAgainstLiveAircraft;
                    [_vehicle, _gid, "REAL"]
                };

                private _effect = createHashMapFromArray [["totalLosses", 0], ["groupsHit", 0], ["groupsDestroyed", 0]];
                if (_interceptStatus == "CLEAR" && {_missionType == "CAS"}) then {
                    _effect = [_missionRecord] call FLO_fnc_gtnAirApplyVirtualCASEffect;
                };
                _phaseVirtualMs = (diag_tickTime - _tVirtual) * 1000;
                if (_gid in (call FLO_fnc_virtualizationGetGroupMap)) then {
                    [_gid, false] call FLO_fnc_gtnAirParkCombatGroupOffMap;
                } else {
                    _missions deleteAt _gid;
                };
                _self call ["_scheduleVirtualMissionRelease", [_gid, _duration]];

                ["GTN Air Asset Manager", 3, format[
                    "Virtual %1 mission by %2 at %3 (intercept=%4 losses=%5 duration=%6s)",
                    _missionType,
                    _gid,
                    _targetPos,
                    _interceptStatus,
                    _effect get "totalLosses",
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
                [_gid] call FLO_fnc_gtnAirParkCombatGroupOffMap;
                []
            };
            private _vehicles = [_realGroup] call FLO_fnc_virtualizationCollectRealGroupVehicles;
            if (_vehicles isEqualTo []) exitWith {
                [_gid] call FLO_fnc_gtnAirParkCombatGroupOffMap;
                []
            };
            private _veh = _vehicles select 0;

            if !([_gid, _gdata, _missionRecord, _playerRequested] call FLO_fnc_gtnAirAuthorizeSortie) exitWith {
                [_gid] call FLO_fnc_gtnAirParkCombatGroupOffMap;
                []
            };

            [_gdata, "AIR", _missionType] call FLO_fnc_virtualizationSetMissionLock;
            _missionRecord set ["mode", "REAL"];
            _missions set [_gid, _missionRecord];
            [_realGroup] call CBA_fnc_clearWaypoints;
            [_veh, _requestSide] call FLO_fnc_gtnAirDefenseActivateAgainstLiveAircraft;
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
                private _missionRecord = _missions get _gid;
                _missionState = _missionRecord get "mode";
                private _groups = call FLO_fnc_virtualizationGetGroupMap;
                if (_gid in _groups) then {
                    private _data = _groups get _gid;
                    if (_missionState != "VIRTUAL") then {
                        [_data, "AIR", "RTB"] call FLO_fnc_virtualizationSetMissionLock;
                        private _rtbPos = _self call ["_getRTBPosition", [_gid]];
                        _self call ["_sendToRTB", [_gid]];
                        _missionRecord set ["mode", "RTB"];
                        _missions set [_gid, _missionRecord];
                        _self call ["_scheduleRTBCompletion", [_gid, _rtbPos]];
                        _sentRTB = true;
                    } else {
                        [_data] call FLO_fnc_virtualizationClearMissionLock;
                        [_data] call FLO_fnc_virtualizationClearExecutionState;
                        _missions deleteAt _gid;
                    };
                    _released = true;
                } else {
                    ["GTN Air Asset Manager", 2, format["Group %1 not found in virtualGroups - may have been destroyed", _gid]] call FLO_fnc_log;
                    _missions deleteAt _gid;
                };
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

        // Return the terrain-edge egress; completion then parks the group off-map.
        ["_getRTBPosition", {
            params ["_groupId"];
            private _groups = call FLO_fnc_virtualizationGetGroupMap;
            if !(_groupId in _groups) exitWith {
                ["GTN Air Asset Manager", 2, format["_getRTBPosition: Group %1 not in virtualGroups", _groupId]] call FLO_fnc_log;
                [0,0,0]
            };
            private _gData = _groups get _groupId;
            private _homeObjective = _gData get "homeObjective";
            if (_homeObjective == "") then { throw format ["Air group %1 has no homeObjective", _groupId]; };
            private _homePos = (FLO_Objectives get _homeObjective) get "position";
            ([_gData get "side", _homePos] call FLO_fnc_gtnAirResolveReserveRoutePositions) select 2
        }],

        // Send aircraft to RTB - works for both active (real) and virtual groups
        ["_sendToRTB", {
            params ["_groupId"];

            private _groups = call FLO_fnc_virtualizationGetGroupMap;
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

                ["GTN Air Asset Manager", 3, format["RTB waypoints set for %1 to %2", _groupId, _rtbPos]] call FLO_fnc_log;
            } else {
                // Virtual group - use virtual waypoint system
                private _waypoints = [
                    [_rtbPos, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", 50]
                ];
                [_groupId, _waypoints, true, "GTN_AIR"] call FLO_fnc_updateVirtualGroupWaypoints;

                ["GTN Air Asset Manager", 3, format["Virtual RTB waypoints for %1 to %2", _groupId, _rtbPos]] call FLO_fnc_log;
            };

            [_gData, "RTB"] call FLO_fnc_virtualizationSetExecutionState;
            true
        }],

        // Get available aircraft for missions
        ["_getAvailableAircraft", {
            if (isNil "FLO_VirtualForceRegistry") exitWith { [] };
            private _groups = call FLO_fnc_virtualizationGetGroupMap;
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

