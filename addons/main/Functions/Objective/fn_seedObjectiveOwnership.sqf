/*
 * Seeds initial EAST/WEST ownership while anchoring the configured player side
 * at the selected campaign start position.
 */

if (!isServer) exitWith { false };
if (isNil "FLO_Objectives" || {FLO_Objectives isEqualTo []}) exitWith { false };

params [
    ["_startPos", [], [[]]],
    ["_westRatio", 0.5, [0]],
    ["_anchorSide", sideUnknown]
];

if !(_anchorSide in [west, east]) then {
    throw format ["Cannot seed objective ownership for unsupported anchor side %1", _anchorSide];
};

private _allObjectives = keys FLO_Objectives;
private _objectiveCount = count _allObjectives;
private _targetWestCount = round (_objectiveCount * _westRatio);
if (_objectiveCount > 1) then {
    _targetWestCount = (_targetWestCount max 1) min (_objectiveCount - 1);
} else {
    _targetWestCount = _objectiveCount;
};

private _targetAnchorCount = [
    _targetWestCount,
    _objectiveCount - _targetWestCount
] select (_anchorSide isEqualTo east);
if (_objectiveCount == 1) then {
    _targetAnchorCount = 1;
};
private _opposingSide = [east, west] select (_anchorSide isEqualTo east);
private _anchorOwned = [];
private _opposingOwned = [];
private _queue = [];
private _queued = createHashMap;
private _anchorSet = createHashMap;

private _seedObjectiveId = ([_allObjectives, [], {
    (((FLO_Objectives get _x) get "position") distance2D _startPos)
}, "ASCEND"] call BIS_fnc_sortBy) select 0;

_queue pushBack _seedObjectiveId;
_queued set [_seedObjectiveId, true];

while {_queue isNotEqualTo [] && {count _anchorOwned < _targetAnchorCount}} do {
    private _objectiveId = _queue deleteAt 0;
    if (isNil {_anchorSet get _objectiveId}) then {
        private _objective = FLO_Objectives get _objectiveId;
        _objective set ["owner", _anchorSide];
        FLO_Objectives set [_objectiveId, _objective];
        _anchorOwned pushBack _objectiveId;
        _anchorSet set [_objectiveId, true];

        private _neighbors = +(_objective get "linkedObjectives");
        _neighbors = [_neighbors, [], {
            (((FLO_Objectives get _x) get "position") distance2D _startPos)
        }, "ASCEND"] call BIS_fnc_sortBy;

        {
            if (isNil {_queued get _x}) then {
                _queue pushBack _x;
                _queued set [_x, true];
            };
        } forEach _neighbors;

        if (_queue isEqualTo [] && {count _anchorOwned < _targetAnchorCount}) then {
            private _unqueued = _allObjectives select { isNil {_queued get _x} };
            private _closestUnqueued = ([_unqueued, [], {
                (((FLO_Objectives get _x) get "position") distance2D _startPos)
            }, "ASCEND"] call BIS_fnc_sortBy) select 0;
            _queue pushBack _closestUnqueued;
            _queued set [_closestUnqueued, true];
        };
    };
};

{
    if (isNil {_anchorSet get _x}) then {
        private _objective = FLO_Objectives get _x;
        _objective set ["owner", _opposingSide];
        FLO_Objectives set [_x, _objective];
        _opposingOwned pushBack _x;
    };
} forEach _allObjectives;

if ((_anchorOwned isEqualTo [] || {_opposingOwned isEqualTo []}) && {_objectiveCount > 1}) then {
    private _sorted = [_allObjectives, [], {
        (((FLO_Objectives get _x) get "position") distance2D _startPos)
    }, "ASCEND"] call BIS_fnc_sortBy;
    private _anchorObjectiveId = _sorted select 0;
    private _opposingObjectiveId = _sorted select -1;

    private _anchorObjective = FLO_Objectives get _anchorObjectiveId;
    _anchorObjective set ["owner", _anchorSide];
    FLO_Objectives set [_anchorObjectiveId, _anchorObjective];

    private _opposingObjective = FLO_Objectives get _opposingObjectiveId;
    _opposingObjective set ["owner", _opposingSide];
    FLO_Objectives set [_opposingObjectiveId, _opposingObjective];
};

{
    [_x, FLO_Objectives get _x] call FLO_fnc_createObjectiveMarker;
} forEach _allObjectives;

publicVariable "FLO_Objectives";
FLO_ObjectiveRuntimeState = [] call FLO_fnc_buildObjectiveRuntimeState;
[] call FLO_fnc_publishObjectiveRuntimeState;

["OBJECTIVE", 3, format [
    "Seeded ownership: WEST=%1 EAST=%2 westRatio=%3 startSide=%4 anchor=%5",
    ({((FLO_Objectives get _x) get "owner") isEqualTo west} count _allObjectives),
    ({((FLO_Objectives get _x) get "owner") isEqualTo east} count _allObjectives),
    _westRatio,
    [_anchorSide] call FLO_fnc_sideKey,
    _startPos
]] call FLO_fnc_log;

true
