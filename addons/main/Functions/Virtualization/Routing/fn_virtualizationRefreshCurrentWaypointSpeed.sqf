/*
 * Function: FLO_fnc_virtualizationRefreshCurrentWaypointSpeed
 */

params ["_groupData"];

private _waypoints = _groupData get "waypoints";
private _currentWpIdx = _groupData get "currentWaypointIndex";

if (_waypoints isEqualTo [] || {_currentWpIdx >= count _waypoints}) exitWith {
    _groupData set ["virtualSpeed", 0];
    _groupData set ["virtualMoveCarryMeters", 0];
    true
};

private _wp = _waypoints select _currentWpIdx;
private _wpSpeed = _wp select 3;

_groupData set ["virtualSpeed", [_groupData, _wpSpeed] call FLO_fnc_virtualizationComputeVirtualSpeed];

true
