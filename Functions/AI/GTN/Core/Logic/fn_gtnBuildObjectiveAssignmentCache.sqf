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
    ["garrisonCounts", createHashMap],
    ["defenderCounts", createHashMap],
    ["claimedPositionsByObjective", createHashMap]
];

if (isNil "_cmdr") exitWith { _cache };

private _groups = FLO_virtualGroups get "_groups";
private _ownSide = _cmdr get "_ownSide";
private _attackCounts = _cache get "attackCounts";
private _garrisonCounts = _cache get "garrisonCounts";
private _defenderCounts = _cache get "defenderCounts";
private _claimedPositionsByObjective = _cache get "claimedPositionsByObjective";

{
    private _gData = _y;
    if ((_gData get "side") != _ownSide) then { continue };

    private _order = _gData get "commanderOrder";
    if (_order == "ATTACK") then {
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
        if (_objectiveId == "") then { continue };

        private _garrisonCount = if (_objectiveId in _garrisonCounts) then {
            _garrisonCounts get _objectiveId
        } else {
            0
        };
        _garrisonCounts set [_objectiveId, _garrisonCount + 1];

        private _defenderCount = if (_objectiveId in _defenderCounts) then {
            _defenderCounts get _objectiveId
        } else {
            0
        };
        _defenderCounts set [_objectiveId, _defenderCount + 1];

        private _claimPos = _gData get "garrisonPosition";
        if !(_claimPos isEqualType [] && {count _claimPos >= 2}) then {
            _claimPos = _gData get "position";
        };

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
    if !(_claimPos isEqualType [] && {count _claimPos >= 2}) then {
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
