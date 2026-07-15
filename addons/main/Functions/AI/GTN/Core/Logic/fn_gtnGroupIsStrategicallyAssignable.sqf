/*
 * Function: FLO_fnc_gtnGroupIsStrategicallyAssignable
 * Author: Frontline Operations Development Group
 *
 * Description:
 *   Returns whether a virtual group is eligible for normal GTN strategic tasking.
 *   This excludes dedicated transports, logistics replacements, mission-locked
 *   groups, and passengers/carriers that are already in a transport relationship.
 *
 * Arguments:
 *   0: Group data <HASHMAP>
 *   1: Own side <SIDE>
 *   2: Allowed group types <ARRAY> - Optional
 *   3: Allowed current orders <ARRAY> - Optional. Empty skips order filtering.
 *   4: Allowed campaign reservation owner <STRING> - Optional
 *   5: Rejection counters <HASHMAP> - Optional
 *
 * Return Value:
 *   BOOL
 */

params [
    ["_groupData", nil],
    ["_ownSide", east, [east]],
    ["_allowedGroupTypes", [], [[]]],
    ["_allowedOrders", [], [[]]],
    ["_reservationOwnerId", "", [""]],
    ["_rejectionCounts", createHashMap, [createHashMap]]
];

private _reject = {
    params ["_reason"];
    private _count = if (_reason in _rejectionCounts) then { _rejectionCounts get _reason } else { 0 };
    _rejectionCounts set [_reason, _count + 1];
    false
};

if (isNil "_groupData") exitWith { ["MISSING_GROUP"] call _reject };
if ((_groupData get "side") != _ownSide) exitWith { ["WRONG_SIDE"] call _reject };

private _groupType = _groupData get "groupType";
if (_allowedGroupTypes isNotEqualTo [] && {!(_groupType in _allowedGroupTypes)}) exitWith {
    ["WRONG_TYPE"] call _reject
};

if (_groupData get "transportRole") exitWith { ["TRANSPORT_ROLE"] call _reject };
if (_groupData get "inCombat") exitWith { ["IN_COMBAT"] call _reject };
if ((_groupData get "missionLock") != "") exitWith { ["MISSION_LOCK"] call _reject };
if ((_groupData get "replacementState") != "") exitWith { ["REPLACEMENT"] call _reject };
if ((_groupData get "attachedTo") != "" || {(_groupData get "mountedIn") != ""}) exitWith {
    ["TRANSPORT_BOUND"] call _reject
};

private _reservationId = _groupData get "campaignOperationId";
if (_reservationId != "" && {_reservationId != _reservationOwnerId}) exitWith {
    ["CAMPAIGN_RESERVED"] call _reject
};

private _currentOrder = _groupData get "commanderOrder";
if (_allowedOrders isNotEqualTo [] && {_currentOrder != ""} && {!(_currentOrder in _allowedOrders)}) exitWith {
    ["CURRENT_ORDER"] call _reject
};

true
