/*
 * Function: FLO_fnc_virtualizationApplyBootstrapWaypoint
 */

params [
    "_groupData",
    "_targetPos",
    "_wpType",
    "_wpBehavior",
    "_wpSpeed",
    "_wpFormation",
    "_wpMode",
    "_wpCompletionRadius"
];

private _realGroup = _groupData get "realGroup";
if (isNull _realGroup) exitWith { false };

[_realGroup] call CBA_fnc_clearWaypoints;
_realGroup setSpeedMode _wpSpeed;
private _wp = _realGroup addWaypoint [_targetPos, 0];
_wp setWaypointType _wpType;
_wp setWaypointBehaviour _wpBehavior;
_wp setWaypointSpeed _wpSpeed;
_wp setWaypointFormation _wpFormation;
_wp setWaypointCombatMode _wpMode;
_wp setWaypointCompletionRadius _wpCompletionRadius;

true
