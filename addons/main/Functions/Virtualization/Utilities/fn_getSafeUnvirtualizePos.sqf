/*
 * Function: FLO_fnc_getSafeUnvirtualizePos
 * Author: Frontline Operations Development Group
 * Description:
 * Ensures a position used for unvirtualizing a group is not too close to a
 * player on foot or in a ground vehicle. It first searches for the nearest
 * small local offset that preserves the route shape before falling back to a
 * simple push away from the nearest player.
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

private _eligiblePlayers = allPlayers select {
    alive _x && {
        private _veh = vehicle _x;
        _veh == _x || {!(_veh isKindOf "Air")}
    }
};
if (_eligiblePlayers isEqualTo []) exitWith { _position };

private _clearanceMeters = 150;
private _nearestPlayer = objNull;
private _nearestDist = 999999;
{
    private _dist = _position distance2D _x;
    if (_dist < _nearestDist) then {
        _nearestDist = _dist;
        _nearestPlayer = _x;
    };
} forEach _eligiblePlayers;

if (!isNull _nearestPlayer && {_nearestDist < _clearanceMeters}) then {
    private _candidate = [];
    {
        private _radius = _x;
        for "_bearing" from 0 to 330 step 30 do {
            private _probe = _position getPos [_radius, _bearing];
            if !(surfaceIsWater _probe) then {
                private _clear = true;
                {
                    if ((_probe distance2D _x) < _clearanceMeters) exitWith {
                        _clear = false;
                    };
                } forEach _eligiblePlayers;

                if (_clear) exitWith {
                    _candidate = _probe;
                };
            };
        };
        if (count _candidate >= 2) exitWith {};
    } forEach [40, 80, 120, 160, 220, 300];

    if (count _candidate < 2) then {
        private _dir = _nearestPlayer getDir _position;
        _candidate = _nearestPlayer getPos [_clearanceMeters, _dir];
    };

    private _terrainHeight = getTerrainHeightASL _candidate;
    _position = [_candidate select 0, _candidate select 1, _terrainHeight max 0];
};

_position
