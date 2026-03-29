/*
 * Function: FLO_fnc_logisticsNetworkGetCachedSpawnPosition
 * Author: Frontline Operations Development Group
 * Description:
 *   Resolves a reusable spawn position for a supply source objective. Road
 *   positions are cached per objective so logistics dispatch does not repeat
 *   expensive nearRoads scans every time a reinforcement group is created.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Objective ID <STRING>
 *
 * Return Value:
 *   ARRAY - Spawn position [x,y,z]
 */

params ["_net", "_objectiveId"];

if (_objectiveId == "") exitWith { [0, 0, 0] };

private _objective = FLO_Objectives get _objectiveId;
private _spawnCache = _net get "_spawnRoadCache";
private _cacheEntry = if (_objectiveId in _spawnCache) then {
    _spawnCache get _objectiveId
} else {
    private _centerPos = _objective get "position";
    private _radius = (_objective get "radius") max 80;
    private _searchRadius = _radius + 120;
    private _roadPositions = [];

    {
        private _roadPos = getPos _x;
        if ((_roadPos distance2D _centerPos) > _searchRadius) then { continue };
        _roadPos set [2, 0];
        _roadPositions pushBackUnique _roadPos;
        if ((count _roadPositions) >= 16) exitWith {};
    } forEach (_centerPos nearRoads _searchRadius);

    private _newEntry = createHashMapFromArray [
        ["positions", _roadPositions],
        ["nextIndex", floor random ((count _roadPositions) max 1)]
    ];
    _spawnCache set [_objectiveId, _newEntry];
    _newEntry
};

private _roadPositions = _cacheEntry get "positions";
if ((count _roadPositions) > 0) then {
    private _nextIndex = _cacheEntry get "nextIndex";
    private _spawnPos = +(_roadPositions select (_nextIndex mod (count _roadPositions)));
    _cacheEntry set ["nextIndex", _nextIndex + 1];
    _spawnPos
} else {
    private _spawnPos = [_objectiveId] call FLO_fnc_getRandomObjectivePos;
    if (_spawnPos isEqualTo [0, 0, 0]) then {
        _spawnPos = +(_objective get "position");
        _spawnPos set [2, 0];
    };
    _spawnPos
}
