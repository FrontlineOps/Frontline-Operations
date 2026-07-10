/*
    Function: FLO_fnc_gtnArtilleryManager

    Description:
    Manages artillery groups that exist in the virtualization system.
    For target areas inside the shared virtualization activation bubble, the
    manager unvirtualizes and executes a real fire mission.
    For remote areas, the manager keeps artillery virtual and applies a
    virtual combat effect instead of spawning real assets.

    Firing pattern inspired by LAMBS Danger fnc_doArtillery:
    - Beaten zone cone pattern spreading towards the target
    - MLRS detection with salvo fire
    - Round-by-round firing with waitUntil unitReady
    - Heavier artillery fires more rounds, more accurately

    Returns:
    HashMap object with methods to request fire missions.

    Example:
        private _mgr = call FLO_fnc_gtnArtilleryManager;
        _mgr call ["_requestFireMission", [[1000,1000,0], 6, 100]];
*/

params [];

if (isNil "FLO_GTNArtilleryManager") then {
    FLO_GTNArtilleryManager = createHashMapObject [[
        ["missions", createHashMap],
        ["objectiveCooldowns", createHashMap],
        ["sideCooldowns", createHashMap],
        ["batteryCooldowns", createHashMap],
        ["artilleryGroupsBySide", createHashMapFromArray [
            ["ALL", createHashMap],
            ["EAST", createHashMap],
            ["WEST", createHashMap]
        ]],
        ["observedSpotters", createHashMap],
        ["observedFireSpotterCooldowns", createHashMap],
        ["observedFireTargetCooldowns", createHashMap],
        ["counterBatteryReports", createHashMap],
        ["counterBatteryCooldowns", createHashMap],
        ["shootAndScootTime", 90],
        ["defaultRounds", 6],
        ["defaultAccuracy", 100],  // Dispersion in meters
        ["objectiveCooldownSeconds", 180],
        ["observedFireSenseRadius", 1500],
        ["observedFireDangerCloseRadius", 200],
        ["observedFireSpotterCooldownSeconds", 90],
        ["observedFireTargetCooldownSeconds", 120],
        ["observedFireInterval", 5],
        ["observedFireBatchSize", 10],
        ["observedFireMaxPerSidePerCycle", 1],
        ["counterBatteryExposureThreshold", 5],
        ["counterBatteryMinMissionCount", 2],
        ["counterBatteryWindowSeconds", 240],
        ["counterBatteryCooldownSeconds", 300],
        ["counterBatteryMaxPerSidePerCycle", 1],
        ["observedFireCursor", 0],
        ["observedFirePfhId", -1],
        ["observedFireAddedEh", -1],
        ["observedFireActivatedEh", -1],
        ["observedFireDeactivatedEh", -1],
        ["observedFireRemovedEh", -1],

        // A target area is "live" only when it is inside the shared player
        // activation bubble. Remote batteries stay virtual.
        ["_isLiveArea", {
            params ["_targetPos", ["_radius", -1]];

            [_targetPos, _radius] call FLO_fnc_virtualizationIsPositionWithinActivationRange
        }],

        // Applies virtual artillery damage to nearby enemy virtual groups.
        ["_applyVirtualFireEffect", {
            params ["_artySide", "_targetPos", "_rounds", "_accuracy"];

            private _enemySide = if (_artySide isEqualTo east) then { west } else { east };
            private _groups = call FLO_fnc_virtualizationGetGroupMap;
            private _impactRadius = ((_accuracy max 50) * 3) min 700;
            private _candidates = [];

            {
                private _gid = _x;
                private _gData = _y;
                if ((_gData get "side") != _enemySide) then { continue };
                if (_gData get "isActive") then { continue };

                private _dist = (_gData get "position") distance2D _targetPos;
                if (_dist <= _impactRadius) then {
                    _candidates pushBack [_dist, _gid, _gData];
                };
            } forEach _groups;

            if (_candidates isEqualTo []) exitWith { 0 };

            _candidates sort true;

            private _targetsToHit = ((ceil (_rounds / 4)) max 1) min 3;
            private _totalLosses = 0;

            for "_i" from 0 to ((_targetsToHit min (count _candidates)) - 1) do {
                private _entry = _candidates select _i;
                _entry params ["_dist", "_gid", "_gData"];

                private _currentCount = _gData get "unitCount";
                if (_currentCount <= 0) then { continue };

                private _baseLoss = ceil ((_rounds * 0.35) / (_i + 1));
                private _falloff = 1 - ((_dist / _impactRadius) * 0.5);
                private _loss = ceil ((_baseLoss * _falloff) max 1);
                if (_loss > _currentCount) then { _loss = _currentCount; };

                private _newCount = _currentCount - _loss;
                if (_newCount <= 0) then {
                    [_gid] call FLO_fnc_virtualizationRemoveGroup;
                } else {
                    [
                        _gid,
                        createHashMapFromArray [["unitCount", _newCount]]
                    ] call FLO_fnc_virtualizationPatchGroup;
                };

                _totalLosses = _totalLosses + _loss;
            };

            _totalLosses
        }],

        ["_scheduleVirtualMissionRelease", {
            params ["_gid", ["_duration", 60]];

            [_gid, _duration] spawn {
                params ["_gid", "_duration"];
                sleep _duration;

                if (!isNil "FLO_VirtualForceRegistry") then {
                    private _groups = call FLO_fnc_virtualizationGetGroupMap;
                    if (_gid in _groups) then {
                        private _gData = _groups get _gid;
                        [_gData] call FLO_fnc_virtualizationClearMissionLock;
                    };
                };

                if (!isNil "FLO_GTNArtilleryManager") then {
                    private _missionRecord = (FLO_GTNArtilleryManager get "missions") get _gid;
                    (FLO_GTNArtilleryManager get "missions") deleteAt _gid;
                    if (!isNil "_missionRecord") then {
                        ["FLO_GTN_ArtilleryMissionStateChanged", [_missionRecord get "side", _missionRecord get "missionId", "COMPLETED"]] call CBA_fnc_localEvent;
                    };
                };
            };
        }],

        ["_isCooldownActive", {
            params ["_cooldowns", "_key"];

            private _lockedUntil = _cooldowns getOrDefault [_key, 0];
            if (_lockedUntil <= diag_tickTime) exitWith {
                _cooldowns deleteAt _key;
                false
            };

            true
        }],

        ["_isSpotterOnCooldown", {
            params ["_groupId"];
            _self call ["_isCooldownActive", [_self get "observedFireSpotterCooldowns", _groupId]]
        }],

        ["_markSpotterCooldown", {
            params ["_groupId"];
            (_self get "observedFireSpotterCooldowns") set [
                _groupId,
                diag_tickTime + (_self get "observedFireSpotterCooldownSeconds")
            ];
        }],

        ["_isObservedTargetOnCooldown", {
            params ["_targetKey"];
            _self call ["_isCooldownActive", [_self get "observedFireTargetCooldowns", _targetKey]]
        }],

        ["_markObservedTargetCooldown", {
            params ["_targetKey"];
            (_self get "observedFireTargetCooldowns") set [
                _targetKey,
                diag_tickTime + (_self get "observedFireTargetCooldownSeconds")
            ];
        }],

        ["_buildObservedTargetKey", {
            params ["_requestSide", "_enemyGroup", "_targetPos"];

            private _sideKey = ([_requestSide] call FLO_fnc_gtnSideContext) get "sideKey";
            private _enemyGroupId = _enemyGroup getVariable ["FLO_virtualGroupId", ""];
            if (_enemyGroupId != "") exitWith {
                format ["OBS:%1:%2", _sideKey, _enemyGroupId]
            };

            private _enemyLeader = leader _enemyGroup;
            if (!isNull _enemyLeader) exitWith {
                format ["OBS:%1:%2", _sideKey, netId _enemyLeader]
            };

            private _bucketX = floor ((_targetPos select 0) / 100);
            private _bucketY = floor ((_targetPos select 1) / 100);
            format ["OBS:%1:%2_%3", _sideKey, _bucketX, _bucketY]
        }],

        ["_isObservedImpactSafe", {
            params ["_targetPos", "_requestSide", ["_dangerRadius", -1]];

            if (_dangerRadius < 0) then {
                _dangerRadius = _self get "observedFireDangerCloseRadius";
            };

            private _groups = call FLO_fnc_virtualizationGetGroupMap;
            private _nearGroupIds = ["queryRadius", [_targetPos, _dangerRadius]] call FLO_fnc_virtualizationSpatialIndex;
            private _safe = true;

            {
                if !(_x in _groups) then { continue };

                private _gData = _groups get _x;
                if !(_gData get "isActive") then { continue };
                if ((_gData get "side") != _requestSide) then { continue };
                if (((_gData get "position") distance2D _targetPos) > _dangerRadius) then { continue };

                _safe = false;
            } forEach _nearGroupIds;

            if (!_safe) exitWith { false };

            private _playersDangerClose = {
                alive _x &&
                {side group _x == _requestSide} &&
                {(getPosATL _x) distance2D _targetPos <= _dangerRadius}
            } count allPlayers;

            _playersDangerClose == 0
        }],

        ["_initializeObservedFireSupport", {
            if ((_self get "observedFirePfhId") >= 0) exitWith {};

            private _groups = call FLO_fnc_virtualizationGetGroupMap;
            {
                [FLO_GTNArtilleryManager, _x, _y, true] call FLO_fnc_gtnArtillerySyncCachedGroup;
                [FLO_GTNArtilleryManager, _x, _y] call FLO_fnc_gtnArtillerySyncObservedSpotter;
            } forEach _groups;

            private _addedHandler = ["FLO_Virtualization_GroupAdded", {
                params ["_groupId", "_groupData"];
                [FLO_GTNArtilleryManager, _groupId, _groupData, true] call FLO_fnc_gtnArtillerySyncCachedGroup;
            }] call CBA_fnc_addEventHandler;
            _self set ["observedFireAddedEh", _addedHandler];

            private _activatedHandler = ["FLO_Virtualization_GroupActivated", {
                params ["_groupId", "_groupData", "_realGroup"];
                [FLO_GTNArtilleryManager, _groupId, _groupData] call FLO_fnc_gtnArtillerySyncObservedSpotter;
            }] call CBA_fnc_addEventHandler;
            _self set ["observedFireActivatedEh", _activatedHandler];

            private _deactivatedHandler = ["FLO_Virtualization_GroupDeactivated", {
                params ["_groupId", "_groupData"];
                [FLO_GTNArtilleryManager, _groupId, _groupData] call FLO_fnc_gtnArtillerySyncObservedSpotter;
            }] call CBA_fnc_addEventHandler;
            _self set ["observedFireDeactivatedEh", _deactivatedHandler];

            private _removedHandler = ["FLO_Virtualization_GroupRemoved", {
                params ["_groupId"];
                [FLO_GTNArtilleryManager, _groupId, nil, false] call FLO_fnc_gtnArtillerySyncCachedGroup;
                (FLO_GTNArtilleryManager get "observedSpotters") deleteAt _groupId;
                (FLO_GTNArtilleryManager get "observedFireSpotterCooldowns") deleteAt _groupId;
                (FLO_GTNArtilleryManager get "batteryCooldowns") deleteAt _groupId;
            }] call CBA_fnc_addEventHandler;
            _self set ["observedFireRemovedEh", _removedHandler];

            private _pfhId = [{
                [FLO_GTNArtilleryManager] call FLO_fnc_gtnArtilleryProcessObservedFireRequests;
                [FLO_GTNArtilleryManager] call FLO_fnc_gtnProcessCounterBatteryRequests;
            }, _self get "observedFireInterval", []] call CBA_fnc_addPerFrameHandler;
            _self set ["observedFirePfhId", _pfhId];
        }],

        ["_shutdownObservedFireSupport", {
            private _pfhId = _self get "observedFirePfhId";
            if (_pfhId >= 0) then {
                [_pfhId] call CBA_fnc_removePerFrameHandler;
                _self set ["observedFirePfhId", -1];
            };

            private _addedHandler = _self get "observedFireAddedEh";
            if (_addedHandler >= 0) then {
                ["FLO_Virtualization_GroupAdded", _addedHandler] call CBA_fnc_removeEventHandler;
                _self set ["observedFireAddedEh", -1];
            };

            private _activatedHandler = _self get "observedFireActivatedEh";
            if (_activatedHandler >= 0) then {
                ["FLO_Virtualization_GroupActivated", _activatedHandler] call CBA_fnc_removeEventHandler;
                _self set ["observedFireActivatedEh", -1];
            };

            private _deactivatedHandler = _self get "observedFireDeactivatedEh";
            if (_deactivatedHandler >= 0) then {
                ["FLO_Virtualization_GroupDeactivated", _deactivatedHandler] call CBA_fnc_removeEventHandler;
                _self set ["observedFireDeactivatedEh", -1];
            };

            private _removedHandler = _self get "observedFireRemovedEh";
            if (_removedHandler >= 0) then {
                ["FLO_Virtualization_GroupRemoved", _removedHandler] call CBA_fnc_removeEventHandler;
                _self set ["observedFireRemovedEh", -1];
            };
        }],

        // =========================================================================
        // REQUEST FIRE MISSION
        // Main entry point for artillery fire missions
        // =========================================================================
        ["_requestFireMission", {
            params ["_targetPos", ["_rounds", -1], ["_accuracy", -1], ["_requestSide", sideUnknown], ["_objectiveId", ""], ["_requestKind", "GENERAL"], ["_forceLive", false]];

            if (_rounds < 0) then { _rounds = _self get "defaultRounds"; };
            if (_accuracy < 0) then { _accuracy = _self get "defaultAccuracy"; };
            if (_rounds <= 0) exitWith {
                ["GTN Artillery", 1, format ["Rejected %1 artillery request with %2 rounds", _requestKind, _rounds]] call FLO_fnc_log;
                false
            };

            private _requestStatus = [_self, _requestSide, _objectiveId] call FLO_fnc_gtnArtilleryCanRequestMission;
            if !(_requestStatus select 0) exitWith { false };

            private _missions = _self get "missions";
            private _artGroups = [_self, _requestSide] call FLO_fnc_gtnArtilleryGetAvailableGroups;

            ["GTN Artillery", 3, format["Found %1 artillery groups", count _artGroups]] call FLO_fnc_log;

            if (_artGroups isEqualTo []) exitWith { false };

            ["GTN Artillery", 3, format["Available (not on mission): %1. Missions map: %2", count _artGroups, _missions]] call FLO_fnc_log;

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
            } forEach _artGroups;
            if (_sel isEqualTo []) exitWith { false };

            private _gid = _sel select 0;
            private _gdata = _sel select 1;
            private _batteryStatus = [_self, _requestSide, _objectiveId, _gid] call FLO_fnc_gtnArtilleryCanRequestMission;
            if !(_batteryStatus select 0) exitWith { false };
            private _isLiveArea = if (_forceLive) then { true } else { _self call ["_isLiveArea", [_targetPos]] };
            private _targetSide = if (_requestSide isEqualTo east) then {
                west
            } else {
                if (_requestSide isEqualTo west) then { east } else { sideUnknown };
            };
            private _forceLiveActivationFailed = false;

            if (_isLiveArea && {!(_gdata get "isActive")} && {!([_gid] call FLO_fnc_virtualizationTryActivateGroup)}) then {
                if (_forceLive) then {
                    _forceLiveActivationFailed = true;
                } else {
                    _isLiveArea = false;
                };
            };

            if (_forceLiveActivationFailed) exitWith {
                ["GTN Artillery", 2, format [
                    "Force-live artillery request for %1 failed - unable to activate battery %2",
                    _targetPos,
                    _gid
                ]] call FLO_fnc_log;
                false
            };

            ["GTN Artillery", 3, format["Selected group %1, isActive: %2, liveArea: %3", _gid, _gdata get "isActive", _isLiveArea]] call FLO_fnc_log;

            // Non-live area: keep support entirely virtual.
            if (!_isLiveArea) exitWith {
                private _missionRecord = [_gid, _gdata, _targetPos, _rounds, _accuracy, createHashMap, _requestKind] call FLO_fnc_gtnBuildArtilleryMissionRecord;
                if !([_self, _gid, _gdata, _requestSide, _objectiveId, _missionRecord] call FLO_fnc_gtnArtilleryAuthorizeMission) exitWith { false };

                [_gdata, "ARTILLERY", "VIRTUAL_FIRE"] call FLO_fnc_virtualizationSetMissionLock;
                (_self get "missions") set [_gid, _missionRecord];
                ["FLO_GTN_ArtilleryMissionStateChanged", [_missionRecord get "side", _missionRecord get "missionId", "STARTED"]] call CBA_fnc_localEvent;

                if (_targetSide in [east, west]) then {
                    [_self, _gid, _gdata, _targetSide, _missionRecord] call FLO_fnc_gtnRecordCounterBatteryExposure;
                };
                [_requestSide, _missionRecord] call FLO_fnc_gtnBroadcastArtilleryRadio;

                private _losses = _self call ["_applyVirtualFireEffect", [_gdata get "side", _targetPos, _rounds, _accuracy]];
                private _missionDuration = (40 + (_rounds * 4)) min 180;
                _self call ["_scheduleVirtualMissionRelease", [_gid, _missionDuration]];

                ["GTN Artillery", 3, format[
                    "Virtual-only fire mission by %1 at %2 (losses=%3, duration=%4s)",
                    _gid,
                    _targetPos,
                    _losses,
                    round _missionDuration
                ]] call FLO_fnc_log;
                true
            };

            private _realGroup = _gdata get "realGroup";
            if (isNull _realGroup) exitWith {
                ["GTN Artillery", 1, format [
                    "Artillery request failed - selected battery %1 has no realGroup after live activation",
                    _gid
                ]] call FLO_fnc_log;
                false
            };
            private _firePlan = [_realGroup, _targetPos, _rounds, _accuracy] call FLO_fnc_gtnBuildArtilleryFirePlan;
            if ((keys _firePlan) isEqualTo []) exitWith {
                ["GTN Artillery", 1, format [
                    "Artillery request failed - selected battery %1 produced an empty fire plan at %2",
                    _gid,
                    _targetPos
                ]] call FLO_fnc_log;
                false
            };

            private _missionRecord = [_gid, _gdata, _targetPos, _rounds, _accuracy, _firePlan, _requestKind] call FLO_fnc_gtnBuildArtilleryMissionRecord;
            if !([_self, _gid, _gdata, _requestSide, _objectiveId, _missionRecord] call FLO_fnc_gtnArtilleryAuthorizeMission) exitWith { false };

            if (_targetSide in [east, west]) then {
                private _alertPayload = [];
                if ((keys _firePlan) isNotEqualTo []) then {
                    _alertPayload = [
                        _firePlan get "etaMin",
                        _firePlan get "etaMax",
                        _firePlan get "impactPoints"
                    ];
                };
                [_targetPos, _rounds, _accuracy, _targetSide, _alertPayload] call FLO_fnc_gtnAlertIncomingArtillery;
            };

            // Mark as on mission to prevent virtualization
            [_gdata, "ARTILLERY", "LIVE_FIRE"] call FLO_fnc_virtualizationSetMissionLock;

            // Register mission
            (_self get "missions") set [_gid, _missionRecord];
            ["FLO_GTN_ArtilleryMissionStateChanged", [_missionRecord get "side", _missionRecord get "missionId", "STARTED"]] call CBA_fnc_localEvent;
            if (_targetSide in [east, west]) then {
                [_self, _gid, _gdata, _targetSide, _missionRecord] call FLO_fnc_gtnRecordCounterBatteryExposure;
            };
            [_requestSide, _missionRecord] call FLO_fnc_gtnBroadcastArtilleryRadio;

            // Spawn the fire mission process
            [_gid, _gdata, _realGroup, _targetPos, _rounds, _accuracy, _firePlan, _self] spawn FLO_fnc_gtnArtilleryFireMission;

            true
        }],

        // =========================================================================
        // CLEANUP MISSION
        // Called when a mission completes (success or failure)
        // =========================================================================
        ["_cleanupMission", {
            params ["_gid", "_veh"];

            private _groups = call FLO_fnc_virtualizationGetGroupMap;
            private _gdata = _groups get _gid;

            if (isNil "_gdata") exitWith {
                private _missionRecord = (_self get "missions") get _gid;
                (_self get "missions") deleteAt _gid;
                if (!isNil "_missionRecord") then {
                    ["FLO_GTN_ArtilleryMissionStateChanged", [_missionRecord get "side", _missionRecord get "missionId", "COMPLETED"]] call CBA_fnc_localEvent;
                };
            };

            private _realGroup = _gdata get "realGroup";

            // Shoot and scoot - move to new position
            if (!isNull _realGroup && {(units _realGroup) isNotEqualTo []}) then {
                private _cur = if (!isNull _veh && alive _veh) then { getPos _veh } else { getPos leader _realGroup };
                private _dir = random 360;
                private _dist = 300 + random 300;
                private _newPos = _cur getPos [_dist, _dir];
                private _wps = [[_newPos, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", 10]];
                [_gid, _wps, false] call FLO_fnc_updateVirtualGroupWaypoints;

                ["GTN Artillery", 3, format["Artillery %1 shoot-and-scoot to %2", _gid, _newPos]] call FLO_fnc_log;
            };

            // Wait for relocation then release
            private _scootTime = _self get "shootAndScootTime";
            [_gid, _scootTime] spawn {
                params ["_gid", "_scootTime"];
                sleep _scootTime;

                private _groups = call FLO_fnc_virtualizationGetGroupMap;
                private _gdata = _groups get _gid;
                if (!isNil "_gdata") then {
                    // Clear mission flag
                    [_gdata] call FLO_fnc_virtualizationClearMissionLock;

                    // Reset state to idle so virtualization can assign new patrol
                    [_gdata, "idle"] call FLO_fnc_virtualizationSetRuntimeState;
                    [
                        _gid,
                        createHashMapFromArray [["autoPatrol", false]]
                    ] call FLO_fnc_virtualizationPatchGroup;

                    if ((_gdata get "isActive") && {!isNull (_gdata get "realGroup")}) then {
                        [_gid, _gdata] call FLO_fnc_deactivateVirtualGroup;
                    };
                };

                if (!isNil "FLO_GTNArtilleryManager") then {
                    private _missionRecord = (FLO_GTNArtilleryManager get "missions") get _gid;
                    (FLO_GTNArtilleryManager get "missions") deleteAt _gid;
                    if (!isNil "_missionRecord") then {
                        ["FLO_GTN_ArtilleryMissionStateChanged", [_missionRecord get "side", _missionRecord get "missionId", "COMPLETED"]] call CBA_fnc_localEvent;
                    };
                };

                ["GTN Artillery", 3, format["Artillery %1 mission fully complete, revirtualized", _gid]] call FLO_fnc_log;
            };
        }]
    ]];

    FLO_GTNArtilleryManager call ["_initializeObservedFireSupport", []];
};

FLO_GTNArtilleryManager
