/*
 * Function: FLO_fnc_virtualizationDeactivateMountedPassengerGroup
 * Author: Frontline Operations Development Group
 * Description:
 *   Virtualizes a mounted passenger group without deleting the carrier vehicle.
 *   This is used when a transport virtualizes and its attached passenger groups
 *   are still active in the live world.
 *
 * Arguments:
 * 0: Group ID <STRING>
 * 1: Group Data <HASHMAP>
 * 2: Carrier Group ID <STRING> - Optional, for logging only
 *
 * Return Value:
 * BOOL - True when the passenger group state was cleared
 */

params [
    ["_groupId", "", [""]],
    ["_groupData", createHashMap, [createHashMap]],
    ["_carrierGroupId", "", [""]]
];

if (_groupId == "") exitWith { false };

private _realGroup = _groupData get "realGroup";
private _wasActive = _groupData get "isActive";
private _hadRealGroup = !isNull _realGroup;
if (!isNull _realGroup) then {
    [_groupId, _groupData, _realGroup] call FLO_fnc_virtualizationCaptureRealGroupPosition;
    [_groupId, _groupData, _realGroup] call FLO_fnc_virtualizationCaptureRealGroupWaypoints;
    [_groupData, _realGroup] call FLO_fnc_virtualizationCaptureRealGroupRuntimeState;
    [_groupId, _groupData, _realGroup] call FLO_fnc_virtualizationSyncRealGroupOutcome;

    {
        _x hideObjectGlobal true;
        deleteVehicle _x;
    } forEach units _realGroup;

    deleteGroup _realGroup;
};

[_groupData] call FLO_fnc_virtualizationClearRealGroup;
[_groupData] call FLO_fnc_virtualizationClearRealVehicles;
[_groupData] call FLO_fnc_virtualizationClearMountedIn;
_groupData set ["isActive", false];
_groupData set ["lastStateChangeTime", diag_tickTime];

if (_wasActive || {_hadRealGroup}) then {
    ["FLO_Virtualization_GroupDeactivated", [_groupId, _groupData]] call CBA_fnc_localEvent;
};
["VIRTUALIZATION", 3, format [
    "Virtualized mounted passenger group %1 from carrier %2",
    _groupId,
    _carrierGroupId
]] call FLO_fnc_log;

true
