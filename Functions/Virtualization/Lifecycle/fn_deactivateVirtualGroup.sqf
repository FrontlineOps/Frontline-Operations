/*
 * Function: FLO_fnc_deactivateVirtualGroup
 * Author: Frontline Operations Development Group
 * Description:
 * Deactivates a virtual group by removing it from the game world but keeping its virtual status.
 *
 * Arguments:
 * 0: Group ID <STRING> - Unique identifier for the virtual group
 * 1: Group Data <HASHMAP> - HashMap containing group data
 *
 * Return Value:
 * Success <BOOLEAN>
 *
 * Example:
 * ["vgroup_1", _groupData] call FLO_fnc_deactivateVirtualGroup;
 */

params ["_groupId", "_groupData"];
["VIRTUALIZATION", 3, format["Deactivating virtual group %1", _groupId]] call FLO_fnc_log;

private _realGroup = _groupData get "realGroup";
if (isNull _realGroup) exitWith {
    ["VIRTUALIZATION", 2, format["Attempted to deactivate virtual group %1 but no real group exists", _groupId]] call FLO_fnc_log;
    false
};

[_groupId, _groupData, _realGroup] call FLO_fnc_virtualizationCaptureRealGroupPosition;
[_groupId, _groupData, _realGroup] call FLO_fnc_virtualizationCaptureRealGroupWaypoints;
[_groupData, _realGroup] call FLO_fnc_virtualizationCaptureRealGroupRuntimeState;

private _syncResult = [_groupId, _groupData, _realGroup] call FLO_fnc_virtualizationSyncRealGroupOutcome;
_syncResult params ["_tracksAssets", "_syncedCount"];

[_realGroup] call FLO_fnc_virtualizationDeleteRealGroupAssets;
private _groupType = _groupData get "groupType";

if (_tracksAssets && {_syncedCount <= 0}) exitWith {
    ["VIRTUALIZATION", 3, format["Deactivated vehicle-backed group %1 lost all %2 assets - removing", _groupId, _groupType]] call FLO_fnc_log;
    [FLO_virtualGroups, _groupId] call FLO_fnc_virtualizationRemoveGroup;
    true
};

// Update virtualization state
[_groupData] call FLO_fnc_virtualizationClearRealGroup;
_groupData set ["isActive", false];
_groupData set ["lastStateChangeTime", diag_tickTime];

["FLO_Virtualization_GroupDeactivated", [_groupId, _groupData]] call CBA_fnc_localEvent;
["VIRTUALIZATION", 3, format["Deactivated virtual group: %1", _groupId]] call FLO_fnc_log;

true
