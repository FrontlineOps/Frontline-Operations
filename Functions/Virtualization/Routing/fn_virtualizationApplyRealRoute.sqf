/*
 * Function: FLO_fnc_virtualizationApplyRealRoute
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies the current virtual route or patrol config to an active real group.
 */

params ["_groupId", "_groupData"];

private _realGroup = _groupData get "realGroup";
if (isNull _realGroup) exitWith { false };

[_realGroup] call CBA_fnc_clearWaypoints;

private _homeObjective = _groupData get "homeObjective";
if (_homeObjective isEqualTo "civ_building") then {
    {
        _x disableAI "PATH";
        _x disableAI "MOVE";
    } forEach units _realGroup;
};

private _patrolConfig = _groupData get "patrolConfig";
if (_patrolConfig isNotEqualTo []) exitWith {
    _patrolConfig params ["_patrolCenter", "_patrolRadius", "_wpCount", "_behavior", "_speed"];
    [_realGroup, _patrolCenter, _patrolRadius, _wpCount, _behavior, _speed] call FLO_fnc_taskPatrol;
    ["VIRTUALIZATION", 3, format ["Group %1: Applied patrol route (center %2, radius %3)", _groupId, _patrolCenter, _patrolRadius]] call FLO_fnc_log;
    true
};

if (_groupData get "noWaypoints") exitWith { true };

private _waypoints = _groupData get "waypoints";
if (count _waypoints == 0) exitWith { true };

private _firstWpType = (_waypoints select 0) select 1;
if (_firstWpType == "CYCLE" && {count _waypoints == 1}) exitWith {
    ["VIRTUALIZATION", 2, format ["Group %1 has only CYCLE waypoint - skipping", _groupId]] call FLO_fnc_log;
    true
};

private _hadCycle = (_waypoints findIf { (_x select 1) == "CYCLE" }) != -1;
private _filteredWaypoints = _waypoints select { (_x select 1) != "CYCLE" };

{
    private _wpPos = _x select 0;
    private _wpType = _x select 1;
    private _wpBehavior = _x select 2;
    private _wpSpeed = _x select 3;
    private _wpFormation = _x select 4;
    private _wpMode = _x select 5;
    private _wpCompletionRadius = _x param [6, 20];

    private _effectiveType = switch (_wpType) do {
        case "SAD": { _wpBehavior = "COMBAT"; _wpMode = "RED"; "MOVE" };
        case "DESTROY": { _wpBehavior = "COMBAT"; _wpMode = "RED"; "MOVE" };
        case "GUARD": { _wpBehavior = "COMBAT"; _wpMode = "RED"; "HOLD" };
        default { _wpType };
    };

    private _wp = _realGroup addWaypoint [_wpPos, 0];
    _wp setWaypointType _effectiveType;
    _wp setWaypointBehaviour _wpBehavior;
    _wp setWaypointSpeed _wpSpeed;
    _wp setWaypointFormation _wpFormation;
    _wp setWaypointCombatMode _wpMode;
    _wp setWaypointCompletionRadius _wpCompletionRadius;

    if (_wpType != _effectiveType) then {
        ["VIRTUALIZATION", 4, format ["Group %1: Converted %2 to %3", _groupId, _wpType, _effectiveType]] call FLO_fnc_log;
    };
} forEach _filteredWaypoints;

if (_hadCycle && {count waypoints _realGroup > 1}) then {
    private _lastWp = [_realGroup, (count waypoints _realGroup) - 1];
    _lastWp setWaypointStatements [
        "true",
        format ["(group this) setCurrentWaypoint [(group this), %1];", 1]
    ];
    ["VIRTUALIZATION", 4, format ["Group %1: Added loop statement to last waypoint", _groupId]] call FLO_fnc_log;
};

if ((_groupData get "groupType") == "helicopter" && {([_groupData] call FLO_fnc_virtualizationIsTransportCarrier)}) then {
    private _transportVehicles = ([_realGroup] call FLO_fnc_virtualizationCollectRealGroupVehicles) select { !isNull _x && {alive _x} };
    private _insertMode = _groupData get "transportInsertMode";
    private _targetAltitude = switch (_insertMode) do {
        case "AIR_DROP": { FLO_Transport_AirDropAltitude };
        case "AIR_LAND": { FLO_Transport_AirLandAltitude };
        default { 60 };
    };

    {
        _x flyInHeight _targetAltitude;
    } forEach _transportVehicles;
};

true
