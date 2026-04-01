/*
 * Function: FLO_fnc_virtualizationResolveInactiveUpdateProfile
 *
 * Description:
 *   Resolves the full-update cadence, movement-only cadence, and strategic
 *   virtual speed multiplier for an inactive group outside activation range.
 */

params ["_groupData", "_nearestDist", "_activationDist"];

private _ringDist = (_nearestDist - _activationDist) max 0;
private _fullUpdateInterval = if (_ringDist <= 250) then {
    1.25
} else {
    if (_ringDist <= 1000) then { 3 } else { 10 };
};
private _movementUpdateInterval = _fullUpdateInterval;
private _speedMultiplier = 1;

private _waypoints = _groupData get "waypoints";
private _currentWpIdx = _groupData get "currentWaypointIndex";
if (count _waypoints == 0 || {_currentWpIdx >= count _waypoints}) exitWith {
    [_fullUpdateInterval, _movementUpdateInterval, _speedMultiplier]
};

private _wp = _waypoints select _currentWpIdx;
private _wpPos = _wp select 0;
private _wpType = _wp select 1;
private _completionRadius = _wp param [6, 20];
private _position = _groupData get "position";

if !(_wpType in ["MOVE", "LOITER", "SAD", "DESTROY", "SENTRY", "CYCLE", "GUARD"]) exitWith {
    [_fullUpdateInterval, _movementUpdateInterval, _speedMultiplier]
};

if ((_position distance2D _wpPos) <= _completionRadius) exitWith {
    [_fullUpdateInterval, _movementUpdateInterval, _speedMultiplier]
};

_movementUpdateInterval = if (_ringDist <= 250) then {
    0.35
} else {
    if (_ringDist <= 1000) then { 1 } else { 3 };
};

private _groupType = _groupData get "groupType";
_speedMultiplier = switch (_groupType) do {
    case "infantry";
    case "civilian";
    case "civ_pedestrian";
    case "civ_building": { 1.15 };
    case "motorized";
    case "civ_car";
    case "civilianVehicle": { 1.6 };
    case "mechanized": { 1.5 };
    case "armor";
    case "mobile_aa": { 1.35 };
    case "helicopter";
    case "air";
    case "jet": { 1.0 };
    default { 1.2 };
};

[_fullUpdateInterval, _movementUpdateInterval, _speedMultiplier]
