/*
 * Function: FLO_fnc_gtnBuildObjectiveAssignmentCache
 * Author: Frontline Operations Development Group
 *
 * Description:
 * Build one per-cycle cache of objective assignment counts and claimed hold
 * positions so GTN allocation passes do not keep rescanning the full registry.
 *
 * Arguments:
 * 0: GTN Commander <HASHMAP>
 *
 * Return Value:
 * Cache <HASHMAP>
 */

params [["_cmdr", nil]];

private _cache = createHashMapFromArray [
    ["attackCounts", createHashMap],
    ["attackGroupIds", []],
    ["attackCountsByOperation", createHashMap],
    ["attackGroupsByOperation", createHashMap],
    ["orderedGroupIds", []],
    ["garrisonCounts", createHashMap],
    ["defenderCounts", createHashMap],
    ["garrisonGroupsByObjective", createHashMap],
    ["garrisonPositionsByObjective", createHashMap],
    ["claimedPositionsByObjective", createHashMap]
];

if (isNil "_cmdr") exitWith { _cache };

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _ownSide = _cmdr get "_ownSide";
private _attackCounts = _cache get "attackCounts";
private _attackGroupIds = _cache get "attackGroupIds";
private _attackCountsByOperation = _cache get "attackCountsByOperation";
private _attackGroupsByOperation = _cache get "attackGroupsByOperation";
private _orderedGroupIds = _cache get "orderedGroupIds";
private _garrisonCounts = _cache get "garrisonCounts";
private _defenderCounts = _cache get "defenderCounts";
private _garrisonGroupsByObjective = _cache get "garrisonGroupsByObjective";
private _garrisonPositionsByObjective = _cache get "garrisonPositionsByObjective";
private _claimedPositionsByObjective = _cache get "claimedPositionsByObjective";

{
    private _gData = _y;
    if ((_gData get "side") != _ownSide) then { continue };

    private _order = _gData get "commanderOrder";
    if (_order in ["ATTACK", "DEFEND", "GARRISON", "MOVE"]) then {
        _orderedGroupIds pushBack _x;
    };

    if (_order == "ATTACK") then {
        _attackGroupIds pushBack _x;
        private _operationId = _gData get "campaignOperationId";
        if (_operationId == "") then {
            throw format ["ATTACK group %1 has no campaign operation", _x];
        };
        private _operationGroups = if (_operationId in _attackGroupsByOperation) then {
            _attackGroupsByOperation get _operationId
        } else {
            []
        };
        _operationGroups pushBack _x;
        _attackGroupsByOperation set [_operationId, _operationGroups];
        _attackCountsByOperation set [_operationId, count _operationGroups];

        private _objectiveId = _gData get "attackObjective";
        if (_objectiveId != "") then {
            private _count = if (_objectiveId in _attackCounts) then {
                _attackCounts get _objectiveId
            } else {
                0
            };
            _attackCounts set [_objectiveId, _count + 1];
        };
        continue;
    };

    if ((_gData get "groupType") == "static_aa") then { continue };

    if (_order == "GARRISON") then {
        private _objectiveId = _gData get "garrisonObjective";
        if (_objectiveId == "") then {
            private _invalidGarrisonBucket = if ("" in _garrisonGroupsByObjective) then {
                _garrisonGroupsByObjective get ""
            } else {
                []
            };
            _invalidGarrisonBucket pushBack _x;
            _garrisonGroupsByObjective set ["", _invalidGarrisonBucket];
            continue;
        };

        private _garrisonCount = if (_objectiveId in _garrisonCounts) then {
            _garrisonCounts get _objectiveId
        } else {
            0
        };
        _garrisonCounts set [_objectiveId, _garrisonCount + 1];

        private _garrisonGroupBucket = if (_objectiveId in _garrisonGroupsByObjective) then {
            _garrisonGroupsByObjective get _objectiveId
        } else {
            []
        };
        _garrisonGroupBucket pushBack _x;
        _garrisonGroupsByObjective set [_objectiveId, _garrisonGroupBucket];

        private _defenderCount = if (_objectiveId in _defenderCounts) then {
            _defenderCounts get _objectiveId
        } else {
            0
        };
        _defenderCounts set [_objectiveId, _defenderCount + 1];

        private _claimPos = _gData get "garrisonPosition";
        if (!(_claimPos isEqualType []) || {count _claimPos < 2}) then {
            _claimPos = _gData get "position";
        };

        private _garrisonPositionBucket = if (_objectiveId in _garrisonPositionsByObjective) then {
            _garrisonPositionsByObjective get _objectiveId
        } else {
            []
        };
        _garrisonPositionBucket pushBack _claimPos;
        _garrisonPositionsByObjective set [_objectiveId, _garrisonPositionBucket];

        private _bucket = if (_objectiveId in _claimedPositionsByObjective) then {
            _claimedPositionsByObjective get _objectiveId
        } else {
            []
        };
        _bucket pushBack _claimPos;
        _claimedPositionsByObjective set [_objectiveId, _bucket];
        continue;
    };

    if (_order != "DEFEND") then { continue };

    private _objectiveId = _gData get "defendObjective";
    if (_objectiveId == "") then { continue };

    private _defenderCount = if (_objectiveId in _defenderCounts) then {
        _defenderCounts get _objectiveId
    } else {
        0
    };
    _defenderCounts set [_objectiveId, _defenderCount + 1];

    private _claimPos = _gData get "orderTargetPos";
    if (!(_claimPos isEqualType []) || {count _claimPos < 2}) then {
        _claimPos = _gData get "position";
    };

    private _bucket = if (_objectiveId in _claimedPositionsByObjective) then {
        _claimedPositionsByObjective get _objectiveId
    } else {
        []
    };
    _bucket pushBack _claimPos;
    _claimedPositionsByObjective set [_objectiveId, _bucket];
} forEach _groups;

_cache
