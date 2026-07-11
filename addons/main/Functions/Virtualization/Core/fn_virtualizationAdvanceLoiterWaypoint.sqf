/*
 * Function: FLO_fnc_virtualizationAdvanceLoiterWaypoint
 */

params ["_groupData", "_currentIdx", "_waypoints", "_isPatrol", "_currentWp"];

private _timeout = _currentWp param [6, 60];
private _loiterStart = _groupData get "loiterStartTime";

if (_loiterStart == 0) exitWith {
    _groupData set ["loiterStartTime", diag_tickTime];
};

if (diag_tickTime - _loiterStart <= _timeout) exitWith {};

_groupData set ["loiterStartTime", 0];
private _nextIdx = _currentIdx + 1;

if (_nextIdx >= count _waypoints) then {
    _nextIdx = 0;
    if (!_isPatrol) then {
        [_groupData, "idle"] call FLO_fnc_virtualizationSetRuntimeState;
    };
};

_groupData set ["currentWaypointIndex", _nextIdx];
