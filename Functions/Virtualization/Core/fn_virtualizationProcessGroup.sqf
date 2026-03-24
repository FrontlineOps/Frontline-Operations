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
 * 4: Group Update Times HashMap <HASHMAP> - For tiered updates
 *
 * Return Value:
 * None
 *
 * Example:
 * [_groupId, _groupData, 2000, diag_tickTime, _updateTimes] call FLO_fnc_virtualizationProcessGroup;
 */

params ["_groupId", "_groupData", "_activationDist", "_now", "_groupUpdateTimes"];

private _virtStats = FLO_VirtUpdate get "stats";

private _isActive = _groupData get "isActive";
private _groupType = _groupData get "groupType";
private _realGroup = _groupData get "realGroup";
private _tracksAssets = [_groupType] call FLO_fnc_virtualizationUsesAssetStrength;
private _missionLock = _groupData get "missionLock";
private _inCombat = _groupData get "inCombat";
private _forceVirtual = _groupData get "forceVirtual";
private _replacementState = _groupData get "replacementState";

private _tierResult = [_groupId, _groupData, _activationDist, _now, _groupUpdateTimes, _virtStats] call FLO_fnc_virtualizationApplyTieredUpdateWindow;
_tierResult params ["_shouldProcess", "_nearestDist"];
if (!_shouldProcess) exitWith {};

if ([_groupId, _groupData, _virtStats] call FLO_fnc_virtualizationProcessAttachedGroup) exitWith {};

if (!_isActive && {!_inCombat}) then {
    [_groupId, _groupData, _now, _virtStats] call FLO_fnc_virtualizationProcessInactiveMovement;
};

[_groupId, _groupData, _activationDist, _nearestDist, _forceVirtual, _missionLock, _replacementState, _virtStats] call FLO_fnc_virtualizationProcessActivationState;

_isActive = _groupData get "isActive";
_realGroup = _groupData get "realGroup";

if (_isActive && {!isNull _realGroup}) then {
    [_groupId, _groupData, _realGroup, _tracksAssets, _replacementState, _now, _virtStats] call FLO_fnc_virtualizationProcessActiveState;
};

