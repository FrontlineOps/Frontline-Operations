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

if !(_groupData isEqualType createHashMap) exitWith {
    ["VIRTUALIZATION", 1, format [
        "Invalid deactivateVirtualGroup call for %1 - missing group data",
        _groupId
    ]] call FLO_fnc_log;
    false
};

["VIRTUALIZATION", 3, format["Deactivating virtual group %1", _groupId]] call FLO_fnc_log;

private _realGroup = _groupData get "realGroup";
if (isNull _realGroup) exitWith {
    [_groupId, _groupData] call FLO_fnc_virtualizationRepairOrphanedActiveGroup
};

private _realUnitCount = count units _realGroup;
if (_realUnitCount <= 0) then {
    ["VIRTUALIZATION", 2, format [
        "Deactivating active group %1 (%2) with an empty realGroup (missionLock=%3 replacementState=%4 transportRole=%5 attachedTo=%6 mountedIn=%7 attachedGroups=%8 trackedVehicles=%9 objective=%10 pos=%11)",
        _groupId,
        _groupData get "groupType",
        _groupData get "missionLock",
        _groupData get "replacementState",
        _groupData get "transportRole",
        [_groupData] call FLO_fnc_virtualizationGetTransportAttachment,
        [_groupData] call FLO_fnc_virtualizationGetMountedTransport,
        count ([_groupData] call FLO_fnc_virtualizationGetTransportPassengers),
        count (_groupData get "realVehicles"),
        _groupData get "objective",
        _groupData get "position"
    ]] call FLO_fnc_log;
};

[_groupId, _groupData, _realGroup] call FLO_fnc_virtualizationCaptureRealGroupPosition;
[_groupId, _groupData, _realGroup] call FLO_fnc_virtualizationCaptureRealGroupWaypoints;
[_groupData, _realGroup] call FLO_fnc_virtualizationCaptureRealGroupRuntimeState;

private _syncResult = [_groupId, _groupData, _realGroup] call FLO_fnc_virtualizationSyncRealGroupOutcome;
_syncResult params ["_tracksAssets", "_syncedCount"];

[_groupId, _groupData] call FLO_fnc_virtualizationDeactivateMountedPassengers;
[_groupData, _realGroup] call FLO_fnc_virtualizationDeleteRealGroupAssets;
private _groupType = _groupData get "groupType";

if (_syncedCount <= 0) exitWith {
    ["VIRTUALIZATION", 3, format["Deactivated group %1 lost all remaining %2 strength - removing", _groupId, _groupType]] call FLO_fnc_log;
    [FLO_virtualGroups, _groupId] call FLO_fnc_virtualizationRemoveGroup;
    true
};

// Update virtualization state
[_groupData] call FLO_fnc_virtualizationClearRealGroup;
[_groupData] call FLO_fnc_virtualizationClearRealVehicles;
_groupData set ["isActive", false];
_groupData set ["lastStateChangeTime", diag_tickTime];

["FLO_Virtualization_GroupDeactivated", [_groupId, _groupData]] call CBA_fnc_localEvent;
["VIRTUALIZATION", 3, format["Deactivated virtual group: %1", _groupId]] call FLO_fnc_log;

true
