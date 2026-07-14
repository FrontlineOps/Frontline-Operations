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
        ["firePlanRejections", createHashMap],
        ["firePlanRejectSeconds", 300],
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
        ["virtualCombatStallRounds", 3],
        ["virtualCombatMaximumRatio", 1.4],
        ["virtualCombatMaximumMomentum", 25],
        ["virtualCombatZoneCooldownSeconds", 600],
        ["virtualCombatRounds", 8],
        ["virtualCombatAccuracy", 80],
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
            } count ([] call FLO_fnc_getConnectedHumanPlayers);

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
            params ["_targetPos", ["_rounds", -1], ["_accuracy", -1], ["_requestSide", sideUnknown], ["_objectiveId", ""], ["_requestKind", "GENERAL"], ["_forceLive", false], ["_targetContext", createHashMap]];

            if (_rounds < 0) then { _rounds = _self get "defaultRounds"; };
            if (_accuracy < 0) then { _accuracy = _self get "defaultAccuracy"; };
            if (_rounds <= 0) exitWith {
                ["GTN Artillery", 1, format ["Rejected %1 artillery request with %2 rounds", _requestKind, _rounds]] call FLO_fnc_log;
                false
            };

            private _requestStatus = [_self, _requestSide, _objectiveId] call FLO_fnc_gtnArtilleryCanRequestMission;
            if !(_requestStatus select 0) exitWith { false };

            private _isLiveArea = if (_forceLive) then { true } else { _self call ["_isLiveArea", [_targetPos]] };
            private _artGroups = [_self, _requestSide] call FLO_fnc_gtnArtilleryGetAvailableGroups;
            if (_requestKind == "VIRTUAL_COMBAT") then {
                _artGroups = _artGroups select { !((_x select 1) get "isActive") };
            };

            ["GTN Artillery", 4, format ["Found %1 artillery groups for %2 request", count _artGroups, _requestKind]] call FLO_fnc_log;

            if (_artGroups isEqualTo []) exitWith { false };

            private _gid = "";
            private _gdata = createHashMap;
            private _realGroup = grpNull;
            private _firePlan = createHashMap;
            private _activatedForSelection = false;
            private _selectionFailed = false;
            if (_isLiveArea) then {
                private _selection = [_self, _artGroups, _targetPos, _rounds, _accuracy] call FLO_fnc_gtnArtillerySelectLiveBattery;
                _gid = _selection get "groupId";
                if (_gid == "") then {
                    _selectionFailed = true;
                    ["GTN Artillery", 4, format [
                        "No live battery could service %1: candidates=%2 cooldownRejected=%3 activationFailures=%4 emptyPlans=%5",
                        _targetPos,
                        count _artGroups,
                        _selection get "rejectedCooldown",
                        _selection get "activationFailures",
                        _selection get "emptyPlans"
                    ]] call FLO_fnc_log;
                } else {
                    _gdata = _selection get "groupData";
                    _realGroup = _selection get "realGroup";
                    _firePlan = _selection get "firePlan";
                    _activatedForSelection = _selection get "activatedForSelection";
                };
            } else {
                private _bestDist = 1e12;
                {
                    _x params ["_candidateId", "_candidateData"];
                    private _distance = (_candidateData get "position") distance2D _targetPos;
                    if (_distance < _bestDist) then {
                        _bestDist = _distance;
                        _gid = _candidateId;
                        _gdata = _candidateData;
                    };
                } forEach _artGroups;
                _selectionFailed = _gid == "";
            };
            if (_selectionFailed) exitWith { false };

            private _batteryStatus = [_self, _requestSide, _objectiveId, _gid] call FLO_fnc_gtnArtilleryCanRequestMission;
            if !(_batteryStatus select 0) exitWith {
                if (_activatedForSelection) then {
                    [_gid, _gdata] call FLO_fnc_deactivateVirtualGroup;
                };
                false
            };
            private _targetSide = if (_requestSide isEqualTo east) then {
                west
            } else {
                if (_requestSide isEqualTo west) then { east } else { sideUnknown };
            };
            ["GTN Artillery", 4, format ["Selected group %1, isActive: %2, liveArea: %3", _gid, _gdata get "isActive", _isLiveArea]] call FLO_fnc_log;

            // Non-live area: keep support entirely virtual.
            if (!_isLiveArea) exitWith {
                private _missionRecord = [_gid, _gdata, _targetPos, _rounds, _accuracy, createHashMap, _requestKind, _targetContext] call FLO_fnc_gtnBuildArtilleryMissionRecord;
                if !([_self, _gid, _gdata, _requestSide, _objectiveId, _missionRecord] call FLO_fnc_gtnArtilleryAuthorizeMission) exitWith { false };

                [_gdata, "ARTILLERY", "VIRTUAL_FIRE"] call FLO_fnc_virtualizationSetMissionLock;
                (_self get "missions") set [_gid, _missionRecord];
                ["FLO_GTN_ArtilleryMissionStateChanged", [_missionRecord get "side", _missionRecord get "missionId", "STARTED"]] call CBA_fnc_localEvent;

                if (_targetSide in [east, west]) then {
                    [_self, _gid, _gdata, _targetSide, _missionRecord] call FLO_fnc_gtnRecordCounterBatteryExposure;
                };
                [_requestSide, _missionRecord] call FLO_fnc_gtnBroadcastArtilleryRadio;

                private _effect = [_missionRecord] call FLO_fnc_gtnArtilleryApplyVirtualFireEffect;
                private _missionDuration = (40 + (_rounds * 4)) min 180;
                _self call ["_scheduleVirtualMissionRelease", [_gid, _missionDuration]];

                ["GTN Artillery", 3, format[
                    "Virtual-only fire mission by %1 at %2 (losses=%3, hit=%4, destroyed=%5, duration=%6s)",
                    _gid,
                    _targetPos,
                    _effect get "totalLosses",
                    _effect get "groupsHit",
                    _effect get "groupsDestroyed",
                    round _missionDuration
                ]] call FLO_fnc_log;
                true
            };

            private _missionRecord = [_gid, _gdata, _targetPos, _rounds, _accuracy, _firePlan, _requestKind, _targetContext] call FLO_fnc_gtnBuildArtilleryMissionRecord;
            if !([_self, _gid, _gdata, _requestSide, _objectiveId, _missionRecord] call FLO_fnc_gtnArtilleryAuthorizeMission) exitWith {
                if (_activatedForSelection) then {
                    [_gid, _gdata] call FLO_fnc_deactivateVirtualGroup;
                };
                false
            };

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
