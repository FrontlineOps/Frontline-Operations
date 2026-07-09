/*
 * Function: FLO_fnc_transportPickReserveSpawnObjective
 * Description:
 *   Chooses the best objective to stage the next reserve transport carrier
 *   from, preferring objectives with fewer existing reserve carriers and
 *   breaking ties toward deeper supply nodes.
 *
 * Arguments:
 *   0: Candidate objective IDs <ARRAY>
 *   1: Reserve counts by objective <HASHMAP>
 *   2: Active supply nodes <HASHMAP>
 *   3: Fallback objective ID <STRING>
 *
 * Return Value:
 *   STRING - Selected objective ID
 */

params [
    ["_spawnObjectiveIds", [], [[]]],
    ["_countsByObjective", createHashMap, [createHashMap]],
    ["_activeSupplyNodes", createHashMap, [createHashMap]],
    ["_fallbackObjectiveId", "", [""]]
];

private _spawnObjectiveId = _fallbackObjectiveId;
private _spawnDepth = -1;
private _spawnReserveCount = 1e12;

{
    private _objectiveId = _x;
    private _reserveCount = if (_objectiveId in _countsByObjective) then {
        _countsByObjective get _objectiveId
    } else {
        0
    };
    private _depth = if (_objectiveId in _activeSupplyNodes) then {
        (_activeSupplyNodes get _objectiveId) get "depth"
    } else {
        0
    };

    if (
        _reserveCount < _spawnReserveCount
        || {_reserveCount == _spawnReserveCount && {_depth > _spawnDepth}}
    ) then {
        _spawnObjectiveId = _objectiveId;
        _spawnDepth = _depth;
        _spawnReserveCount = _reserveCount;
    };
} forEach _spawnObjectiveIds;

_spawnObjectiveId
