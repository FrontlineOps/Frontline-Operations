/*
 * Function: FLO_fnc_virtualizationSetRouteState
 */

params [
    "_groupData",
    "_waypoints",
    ["_sourceTag", ""],
    ["_runtimeState", "moving"],
    ["_tempWaypointCount", -1]
];

[_groupData] call FLO_fnc_virtualizationClearPathRequest;
_groupData set ["waypoints", _waypoints];
_groupData set ["pathSource", _sourceTag];
_groupData set ["patrolConfig", []];
_groupData set ["autoPatrol", false];
_groupData set ["idleHelicopterParked", false];
_groupData set ["currentWaypointIndex", 0];
_groupData set ["lastMoveTime", diag_tickTime];
_groupData set ["virtualMoveCarryMeters", 0];

if (_tempWaypointCount >= 0) then {
    _groupData set ["tempWaypointCount", _tempWaypointCount];
} else {
    _groupData set ["tempWaypointCount", count _waypoints];
};

[_groupData] call FLO_fnc_virtualizationRefreshCurrentWaypointSpeed;

[_groupData, _runtimeState] call FLO_fnc_virtualizationSetRuntimeState;

true
