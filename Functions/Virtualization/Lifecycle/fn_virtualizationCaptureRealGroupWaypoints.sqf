/*
 * Function: FLO_fnc_virtualizationCaptureRealGroupWaypoints
 */

params ["_groupId", "_groupData", "_realGroup"];

private _realWaypoints = waypoints _realGroup;
private _currentWpIndex = currentWaypoint _realGroup;
private _savedWaypoints = [];

if (count _realWaypoints > 0 && {_currentWpIndex < count _realWaypoints}) then {
    for "_i" from _currentWpIndex to (count _realWaypoints - 1) do {
        private _wp = _realWaypoints select _i;
        private _wpPos = waypointPosition _wp;

        if (_wpPos isEqualType [] && {count _wpPos >= 2} && {(_wpPos select 0) > 100 || (_wpPos select 1) > 100}) then {
            _savedWaypoints pushBack [
                _wpPos,
                waypointType _wp,
                waypointBehaviour _wp,
                waypointSpeed _wp,
                waypointFormation _wp,
                waypointCombatMode _wp
            ];
        };
    };
};

if (count _savedWaypoints > 0) exitWith {
    _groupData set ["waypoints", _savedWaypoints];
    _groupData set ["currentWaypointIndex", 0];
    ["VIRTUALIZATION", 4, format ["Saved %1 remaining waypoints from real group %2", count _savedWaypoints, _groupId]] call FLO_fnc_log;
    true
};

if (count _realWaypoints > 0 && {_currentWpIndex >= count _realWaypoints}) then {
    _groupData set ["waypoints", []];
    _groupData set ["currentWaypointIndex", 0];
    ["VIRTUALIZATION", 4, format ["Group %1 completed all waypoints - clearing virtual waypoints", _groupId]] call FLO_fnc_log;
};

false
