/*
 * Function: FLO_fnc_virtualizationProcessGroup
 * Author: Frontline Operations Development Group
 * Description:
 *   Processes a single virtual group - handles activation, deactivation,
 *   virtual movement, and state management. Called by the main PFH loop.
 *
 * Arguments:
 * 0: Group ID <STRING>
 * 1: Group Data <HASHMAP>
 * 2: Activation Distance <NUMBER>
 * 3: Current Time <NUMBER>
 * 4: Unused legacy argument retained at call sites during refactor <ANY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_groupId, _groupData, 2000, diag_tickTime, nil] call FLO_fnc_virtualizationProcessGroup;
 */

params ["_groupId", "_groupData", "_activationDist", "_now"];

private _virtStats = FLO_VirtUpdate get "stats";

private _isActive = _groupData get "isActive";
private _groupType = _groupData get "groupType";
private _realGroup = _groupData get "realGroup";
private _tracksAssets = [_groupType] call FLO_fnc_virtualizationUsesAssetStrength;
private _missionLock = _groupData get "missionLock";
private _inCombat = _groupData get "inCombat";
private _engagementActive = _groupData get "engagementActive";
private _forceVirtual = _groupData get "forceVirtual";
private _replacementState = _groupData get "replacementState";
private _activationDeferred = _groupData get "activationDeferred";
private _unitCount = _groupData get "unitCount";
private _position = _groupData get "position";

if (!_isActive && {_unitCount <= 0}) exitWith {
    ["VIRTUALIZATION", 2, format [
        "Removing stale inactive zero-strength group %1 (%2)",
        _groupId,
        _groupType
    ]] call FLO_fnc_log;
    [FLO_virtualGroups, _groupId] call FLO_fnc_virtualizationRemoveGroup;
};

if !([_position] call FLO_fnc_validateGroupPosition) exitWith {
    if (_isActive && {!isNull _realGroup}) then {
        ["VIRTUALIZATION", 1, format [
            "Active group %1 (%2) had invalid virtual position %3 - attempting real-group resync",
            _groupId,
            _groupType,
            _position
        ]] call FLO_fnc_log;
        [_groupId, _groupData, _realGroup] call FLO_fnc_virtualizationCaptureRealGroupPosition;
    } else {
        ["VIRTUALIZATION", 1, format [
            "Removing group %1 (%2) with invalid virtual position %3",
            _groupId,
            _groupType,
            _position
        ]] call FLO_fnc_log;
        [FLO_virtualGroups, _groupId] call FLO_fnc_virtualizationRemoveGroup;
    };
};

private _tierResult = [_groupData] call FLO_fnc_virtualizationApplyTieredUpdateWindow;
_tierResult params ["_shouldProcess", "_nearestDist"];
if (!_shouldProcess) exitWith {};

if ([_groupId, _groupData, _virtStats] call FLO_fnc_virtualizationProcessAttachedGroup) exitWith {};

if (_isActive && {isNull _realGroup}) exitWith {
    [_groupId, _groupData] call FLO_fnc_virtualizationRepairOrphanedActiveGroup;
};

if (!_isActive && {!_activationDeferred}) then {
    if (!_inCombat && {!_engagementActive}) then {
        [_groupId, _groupData, _now, _virtStats] call FLO_fnc_virtualizationProcessInactiveMovement;
    } else {
        if ((_groupData get "waypoints") isNotEqualTo []) then {
            _virtStats set ["movementPauseSkipsTotal", (_virtStats get "movementPauseSkipsTotal") + 1];
            _virtStats set ["movementPauseSkipsThisBatch", (_virtStats get "movementPauseSkipsThisBatch") + 1];
        };
    };
};

[_groupId, _groupData, _activationDist, _nearestDist, _forceVirtual, _missionLock, _replacementState, _inCombat, _virtStats] call FLO_fnc_virtualizationProcessActivationState;

_isActive = _groupData get "isActive";
_realGroup = _groupData get "realGroup";

if (_isActive && {!isNull _realGroup}) then {
    [_groupId, _groupData, _realGroup, _tracksAssets, _replacementState, _nearestDist, _now, _virtStats] call FLO_fnc_virtualizationProcessActiveState;
};

