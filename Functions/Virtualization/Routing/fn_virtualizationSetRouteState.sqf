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
_groupData set ["currentWaypointIndex", 0];
_groupData set ["lastMoveTime", diag_tickTime];

if (_tempWaypointCount >= 0) then {
    _groupData set ["tempWaypointCount", _tempWaypointCount];
} else {
    _groupData set ["tempWaypointCount", count _waypoints];
};

if (count _waypoints > 0) then {
    private _wpSpeed = (_waypoints select 0) select 3;
    _groupData set ["virtualSpeed", [(_groupData get "groupType"), _wpSpeed] call FLO_fnc_virtualizationComputeVirtualSpeed];
};

[_groupData, _runtimeState] call FLO_fnc_virtualizationSetRuntimeState;

true
