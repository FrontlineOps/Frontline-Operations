/*
 * Function: FLO_fnc_buildObjectiveLinks
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds the objective adjacency graph from objective positions. Objectives
 *   first link to nearby neighbors within the configured base radius, then the
 *   remaining disconnected graph components are bridged by nearest-neighbor
 *   continuity links so sparse maps still form one usable operational graph.
 *
 * Arguments:
 *   0: Objective map <HASHMAP>
 *
 * Return Value:
 *   HASHMAP - objectiveId -> linked objective IDs
 */

params ["_objectives"];

["init"] call FLO_fnc_objectiveConfig;

private _objectiveIds = keys _objectives;
private _adjacency = createHashMap;
private _baseLinkDistance = (["get", "linkDistance"] call FLO_fnc_objectiveConfig) max 0;
private _baseLinkCount = 0;
private _bridgeLinkCount = 0;

{
    _adjacency set [_x, []];
} forEach _objectiveIds;

for "_i" from 0 to ((count _objectiveIds) - 2) do {
    private _id = _objectiveIds select _i;
    private _pos = (_objectives get _id) get "position";

    for "_j" from (_i + 1) to ((count _objectiveIds) - 1) do {
        private _otherId = _objectiveIds select _j;
        private _otherPos = (_objectives get _otherId) get "position";
        if ((_pos distance2D _otherPos) > _baseLinkDistance) then { continue };

        (_adjacency get _id) pushBack _otherId;
        (_adjacency get _otherId) pushBack _id;
        _baseLinkCount = _baseLinkCount + 1;
    };
};

while {true} do {
    private _components = [];
    private _assigned = createHashMap;

    {
        if (_x in _assigned) then { continue };

        private _component = [];
        private _frontier = [_x];
        _assigned set [_x, true];

        while {_frontier isNotEqualTo []} do {
            private _currentId = _frontier deleteAt 0;
            _component pushBack _currentId;

            {
                if (_x in _assigned) then { continue };
                _assigned set [_x, true];
                _frontier pushBack _x;
            } forEach (_adjacency get _currentId);
        };

        _components pushBack _component;
    } forEach _objectiveIds;

    if ((count _components) <= 1) exitWith {};

    private _bestPair = [];
    private _bestDistance = 1e12;

    for "_i" from 0 to ((count _components) - 2) do {
        private _leftComponent = _components select _i;

        {
            private _leftId = _x;
            private _leftPos = (_objectives get _leftId) get "position";

            for "_j" from (_i + 1) to ((count _components) - 1) do {
                private _rightComponent = _components select _j;

                {
                    private _rightId = _x;
                    private _rightPos = (_objectives get _rightId) get "position";
                    private _dist = _leftPos distance2D _rightPos;

                    if (_dist < _bestDistance) then {
                        _bestDistance = _dist;
                        _bestPair = [_leftId, _rightId];
                    };
                } forEach _rightComponent;
            };
        } forEach _leftComponent;
    };

    if ((count _bestPair) != 2) exitWith {};

    private _fromId = _bestPair select 0;
    private _toId = _bestPair select 1;
    (_adjacency get _fromId) pushBackUnique _toId;
    (_adjacency get _toId) pushBackUnique _fromId;
    _bridgeLinkCount = _bridgeLinkCount + 1;
};

{
    private _objectiveId = _x;
    private _originPos = (_objectives get _objectiveId) get "position";
    private _sortedLinks = [(_adjacency get _objectiveId), [], {
        ((_objectives get _x) get "position") distance2D _originPos
    }, "ASCEND"] call BIS_fnc_sortBy;

    (_objectives get _objectiveId) set ["linkedObjectives", _sortedLinks];
} forEach _objectiveIds;

diag_log format [
    "[OBJ_LINK] Built objective links for %1 objectives: base=%2 continuity=%3 radius=%4m",
    count _objectiveIds,
    _baseLinkCount,
    _bridgeLinkCount,
    round _baseLinkDistance
];

_adjacency
