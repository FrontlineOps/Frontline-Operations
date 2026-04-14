/*
 * Function: FLO_fnc_civilianManager
 * Author: Frontline Operations Development Group
 * Description:
 *   Server-owned civilian manager for local mood, ambient state, and
 *   reputation-driven civilian policy.
 *
 * Return Value:
 * HASHMAP OBJECT - Civilian manager
 */

if (!isServer) exitWith { createHashMap };

if (!isNil "FLO_CivilianManager") exitWith {
    FLO_CivilianManager
};

private _civilianClass = [
    ["#type", "CivilianManager"],
    ["CONFIG", FLO_CivilianConfig],
    ["_objectiveContexts", createHashMap],
    ["_objectivePoiCaches", createHashMap],
    ["_objectiveMemories", createHashMap],
    ["_lastUpdate", -1],
    ["_loopPfhId", -1],
    ["_lastCombatEventAt", -1],
    ["_routineCursor", 0],
    ["_gossipCursor", 0],
    ["_missionState", createHashMapFromArray [
        ["active", false],
        ["id", ""],
        ["type", ""],
        ["objectiveId", ""],
        ["briefing", ""],
        ["requestedByUid", ""],
        ["requestedByName", ""],
        ["startedAt", -1],
        ["taskId", ""],
        ["position", []],
        ["offer", createHashMap]
    ]],
    ["_activeProtests", createHashMap],
    ["_objectiveProtestCooldowns", createHashMap],
    ["_detentionRecords", createHashMap],

    ["getReputation", {
        FLO_ReputationHandle get "value"
    }],

    ["getObjectiveContext", {
        params [
            ["_objectiveId", "", [""]],
            ["_civilianRole", "resident", [""]],
            ["_reportingSide", FLO_ActivePlayerSide, [east]]
        ];

        if !(_reportingSide in [east, west]) then {
            _reportingSide = west;
        };

        private _contexts = _self get "_objectiveContexts";
        private _cacheKey = format ["%1|%2|%3", _objectiveId, _civilianRole, _reportingSide];
        if (_cacheKey in _contexts) exitWith {
            _contexts get _cacheKey
        };

        private _context = [_objectiveId, _civilianRole, _reportingSide] call FLO_fnc_civilianResolveObjectiveContext;
        _contexts set [_cacheKey, _context];
        _context
    }],

    ["getDisposition", {
        params [
            ["_objectiveId", "", [""]],
            ["_civilianRole", "resident", [""]],
            ["_reportingSide", FLO_ActivePlayerSide, [east]]
        ];
        (_self call ["getObjectiveContext", [_objectiveId, _civilianRole, _reportingSide]]) get "disposition"
    }],

    ["getObjectivePoiCache", {
        params [["_objectiveId", "", [""]]];

        private _poiCaches = _self get "_objectivePoiCaches";
        if (_objectiveId in _poiCaches) exitWith {
            _poiCaches get _objectiveId
        };

        private _poiCache = [_objectiveId] call FLO_fnc_civilianBuildObjectivePoiCache;
        _poiCaches set [_objectiveId, _poiCache];
        _poiCache
    }],

    ["getObjectiveMemories", {
        params [["_objectiveId", "", [""]], ["_nowTick", diag_tickTime, [0]]];

        private _ledger = _self get "_objectiveMemories";
        if !(_objectiveId in _ledger) exitWith { [] };

        private _activeMemories = [];
        {
            if ((_x get "expiresAt") > _nowTick) then {
                _activeMemories pushBack _x;
            };
        } forEach (_ledger get _objectiveId);

        _ledger set [_objectiveId, _activeMemories];
        _activeMemories
    }],

    ["recordObjectiveMemory", {
        params [["_memory", createHashMap, [createHashMap]], ["_nowTick", diag_tickTime, [0]]];
        [_self get "_objectiveMemories", _memory, _nowTick] call FLO_fnc_civilianMergeObjectiveMemory;
        true
    }],

    ["ingestCombatEvents", {
        private _ledger = _self get "_objectiveMemories";
        private _lastProcessedAt = _self get "_lastCombatEventAt";
        private _result = [_ledger, _lastProcessedAt, diag_tickTime] call FLO_fnc_civilianIngestCombatEvents;
        _result params ["_latestProcessedAt", "_addedCount"];
        _self set ["_lastCombatEventAt", _latestProcessedAt];
        _addedCount
    }],

    ["propagateObjectiveGossip", {
        private _ledger = _self get "_objectiveMemories";
        private _cursor = _self get "_gossipCursor";
        private _result = [_ledger, _cursor, diag_tickTime] call FLO_fnc_civilianPropagateObjectiveGossip;
        _result params ["_addedCount", "_nextCursor"];
        _self set ["_gossipCursor", _nextCursor];
        _addedCount
    }],

    ["shouldFlee", {
        params [["_position", [0, 0, 0], [[]], [3]]];

        private _objectiveId = [_position] call FLO_fnc_civilianResolveObjective;
        if (_objectiveId == "") exitWith { false };

        private _reportingSide = FLO_ActivePlayerSide;
        if !(_reportingSide in [east, west]) then {
            _reportingSide = west;
        };

        private _context = _self call ["getObjectiveContext", [_objectiveId, "resident", _reportingSide]];
        if ((_context get "disposition") == "FRIENDLY") exitWith { false };

        private _cfg = _self get "CONFIG";
        private _radius = _cfg get "FLEE_RADIUS";
        private _nearbyPlayers = allPlayers select { alive _x && {_position distance2D (getPosATL _x) <= _radius} };
        if ((count _nearbyPlayers) == 0) exitWith { false };

        private _objective = FLO_Objectives get _objectiveId;
        (_objective get "contested") || {(_context get "disposition") in ["WARY", "HOSTILE"]}
    }],

    ["retaskCivilianGroup", {
        params [["_groupId", "", [""]], ["_groupData", createHashMap, [createHashMap]]];

        private _objectiveId = _groupData get "civilianObjective";
        if (_objectiveId == "") exitWith { false };
        private _realGroup = _groupData get "realGroup";
        if (!isNull _realGroup && {{alive _x && {captive _x}} count (units _realGroup) > 0}) exitWith { false };
        if ((_groupData get "civilianRoutineState") == "protest" && {(diag_tickTime < (_groupData get "civilianRoutineUntil"))}) exitWith { false };

        private _reportingSide = FLO_ActivePlayerSide;
        if !(_reportingSide in [east, west]) then {
            _reportingSide = west;
        };

        private _context = _self call ["getObjectiveContext", [_objectiveId, _groupData get "civilianRole", _reportingSide]];
        private _poiCache = _self call ["getObjectivePoiCache", [_objectiveId]];
        private _plan = [_groupData, _context, _poiCache, diag_tickTime] call FLO_fnc_civilianPlanRoutine;
        if ((count (keys _plan)) == 0) exitWith { false };

        [_groupId, _groupData, _plan] call FLO_fnc_civilianApplyRoutinePlan
    }],

    ["updateCivilianRoutines", {
        if (isNil "FLO_virtualGroups") exitWith { 0 };

        private _groups = FLO_virtualGroups get "_groups";
        private _activeCivilianIds = [];
        private _inactiveCivilianIds = [];

        {
            private _groupId = _x;
            private _groupData = _y;

            if ((_groupData get "side") != civilian) then { continue };
            if !((_groupData get "groupType") in ["civilian", "civ_pedestrian", "civ_building", "civilianVehicle", "civ_car"]) then { continue };

            if (_groupData get "isActive") then {
                _activeCivilianIds pushBack _groupId;
            } else {
                _inactiveCivilianIds pushBack _groupId;
            };
        } forEach _groups;

        private _retasked = 0;
        {
            if (_self call ["retaskCivilianGroup", [_x, _groups get _x]]) then {
                _retasked = _retasked + 1;
            };
        } forEach _activeCivilianIds;

        private _inactiveCount = count _inactiveCivilianIds;
        if (_inactiveCount > 0) then {
            private _cursor = _self get "_routineCursor";
            private _batchSize = ((_self get "CONFIG") get "ROUTINE_BATCH_SIZE") max 1;
            private _iterations = _batchSize min _inactiveCount;

            for "_i" from 0 to (_iterations - 1) do {
                private _idx = (_cursor + _i) mod _inactiveCount;
                private _groupId = _inactiveCivilianIds select _idx;
                if (_self call ["retaskCivilianGroup", [_groupId, _groups get _groupId]]) then {
                    _retasked = _retasked + 1;
                };
            };

            _self set ["_routineCursor", (_cursor + _iterations) mod _inactiveCount];
        } else {
            _self set ["_routineCursor", 0];
        };

        _retasked
    }],

    ["updateProtests", {
        private _nowTick = diag_tickTime;
        private _groups = FLO_virtualGroups get "_groups";
        private _activeProtests = _self get "_activeProtests";
        private _cooldowns = _self get "_objectiveProtestCooldowns";
        private _endedObjectives = [];

        {
            private _objectiveId = _x;
            private _record = _y;
            private _target = _record get "target";
            private _groupIds = _record get "groupIds";
            private _shouldEnd = false;

            if ((_record get "expiresAt") <= _nowTick || {isNull _target} || {!alive _target}) then {
                _shouldEnd = true;
            } else {
                private _targetSide = side group _target;
                if !(_targetSide in [east, west]) then {
                    _targetSide = FLO_ActivePlayerSide;
                };

                private _context = _self call ["getObjectiveContext", [_objectiveId, "resident", _targetSide]];
                private _objective = FLO_Objectives get _objectiveId;
                private _qualifies = ((_context get "disposition") == "HOSTILE") || {
                    (_context get "disposition") == "WARY" && {(_objective get "contested")}
                };

                if (!_qualifies || {([getPosATL _target] call FLO_fnc_civilianResolveObjective) != _objectiveId}) then {
                    _shouldEnd = true;
                };
            };

            if (_shouldEnd) then {
                {
                    if !(_x in _groups) then { continue };
                    private _groupData = _groups get _x;
                    if ((_groupData get "civilianRoutineState") == "protest") then {
                        _groupData set ["civilianRoutineUntil", _nowTick - 1];
                    };
                    private _realGroup = _groupData get "realGroup";
                    private _hasDetainedUnits = false;
                    if (!isNull _realGroup) then {
                        {
                            if (alive _x && {captive _x}) then {
                                _hasDetainedUnits = true;
                            };
                            _x setVariable ["FLO_ProtestExpiresAt", _nowTick - 1, false];
                        } forEach (units _realGroup);
                    };
                    if (!_hasDetainedUnits) then {
                        _groupData set ["alwaysActive", _groupData get "protestRestoreAlwaysActive"];
                        _self call ["retaskCivilianGroup", [_x, _groupData]];
                    };
                    _groupData set ["protestRestoreAlwaysActive", false];
                } forEach _groupIds;
                _endedObjectives pushBack _objectiveId;
            };
        } forEach _activeProtests;

        {
            _activeProtests deleteAt _x;
        } forEach _endedObjectives;

        private _started = 0;
        {
            private _player = _x;
            private _playerSide = side group _player;
            if !(_playerSide in [east, west]) then { continue };

            private _objectiveId = [getPosATL _player] call FLO_fnc_civilianResolveObjective;
            if (_objectiveId == "" || {!(_objectiveId in FLO_Objectives)}) then { continue };
            if (_objectiveId in _activeProtests) then { continue };
            if ((_cooldowns getOrDefault [_objectiveId, -1]) > _nowTick) then { continue };

            private _context = _self call ["getObjectiveContext", [_objectiveId, "resident", _playerSide]];
            private _objective = FLO_Objectives get _objectiveId;
            private _qualifies = ((_context get "disposition") == "HOSTILE") || {
                (_context get "disposition") == "WARY" && {(_objective get "contested")}
            };
            if (!_qualifies) then { continue };

            private _selectedGroups = [_objectiveId, _player, FLO_CivilianConfig get "PROTEST_MAX_GROUPS"] call FLO_fnc_civilianSelectObjectiveProtesters;
            if ((count _selectedGroups) < (FLO_CivilianConfig get "PROTEST_MIN_GROUPS")) then { continue };

            private _expiresAt = _nowTick + (FLO_CivilianConfig get "PROTEST_DURATION_SECONDS");
            private _protesters = [_player, _selectedGroups, _objectiveId, _expiresAt] call FLO_fnc_civilianProtest;
            if ((count _protesters) == 0) then { continue };

            _activeProtests set [_objectiveId, createHashMapFromArray [
                ["target", _player],
                ["groupIds", _selectedGroups],
                ["expiresAt", _expiresAt]
            ]];
            _cooldowns set [_objectiveId, _expiresAt + (FLO_CivilianConfig get "PROTEST_COOLDOWN_SECONDS")];
            _started = _started + 1;
        } forEach (allPlayers select { alive _x });

        [count (keys _activeProtests), _started]
    }],

    ["update", {
        if (isNil "FLO_Objectives") exitWith { false };

        private _contexts = createHashMap;
        private _roles = ["resident", "vendor", "worker", "wanderer", "driver", "watcher"];
        {
            private _objectiveId = _x;
            {
                private _side = _x;
                {
                    private _role = _x;
                    private _cacheKey = format ["%1|%2|%3", _objectiveId, _role, _side];
                    _contexts set [_cacheKey, [_objectiveId, _role, _side] call FLO_fnc_civilianResolveObjectiveContext];
                } forEach _roles;
            } forEach [east, west];
        } forEach (keys FLO_Objectives);

        _self set ["_objectiveContexts", _contexts];
        _self set ["_lastUpdate", diag_tickTime];

        private _memoryIngested = _self call ["ingestCombatEvents", []];
        private _gossipAdded = _self call ["propagateObjectiveGossip", []];
        private _retaskedCount = _self call ["updateCivilianRoutines", []];
        private _protestResult = _self call ["updateProtests", []];
        _protestResult params ["_activeProtestCount", "_startedProtests"];

        ["CIVILIAN", 3, format [
            "Civilian manager updated %1 objective contexts at rep %2 | memories=%3 gossip=%4 retasked=%5 protests=%6 started=%7",
            count (keys _contexts),
            _self call ["getReputation", []],
            _memoryIngested,
            _gossipAdded,
            _retaskedCount,
            _activeProtestCount,
            _startedProtests
        ]] call FLO_fnc_log;

        true
    }],

    ["start", {
        if ((_self get "_loopPfhId") >= 0) exitWith { true };

        private _interval = ((_self get "CONFIG") get "UPDATE_INTERVAL") max 5;
        private _pfhId = [{
            params ["_args", "_pfhId"];
            _args params ["_manager"];

            if (isNil "FLO_CivilianManager") exitWith {
                [_pfhId] call CBA_fnc_removePerFrameHandler;
            };

            _manager call ["update", []];
        }, _interval, [_self]] call CBA_fnc_addPerFrameHandler;

        _self set ["_loopPfhId", _pfhId];
        true
    }],

    ["init", {
        _self call ["update", []];
        _self call ["start", []];
        ["CIVILIAN", 2, "Civilian manager initialized and worker started"] call FLO_fnc_log;
        true
    }]
];

FLO_CivilianManager = createHashMapObject [_civilianClass];
FLO_CivilianManager call ["init", []];

FLO_CivilianManager
