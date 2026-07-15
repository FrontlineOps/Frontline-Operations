/*
 * Function: FLO_fnc_virtualizationCommitCommanderOrder
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies one GTN commander order through the canonical virtualization order
 *   pipeline: route update, commander-order state, then optional reassignment
 *   transport request. This keeps order application consistent while leaving
 *   commander doctrine and target selection outside virtualization.
 *
 * Arguments:
 *   0: Group ID <STRING>
 *   1: Group data <HASHMAP>
 *   2: Order type <STRING> - MOVE, ATTACK, DEFEND, or GARRISON
 *   3: Waypoints <ARRAY>
 *   4: Target position <ARRAY>
 *   5: Route source tag <STRING>
 *   6: Objective ID <STRING>
 *   7: Order mode <STRING> - MOVE only
 *   8: Defend lease issued at <NUMBER>
 *   9: Defend lease until <NUMBER>
 *   10: Campaign operation ID <STRING> - ATTACK only
 *
 * Return Value:
 *   ARRAY - [success, routeMs, assignMs, transportMs, orderMs]
 */

params [
    ["_groupId", "", [""]],
    ["_groupData", createHashMap, [createHashMap]],
    ["_orderType", "", [""]],
    ["_waypoints", [], [[]]],
    ["_targetPos", [], [[]]],
    ["_routeSource", "", [""]],
    ["_objectiveId", "", [""]],
    ["_orderMode", "", [""]],
    ["_leaseIssuedAt", -1, [0]],
    ["_leaseUntil", -1, [0]],
    ["_campaignOperationId", "", [""]]
];

if (_groupId == "") then {
    throw "FLO_fnc_virtualizationCommitCommanderOrder: empty group id";
};

if (!(_targetPos isEqualType []) || {count _targetPos < 2}) then {
    throw format [
        "FLO_fnc_virtualizationCommitCommanderOrder: invalid target position for %1: %2",
        _groupId,
        _targetPos
    ];
};

private _order = toUpper _orderType;
if (_order == "ATTACK" && {_objectiveId == "" || {_campaignOperationId == ""}}) then {
    throw format [
        "FLO_fnc_virtualizationCommitCommanderOrder: ATTACK requires objective and campaign operation (%1, %2)",
        _objectiveId,
        _campaignOperationId
    ];
};
private _orderStart = diag_tickTime;

private _tRoute = diag_tickTime;
private _routeCommitted = [_groupId, _waypoints, true, _routeSource] call FLO_fnc_updateVirtualGroupWaypoints;
private _routeMs = (diag_tickTime - _tRoute) * 1000;

if (!_routeCommitted) exitWith {
    [false, _routeMs, 0, 0, (diag_tickTime - _orderStart) * 1000]
};

private _tAssign = diag_tickTime;
switch (_order) do {
    case "MOVE": {
        [_groupData, _targetPos, _orderMode] call FLO_fnc_virtualizationAssignMoveOrder;
    };
    case "ATTACK": {
        [_groupData, _targetPos, _objectiveId, _campaignOperationId] call FLO_fnc_virtualizationAssignAttackOrder;
    };
    case "DEFEND": {
        [_groupData, _targetPos, _objectiveId, _leaseIssuedAt, _leaseUntil] call FLO_fnc_virtualizationAssignDefendOrder;
    };
    case "GARRISON": {
        [_groupData, _targetPos, _objectiveId] call FLO_fnc_virtualizationAssignGarrisonOrder;
    };
    default {
        throw format [
            "FLO_fnc_virtualizationCommitCommanderOrder: unsupported order type %1 for %2",
            _orderType,
            _groupId
        ];
    };
};
private _assignMs = (diag_tickTime - _tAssign) * 1000;

private _tTransport = diag_tickTime;
[_groupId, _groupData, _targetPos, _order] call FLO_fnc_transportMaybeRequestReassignmentPickup;
private _transportMs = (diag_tickTime - _tTransport) * 1000;

private _orderMs = (diag_tickTime - _orderStart) * 1000;

[true, _routeMs, _assignMs, _transportMs, _orderMs]
