/*
 * Function: FLO_fnc_transportApplyPostDismountWaypoint
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies the deferred post-dismount waypoint for a passenger group and
 *   clears the stored post-dismount state.
 *
 * Arguments:
 *   0: Infantry Group ID <STRING>
 *   1: Source Tag <STRING>
 *
 * Return Value:
 *   BOOL - True when a post-dismount waypoint was applied
 */

params [
    ["_infantryGroupId", "", [""]],
    ["_sourceTag", "TRANSPORT_DISMOUNT", [""]]
];

if (_infantryGroupId == "") exitWith { false };

private _infData = [_infantryGroupId] call FLO_fnc_transportGetTrackedGroup;
private _postWp = _infData get "postDismountWaypoint";
if (_postWp isEqualTo []) exitWith { false };

_postWp params [
    ["_targetPos", [0, 0, 0], [[]]],
    ["_orderType", "ORGANIC_PACKAGE", [""]]
];

private _waypoints = [
    [_targetPos, "MOVE", "COMBAT", "NORMAL", "WEDGE", "RED", 50]
];
if !([_infantryGroupId, _waypoints, true, _sourceTag] call FLO_fnc_updateVirtualGroupWaypoints) exitWith {
    ["TRANSPORT", 2, format ["Retained post-dismount task for %1 because no land route was available", _infantryGroupId]] call FLO_fnc_log;
    false
};
private _changes = createHashMapFromArray [["postDismountWaypoint", []]];
if ((_infData get "missionLock") == "TRANSPORT") then {
    _changes set ["missionLock", ""];
    _changes set ["missionType", ""];
};
[_infantryGroupId, _changes] call FLO_fnc_virtualizationPatchGroup;

["TRANSPORT", 3, format [
    "Set post-dismount %1 waypoint for %2",
    _orderType,
    _infantryGroupId
]] call FLO_fnc_log;

true
