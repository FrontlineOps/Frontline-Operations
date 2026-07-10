/*
 * Function: FLO_fnc_virtualizationApplyDirectWaypointUpdate
 */

params ["_groupId", "_groupData", "_sanitizedWaypoints", "_sourceTag"];

if (_sanitizedWaypoints isNotEqualTo []) then {
    [_groupData, _sanitizedWaypoints, _sourceTag, "moving"] call FLO_fnc_virtualizationSetRouteState;
    private _speed = _groupData get "virtualSpeed";
    ["VIRTUALIZATION", 3, format ["Set up virtual movement for group %1 (Speed: %2 m/s)", _groupId, _speed]] call FLO_fnc_log;
} else {
    [_groupData] call FLO_fnc_virtualizationClearPathRequest;
    _groupData set ["waypoints", []];
    _groupData set ["pathSource", _sourceTag];
    _groupData set ["patrolConfig", []];
    _groupData set ["autoPatrol", false];
    _groupData set ["currentWaypointIndex", 0];
    _groupData set ["nextProcessAt", 0];
    [_groupData, "idle"] call FLO_fnc_virtualizationSetRuntimeState;
};

if (_groupData get "isActive") then {
    [_groupId, _groupData] call FLO_fnc_virtualizationApplyRealRoute;
};

true
