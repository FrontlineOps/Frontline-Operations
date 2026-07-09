/*
 * Function: FLO_fnc_gtnBuildObjectiveReserveBands
 * Author: Frontline Operations Development Group
 *
 * Description:
 * Build reserve eligibility bands by walking the friendly objective graph out
 * from one or more seed objectives. Seeds are band 0, their friendly links are
 * band 1, and so on up to the requested depth.
 *
 * Arguments:
 * 0: GTN Commander <HASHMAP>
 * 1: Seed Objective IDs <ARRAY>
 * 2: Max Depth <NUMBER>
 *
 * Return Value:
 * Objective ID -> Band <HASHMAP>
 */

params [
    ["_cmdr", nil],
    ["_seedObjectiveIds", [], [[]]],
    ["_maxDepth", 0, [0]]
];

private _ws = _cmdr get "_worldState";
private _objectives = _ws call ["_getObjectives", []];
private _ownSide = _cmdr get "_ownSide";
private _bands = createHashMap;
private _frontier = [];

{
    if (_x in _bands) then { continue };

    private _seedObjective = _objectives get _x;
    if ((_seedObjective get "owner") != _ownSide) then { continue };

    _bands set [_x, 0];
    _frontier pushBack _x;
} forEach _seedObjectiveIds;

if (_maxDepth <= 0 || {_frontier isEqualTo []}) exitWith { _bands };

for "_depth" from 0 to (_maxDepth - 1) do {
    private _nextFrontier = [];

    {
        private _objective = _objectives get _x;

        {
            if (_x in _bands) then { continue };

            private _linkedObjective = _objectives get _x;
            if ((_linkedObjective get "owner") != _ownSide) then { continue };

            _bands set [_x, _depth + 1];
            _nextFrontier pushBack _x;
        } forEach (_objective get "linkedObjectives");
    } forEach _frontier;

    if (_nextFrontier isEqualTo []) exitWith {};
    _frontier = _nextFrontier;
};

_bands
