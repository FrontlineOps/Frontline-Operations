/*
 * Function: FLO_fnc_virtualizationAdvanceTerminalWaypoint
 */

params ["_groupId", "_groupData", "_currentIdx", "_waypoints", "_wpType"];

private _isLastWp = _currentIdx >= (count _waypoints - 1);

if (_isLastWp) exitWith {
    [_groupData, "holding"] call FLO_fnc_virtualizationSetRuntimeState;
    ["VIRTUALIZATION", 4, format ["Group %1 reached final %2 waypoint - entering holding state", _groupId, _wpType]] call FLO_fnc_log;
};

_waypoints deleteAt _currentIdx;
_groupData set ["waypoints", _waypoints];
_groupData set ["currentWaypointIndex", _currentIdx min (count _waypoints - 1)];
[_groupData, "moving"] call FLO_fnc_virtualizationSetRuntimeState;
["VIRTUALIZATION", 4, format ["Group %1 completed %2 waypoint - advancing to next", _groupId, _wpType]] call FLO_fnc_log;
