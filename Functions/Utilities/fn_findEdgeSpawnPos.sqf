/*
 * Function: FLO_fnc_findEdgeSpawnPos
 * Author: Frontline Operations Development Group
 * Description:
 * Finds a spawn position on the nearest map edge relative to a target position.
 *
 * Parameters:
 * 0: Target Position <ARRAY> - Position to find nearest edge for
 *
 * Returns:
 * Spawn Position <ARRAY> - Position on map edge
 *
 * Example:
 * [getPos player] call FLO_fnc_findEdgeSpawnPos;
 */

params ["_targetPos"];
private _worldSize = worldSize;
private _spawnPos = [];

if (_targetPos select 0 < _worldSize / 2) then {
    _spawnPos = [-500, _targetPos select 1, 0];
} else {
    _spawnPos = [_worldSize + 500, _targetPos select 1, 0];
};

_spawnPos 