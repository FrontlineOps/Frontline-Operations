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
 *
 * Return Value:
 *   BOOL
 */

params [
    ["_groupData", nil],
    ["_ownSide", east, [east]],
    ["_allowedGroupTypes", [], [[]]],
    ["_allowedOrders", [], [[]]]
];

if (isNil "_groupData") exitWith { false };
if ((_groupData get "side") != _ownSide) exitWith { false };

private _groupType = _groupData get "groupType";
if (count _allowedGroupTypes > 0 && {!(_groupType in _allowedGroupTypes)}) exitWith {
    false
};

if (_groupData get "transportRole") exitWith { false };
if (_groupData get "inCombat") exitWith { false };
if ((_groupData get "missionLock") != "") exitWith { false };
if ((_groupData get "replacementState") != "") exitWith { false };
if ((_groupData get "attachedTo") != "" || {(_groupData get "mountedIn") != ""}) exitWith {
    false
};

private _currentOrder = _groupData get "commanderOrder";
if (count _allowedOrders > 0 && {_currentOrder != ""} && {!(_currentOrder in _allowedOrders)}) exitWith {
    false
};

true
