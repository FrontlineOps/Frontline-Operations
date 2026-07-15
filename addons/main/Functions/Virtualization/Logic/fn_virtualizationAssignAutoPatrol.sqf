/*
 * Function: FLO_fnc_virtualizationAssignAutoPatrol
 * Author: Frontline Operations Development Group
 * Description:
 *   Assigns persistent auto-patrol data to an eligible virtual group.
 */

params [
    "_groupId",
    ["_centerOverride", [], [[]]]
];

private _groupData = [_groupId] call FLO_fnc_virtualizationRequireGroup;

if (!([_groupData] call FLO_fnc_virtualizationCanAutoPatrol)) exitWith { false };
if ((_groupData get "state") != "idle") exitWith { false };
if (_groupData get "autoPatrol") exitWith { false };
if ((_groupData get "patrolConfig") isNotEqualTo []) exitWith { false };
if ((_groupData get "waypoints") isNotEqualTo []) exitWith { false };
if (
    (_groupData get "landRouteStartBlocked")
    && {diag_tickTime < (_groupData get "landRouteRetryAt")}
) exitWith { false };

private _patrolPlan = [_groupData, _centerOverride] call FLO_fnc_virtualizationBuildPatrolPlan;
if (_patrolPlan isEqualTo []) exitWith { false };

_patrolPlan params ["_patrolWaypoints", "_patrolConfig"];

if !([_groupId, _patrolWaypoints, true, "AUTO_PATROL", true, _patrolConfig] call FLO_fnc_updateVirtualGroupWaypoints) exitWith {
    false
};

["VIRTUALIZATION", 5, format ["Assigned persistent auto-patrol to %1 (%2 waypoints)", _groupId, count _patrolWaypoints]] call FLO_fnc_log;

true
