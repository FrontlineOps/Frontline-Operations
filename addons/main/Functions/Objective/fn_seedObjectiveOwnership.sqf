/*
 * Function: FLO_fnc_seedObjectiveOwnership
 * Author: Frontline Operations Development Group
 * Description:
 *   Seeds initial EAST/WEST objective ownership from the selected start position.
 *
 * Arguments:
 *   0: Start position <ARRAY>
 *   1: WEST territory ratio <NUMBER> - Default 0.5
 *
 * Returns:
 *   BOOL - true when ownership was seeded
 */

if (!isServer) exitWith { false };
if (isNil "FLO_Objectives" || {FLO_Objectives isEqualTo []}) exitWith { false };

params [["_startPos", [], [[]]], ["_westRatio", 0.5, [0]]];

private _allObjectives = keys FLO_Objectives;
private _objectiveCount = count _allObjectives;
private _targetWestCount = round (_objectiveCount * _westRatio);
if (_objectiveCount > 1) then {
    if (_targetWestCount < 1) then { _targetWestCount = 1; };
    if (_targetWestCount > (_objectiveCount - 1)) then { _targetWestCount = _objectiveCount - 1; };
} else {
    _targetWestCount = _objectiveCount;
};
private _westOwned = [];
private _queue = [];
private _queued = createHashMap;
private _westSet = createHashMap;

private _seedObjId = ([_allObjectives, [], {
    (((FLO_Objectives get _x) get "position") distance2D _startPos)
}, "ASCEND"] call BIS_fnc_sortBy) select 0;

_queue pushBack _seedObjId;
_queued set [_seedObjId, true];

while {_queue isNotEqualTo [] && {count _westOwned < _targetWestCount}} do {
    private _objId = _queue deleteAt 0;
    if (isNil {_westSet get _objId}) then {
        private _objData = FLO_Objectives get _objId;
        _objData set ["owner", west];
        FLO_Objectives set [_objId, _objData];
        _westOwned pushBack _objId;
        _westSet set [_objId, true];

        private _neighbors = +(_objData get "linkedObjectives");
        _neighbors = [_neighbors, [], {
            (((FLO_Objectives get _x) get "position") distance2D _startPos)
        }, "ASCEND"] call BIS_fnc_sortBy;

        {
            if (isNil {_queued get _x}) then {
                _queue pushBack _x;
                _queued set [_x, true];
            };
        } forEach _neighbors;

        if (_queue isEqualTo [] && {count _westOwned < _targetWestCount}) then {
            private _closestUnqueued = ([_allObjectives select { isNil {_queued get _x} }, [], {
                (((FLO_Objectives get _x) get "position") distance2D _startPos)
            }, "ASCEND"] call BIS_fnc_sortBy) select 0;
            _queue pushBack _closestUnqueued;
            _queued set [_closestUnqueued, true];
        };
    };
};

private _eastOwned = [];
{
    if (isNil {_westSet get _x}) then {
        private _objData = FLO_Objectives get _x;
        _objData set ["owner", east];
        FLO_Objectives set [_x, _objData];
        _eastOwned pushBack _x;
    };
} forEach _allObjectives;

// Ensure both sides own at least one objective.
if (_westOwned isEqualTo [] || {_eastOwned isEqualTo []}) then {
    if (count _allObjectives > 1) then {
        private _sorted = [_allObjectives, [], {
            (((FLO_Objectives get _x) get "position") distance2D _startPos)
        }, "ASCEND"] call BIS_fnc_sortBy;
        private _westObj = _sorted select 0;
        private _eastObj = _sorted select -1;

        private _westObjData = FLO_Objectives get _westObj;
        _westObjData set ["owner", west];
        FLO_Objectives set [_westObj, _westObjData];

        private _eastObjData = FLO_Objectives get _eastObj;
        _eastObjData set ["owner", east];
        FLO_Objectives set [_eastObj, _eastObjData];

        _westOwned = [_westObj];
        _eastOwned = [_eastObj];
    };
};

// Refresh markers for seeded ownership.
{
    [_x, FLO_Objectives get _x] call FLO_fnc_createObjectiveMarker;
} forEach _allObjectives;

publicVariable "FLO_Objectives";
FLO_ObjectiveRuntimeState = [] call FLO_fnc_buildObjectiveRuntimeState;
[] call FLO_fnc_publishObjectiveRuntimeState;

["OBJECTIVE", 2, format ["Seeded ownership from start position: WEST=%1 EAST=%2 ratio=%3 (anchor=%4)",
    ({((FLO_Objectives get _x) get "owner") isEqualTo west} count _allObjectives),
    ({((FLO_Objectives get _x) get "owner") isEqualTo east} count _allObjectives),
    _westRatio,
    _startPos
]] call FLO_fnc_log;

true
