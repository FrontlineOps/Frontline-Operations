/*
 * Function: FLO_fnc_getSafeUnvirtualizePos
 * Author: Frontline Operations Development Group
 * Description:
 * Ensures a position used for unvirtualizing a group is at least 500 meters
 * away from any player on foot or in a ground vehicle. If a player is closer,
 * the position is shifted to 500 meters away from the nearest player.
 *
 * Arguments:
 * 0: Position <ARRAY> - Original position for spawning
 * Return Value:
 * Adjusted position <ARRAY>
 *
 * Example:
 * [_position] call FLO_fnc_getSafeUnvirtualizePos;
 */

params [["_position", [0,0,0], [[]]]];

// Validate position - return nil if invalid to signal caller
if ((_position select 0) < 100 && (_position select 1) < 100) exitWith {_position};

private _nearestPlayer = objNull;
private _nearestDist = 999999;
{
    if (alive _x && {side _x == west}) then {
        private _veh = vehicle _x;
        if (_veh == _x || !(_veh isKindOf "Air")) then {
            private _dist = _position distance2D _x;
            if (_dist < _nearestDist) then {
                _nearestDist = _dist;
                _nearestPlayer = _x;
            };
        };
    };
} forEach allPlayers;

if (!isNull _nearestPlayer && {_nearestDist < 500}) then {
    private _dir = _nearestPlayer getDir _position;
    private _newPos = _nearestPlayer getPos [500, _dir];

    // Ensure the new position has proper terrain height (not underwater/underground)
    private _terrainHeight = getTerrainHeightASL _newPos;
    _position = [_newPos select 0, _newPos select 1, _terrainHeight max 0];
};

_position
