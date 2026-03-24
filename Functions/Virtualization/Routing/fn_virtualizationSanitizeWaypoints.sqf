/*
 * Function: FLO_fnc_virtualizationSanitizeWaypoints
 */

params ["_groupType", "_waypoints"];

private _isNavalGroup = _groupType in ["boat", "naval", "submarine"];
private _sanitizedWaypoints = [];

{
    if !(_x isEqualType [] && {count _x >= 7}) then { continue };
    private _wpPos = _x select 0;
    if !(_wpPos isEqualType [] && {count _wpPos >= 2}) then { continue };

    if (!_isNavalGroup && {surfaceIsWater _wpPos}) then {
        private _safePos = [_wpPos, 500] call FLO_fnc_getSafeLandPos;
        private _newWp = +_x;
        _newWp set [0, _safePos];
        _sanitizedWaypoints pushBack _newWp;
    } else {
        _sanitizedWaypoints pushBack _x;
    };
} forEach _waypoints;

_sanitizedWaypoints
