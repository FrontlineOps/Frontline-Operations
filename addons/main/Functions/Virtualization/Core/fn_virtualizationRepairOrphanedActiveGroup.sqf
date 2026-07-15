/*
 * Function: FLO_fnc_virtualizationRepairOrphanedActiveGroup
 * Author: Frontline Operations Development Group
 * Description:
 *   Repairs an impossible active-group state where virtualization still marks
 *   the group active but its canonical live-engine group handle is gone.
 *   A surviving operational crew can restore the canonical group handle.
 *   Crewless assets remain abandoned in the physical world while their ghost
 *   virtual combat strength is removed.
 *
 * Arguments:
 *   0: Group ID <STRING>
 * Return Value:
 *   BOOL - True when the broken state was handled
 */

params [["_groupId", "", [""]]];

private _groupData = [_groupId] call FLO_fnc_virtualizationRequireGroup;

if !(_groupData get "isActive") exitWith { false };
private _realGroup = _groupData get "realGroup";
if (!isNull _realGroup) exitWith { false };

private _groupType = _groupData get "groupType";
private _tracksAssets = [_groupType] call FLO_fnc_virtualizationUsesAssetStrength;
private _recoverableAssets = if (_tracksAssets) then {
    [_groupData, grpNull] call FLO_fnc_virtualizationGetRealAssetVehicles
} else {
    []
};
private _recoverableCount = count _recoverableAssets;
private _replacementRealGroup = grpNull;
{
    private _asset = _x;
    {
        private _role = assignedVehicleRole _x;
        private _candidateGroup = group _x;
        if (
            alive _x
            && {!isPlayer _x}
            && {_role isNotEqualTo []}
            && {toLower (_role select 0) != "cargo"}
            && {!isNull _candidateGroup}
            && {(_candidateGroup getVariable ["FLO_virtualGroupId", ""]) == _groupId}
        ) exitWith {
            _replacementRealGroup = _candidateGroup;
        };
    } forEach (crew _asset);
    if (!isNull _replacementRealGroup) exitWith {};
} forEach _recoverableAssets;
private _attachedTo = [_groupData] call FLO_fnc_virtualizationGetTransportAttachment;
private _mountedIn = [_groupData] call FLO_fnc_virtualizationGetMountedTransport;
private _attachedPassengerCount = count ([_groupData] call FLO_fnc_virtualizationGetTransportPassengers);
private _trackedRealVehicles = count (_groupData get "realVehicles");

["VIRTUALIZATION", 2, format [
    "Active group %1 (%2) lost its realGroup handle while still marked active (missionLock=%3 replacementState=%4 recoverableAssets=%5 attachedTo=%6 mountedIn=%7 transportRole=%8 attachedGroups=%9 trackedVehicles=%10 objective=%11 pos=%12) - repairing",
    _groupId,
    _groupType,
    _groupData get "missionLock",
    _groupData get "replacementState",
    _recoverableCount,
    _attachedTo,
    _mountedIn,
    _groupData get "transportRole",
    _attachedPassengerCount,
    _trackedRealVehicles,
    _groupData get "objective",
    _groupData get "position"
]] call FLO_fnc_log;

if (!isNull _replacementRealGroup) exitWith {
    [_groupData, _replacementRealGroup] call FLO_fnc_virtualizationSetRealGroup;
    [_groupData, _recoverableAssets] call FLO_fnc_virtualizationSetRealVehicles;
    _replacementRealGroup setVariable ["FLO_virtualGroupId", _groupId];
    [_groupData, _groupId] call FLO_fnc_virtualizationValidateGroup;
    call FLO_fnc_virtualizationTouchRegistry;

    ["VIRTUALIZATION", 3, format [
        "Recovered active group %1 (%2) from surviving operational crew and %3 tracked assets",
        _groupId,
        _groupType,
        _recoverableCount
    ]] call FLO_fnc_log;
    true
};

private _retirementCandidate = [_groupData] call FLO_fnc_virtualizationCloneValue;
[_retirementCandidate] call FLO_fnc_virtualizationClearRealGroup;
[_retirementCandidate] call FLO_fnc_virtualizationClearRealVehicles;
_retirementCandidate set ["isActive", false];
_retirementCandidate set ["unitCount", 0];
_retirementCandidate set ["comp", []];
_retirementCandidate set ["lastStateChangeTime", diag_tickTime];
_retirementCandidate set ["nextProcessAt", 0];

// The doomed carrier must end transport execution before ordinary removal
// validates and detaches its surviving passenger relationships.
_retirementCandidate set ["dismountAtWaypoint", -1];
_retirementCandidate set ["transportInsertMode", ""];
_retirementCandidate set ["transportInsertPos", []];
_retirementCandidate set ["transportLandCommandIssued", false];
_retirementCandidate set ["transportUnloadCommandIssued", false];
_retirementCandidate set ["transportUnloadIssuedAt", -1];
if ((_retirementCandidate get "executionState") == "TRANSPORT") then {
    _retirementCandidate set ["executionState", ""];
};
if ((_retirementCandidate get "missionLock") == "TRANSPORT") then {
    _retirementCandidate set ["missionLock", ""];
    _retirementCandidate set ["missionType", ""];
};

[_retirementCandidate, _groupId] call FLO_fnc_virtualizationValidateGroup;
{
    _groupData set [_x, _retirementCandidate get _x];
} forEach [
    "realGroup",
    "activeInitialUnitCount",
    "realVehicles",
    "isActive",
    "unitCount",
    "comp",
    "lastStateChangeTime",
    "nextProcessAt",
    "dismountAtWaypoint",
    "transportInsertMode",
    "transportInsertPos",
    "transportLandCommandIssued",
    "transportUnloadCommandIssued",
    "transportUnloadIssuedAt",
    "executionState",
    "missionLock",
    "missionType"
];
call FLO_fnc_virtualizationTouchRegistry;

if (_attachedPassengerCount > 0) then {
    [_groupId, _groupData] call FLO_fnc_virtualizationDeactivateMountedPassengers;
};

if !([_groupId] call FLO_fnc_virtualizationRemoveGroup) then {
    private _message = format [
        "Failed to remove coherently retired orphan group %1 (%2)",
        _groupId,
        _groupType
    ];
    ["VIRTUALIZATION", 1, _message] call FLO_fnc_log;
    throw _message;
};

["VIRTUALIZATION", 3, format [
    "Removed orphaned active group %1 (%2) after operational crew loss; abandonedAssets=%3 passengerGroups=%4",
    _groupId,
    _groupType,
    _recoverableCount,
    _attachedPassengerCount
]] call FLO_fnc_log;

true
