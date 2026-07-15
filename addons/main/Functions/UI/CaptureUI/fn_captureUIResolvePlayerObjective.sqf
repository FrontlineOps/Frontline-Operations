/* Resolves the nearest maintained objective containing a player. */
params ["_player", "_objectiveIds"];

private _position = getPosATL _player;
private _nearestDistance = 1e12;
private _match = [];

{
    private _objectiveId = _x;
    private _objective = FLO_Objectives get _objectiveId;
    private _distance = (_objective get "position") distance2D _position;
    if (_distance < (_objective get "radius") && {_distance < _nearestDistance}) then {
        _nearestDistance = _distance;
        _match = [_objectiveId, _objective];
    };
} forEach _objectiveIds;

_match
