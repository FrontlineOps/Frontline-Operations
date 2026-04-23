/*
 * Function: FLO_fnc_virtualizationRepairOrphanedActiveGroup
 * Author: Frontline Operations Development Group
 * Description:
 *   Repairs an impossible active-group state where virtualization still marks
 *   the group active but its canonical live-engine group handle is gone.
 *   Asset-tracked groups can be virtualized back from surviving vehicle
 *   references; non-recoverable groups are removed so ghost strength does not
 *   persist.
 *
 * Arguments:
 *   0: Group ID <STRING>
 *   1: Group data <HASHMAP>
 *
 * Return Value:
 *   BOOL - True when the broken state was handled
 */

params ["_groupId", "_groupData"];

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

if (_recoverableCount <= 0) exitWith {
    if (_attachedPassengerCount > 0) then {
        [_groupId, _groupData] call FLO_fnc_virtualizationDeactivateMountedPassengers;
    };

    ["VIRTUALIZATION", 2, format [
        "Removing orphaned active group %1 (%2) because no recoverable live assets remain",
        _groupId,
        _groupType
    ]] call FLO_fnc_log;
    [FLO_virtualGroups, _groupId] call FLO_fnc_virtualizationRemoveGroup;
    true
};

private _recoverableComp = _recoverableAssets apply { typeOf _x };
if (_attachedPassengerCount > 0) then {
    [_groupId, _groupData] call FLO_fnc_virtualizationDeactivateMountedPassengers;
};
_groupData set ["unitCount", _recoverableCount];
[_groupData, _recoverableComp] call FLO_fnc_virtualizationSetAssetComposition;
[_groupData, grpNull, false] call FLO_fnc_virtualizationDeleteRealGroupAssets;
[_groupData] call FLO_fnc_virtualizationClearRealGroup;
[_groupData] call FLO_fnc_virtualizationClearRealVehicles;
_groupData set ["isActive", false];
_groupData set ["lastStateChangeTime", diag_tickTime];

private _activationDistance = FLO_virtualGroups get "_activationDistance";
private _cachedPlayers = FLO_VirtUpdate get "cachedPlayerPositions";
private _orphanPos = +(_groupData get "position");
private _nearestPlayerDist = 1e10;
{
    _x params ["_playerPos", "_inAir"];
    if (!_inAir) then {
        private _dist = _orphanPos distance2D _playerPos;
        if (_dist < _nearestPlayerDist) then {
            _nearestPlayerDist = _dist;
        };
    };
} forEach _cachedPlayers;

if (_nearestPlayerDist <= _activationDistance) then {
    private _deferredPos = [_orphanPos, _activationDistance] call FLO_fnc_virtualizationComputeDeferredActivationPos;
    [FLO_virtualGroups, _groupId, _deferredPos] call FLO_fnc_virtualizationUpdateGroupPosition;
    _groupData set ["activationDeferred", true];
    _groupData set ["activationDeferredAt", diag_tickTime];
    _groupData set ["activationDeferredPos", _deferredPos];

    ["VIRTUALIZATION", 2, format [
        "Deferred orphan repair reactivation for %1 (%2) originalPos=%3 deferredPos=%4 nearestPlayer=%5m activationDistance=%6m",
        _groupId,
        _groupType,
        _orphanPos,
        _deferredPos,
        (round (_nearestPlayerDist * 10)) / 10,
        _activationDistance
    ]] call FLO_fnc_log;
};

if ([_groupData] call FLO_fnc_gtnCombatAffectsClassification) then {
    [true] call FLO_fnc_gtnCombatMarkClassificationDirty;
};

["FLO_Virtualization_GroupDeactivated", [_groupId, _groupData]] call CBA_fnc_localEvent;

["VIRTUALIZATION", 2, format [
    "Virtualized orphaned active group %1 (%2) with %3 recoverable live assets",
    _groupId,
    _groupType,
    _recoverableCount
]] call FLO_fnc_log;

true
