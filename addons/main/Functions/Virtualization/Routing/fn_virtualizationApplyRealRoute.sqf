/*
 * Function: FLO_fnc_virtualizationApplyRealRoute
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies the current virtual route or patrol config to an active real group.
 */

params ["_groupId", "_groupData"];

private _realGroup = _groupData get "realGroup";
if (isNull _realGroup) exitWith { false };

private _homeObjective = _groupData get "homeObjective";
if (_homeObjective isEqualTo "civ_building") then {
    {
        _x disableAI "PATH";
        _x disableAI "MOVE";
    } forEach units _realGroup;
};

private _patrolConfig = _groupData get "patrolConfig";
private _archetype = [(_groupData get "groupType")] call FLO_fnc_virtualizationGetArchetype;
private _movementDomain = _archetype get "movementDomain";
if (_patrolConfig isNotEqualTo [] && {_movementDomain != "LAND"}) exitWith {
    _patrolConfig params ["_patrolCenter", "_patrolRadius", "_wpCount", "_behavior", "_speed"];
    private _applied = [_realGroup, _patrolCenter, _patrolRadius, _wpCount, _behavior, _speed, _movementDomain] call FLO_fnc_taskPatrol;
    if (_applied) then {
        ["VIRTUALIZATION", 5, format ["Group %1: Applied patrol route (center %2, radius %3)", _groupId, _patrolCenter, _patrolRadius]] call FLO_fnc_log;
    };
    _applied
};

if (_groupData get "noWaypoints") exitWith {
    [_realGroup] call CBA_fnc_clearWaypoints;
    true
};

private _waypoints = _groupData get "waypoints";
if (_waypoints isEqualTo []) exitWith {
    [_realGroup] call CBA_fnc_clearWaypoints;
    true
};

private _hadCycle = (_waypoints findIf { (_x select 1) == "CYCLE" }) != -1 || {_groupData get "autoPatrol"};
private _physicalWaypoints = _waypoints apply {
    private _waypoint = +_x;
    private _wpType = _waypoint select 1;
    private _wpBehavior = _waypoint select 2;
    private _wpMode = _waypoint select 5;

    private _effectiveType = switch (_wpType) do {
        case "CYCLE": { "MOVE" };
        case "SAD": { _wpBehavior = "COMBAT"; _wpMode = "RED"; "MOVE" };
        case "DESTROY": { _wpBehavior = "COMBAT"; _wpMode = "RED"; "MOVE" };
        case "GUARD": { _wpBehavior = "COMBAT"; _wpMode = "RED"; "HOLD" };
        default { _wpType };
    };

    if (_wpType != _effectiveType) then {
        ["VIRTUALIZATION", 4, format ["Group %1: Converted %2 to %3", _groupId, _wpType, _effectiveType]] call FLO_fnc_log;
    };

    _waypoint set [1, _effectiveType];
    _waypoint set [2, _wpBehavior];
    _waypoint set [5, _wpMode];
    _waypoint
};

private _routeApplied = [
    _realGroup,
    _physicalWaypoints,
    _movementDomain,
    format ["VG_ACTIVATE_%1", _groupId],
    _hadCycle,
    true,
    [0, 0, 0],
    _movementDomain == "LAND"
] call FLO_fnc_taskApplyRoute;
if (!_routeApplied) exitWith { false };

_realGroup setSpeedMode ((_physicalWaypoints select 0) select 3);

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
