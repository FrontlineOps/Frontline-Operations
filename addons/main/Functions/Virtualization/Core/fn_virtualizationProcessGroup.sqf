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
 * 4: Profile Phases <BOOLEAN> (optional, default false)
 * Return Value:
 * None
 *
 * Example:
 * [_groupId, _groupData, 2000, diag_tickTime, false] call FLO_fnc_virtualizationProcessGroup;
 */

params [
    "_groupId",
    "_groupData",
    "_activationDist",
    "_now",
    ["_profilePhases", false, [false]]
];

private _virtStats = FLO_VirtUpdate get "stats";

if (_now < (_groupData get "nextProcessAt")) exitWith {
    _virtStats set ["scheduledSkipsTotal", (_virtStats get "scheduledSkipsTotal") + 1];
    _virtStats set ["scheduledSkipsThisBatch", (_virtStats get "scheduledSkipsThisBatch") + 1];
};

private _isActive = _groupData get "isActive";
private _groupType = _groupData get "groupType";
private _realGroup = _groupData get "realGroup";
private _tracksAssets = [_groupType] call FLO_fnc_virtualizationUsesAssetStrength;
private _missionLock = _groupData get "missionLock";
private _inCombat = _groupData get "inCombat";
private _forceVirtual = _groupData get "forceVirtual";
private _replacementState = _groupData get "replacementState";
private _activationDeferred = _groupData get "activationDeferred";
private _unitCount = _groupData get "unitCount";
private _position = _groupData get "position";
private _groupActivationDist = _activationDist;
if (_groupType in ["helicopter", "air", "jet"]) then {
    _groupActivationDist = _activationDist * FLO_AirActivationDistanceMultiplier;
};

if (!_isActive && {_unitCount <= 0}) exitWith {
    ["VIRTUALIZATION", 2, format [
        "Removing stale inactive zero-strength group %1 (%2)",
        _groupId,
        _groupType
    ]] call FLO_fnc_log;
    [_groupId] call FLO_fnc_virtualizationRemoveGroup;
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
        [_groupId] call FLO_fnc_virtualizationRemoveGroup;
    };
};

private _phaseStart = 0;
if (_profilePhases) then { _phaseStart = diag_tickTime; };
private _nearestDist = [_position] call FLO_fnc_virtualizationGetNearestCachedPlayerDistance;
if (_profilePhases) then {
    _virtStats set ["phaseProximityMsTotal", (_virtStats get "phaseProximityMsTotal") + ((diag_tickTime - _phaseStart) * 1000)];
    _phaseStart = diag_tickTime;
};
[_groupData, _nearestDist, _groupActivationDist, _now] call FLO_fnc_virtualizationScheduleNextProcess;
if (_profilePhases) then {
    _virtStats set ["phaseScheduleMsTotal", (_virtStats get "phaseScheduleMsTotal") + ((diag_tickTime - _phaseStart) * 1000)];
    _phaseStart = diag_tickTime;
};

private _attachedHandled = [_groupId, _groupData, _virtStats] call FLO_fnc_virtualizationProcessAttachedGroup;
if (_profilePhases) then {
    _virtStats set ["phaseAttachedMsTotal", (_virtStats get "phaseAttachedMsTotal") + ((diag_tickTime - _phaseStart) * 1000)];
    if (_attachedHandled) then {
        _virtStats set ["phaseAttachedHandledTotal", (_virtStats get "phaseAttachedHandledTotal") + 1];
    };
};
if (_attachedHandled) exitWith {};

if (_isActive && {isNull _realGroup}) exitWith {
    [_groupId] call FLO_fnc_virtualizationRepairOrphanedActiveGroup;
};

if (!_isActive && {!_activationDeferred}) then {
    if (!_inCombat) then {
        if (_profilePhases) then {
            _phaseStart = diag_tickTime;
            _virtStats set ["phaseMovementCallsTotal", (_virtStats get "phaseMovementCallsTotal") + 1];
        };
        [_groupId, _groupData, _now, _virtStats, _profilePhases] call FLO_fnc_virtualizationProcessInactiveMovement;
        if (_profilePhases) then {
            _virtStats set ["phaseMovementMsTotal", (_virtStats get "phaseMovementMsTotal") + ((diag_tickTime - _phaseStart) * 1000)];
        };
    } else {
        if ((_groupData get "waypoints") isNotEqualTo []) then {
            _virtStats set ["movementPauseSkipsTotal", (_virtStats get "movementPauseSkipsTotal") + 1];
            _virtStats set ["movementPauseSkipsThisBatch", (_virtStats get "movementPauseSkipsThisBatch") + 1];
        };
    };
};

if (_profilePhases) then { _phaseStart = diag_tickTime; };
[_groupId, _groupData, _groupActivationDist, _nearestDist, _forceVirtual, _missionLock, _replacementState, _inCombat, _virtStats] call FLO_fnc_virtualizationProcessActivationState;
if (_profilePhases) then {
    _virtStats set ["phaseActivationMsTotal", (_virtStats get "phaseActivationMsTotal") + ((diag_tickTime - _phaseStart) * 1000)];
};

_isActive = _groupData get "isActive";
_realGroup = _groupData get "realGroup";

if (_isActive && {!isNull _realGroup}) then {
    if (_profilePhases) then {
        _phaseStart = diag_tickTime;
        _virtStats set ["phaseActiveCallsTotal", (_virtStats get "phaseActiveCallsTotal") + 1];
    };
    [_groupId, _groupData, _realGroup, _tracksAssets, _replacementState, _nearestDist, _now, _virtStats] call FLO_fnc_virtualizationProcessActiveState;
    if (_profilePhases) then {
        _virtStats set ["phaseActiveMsTotal", (_virtStats get "phaseActiveMsTotal") + ((diag_tickTime - _phaseStart) * 1000)];
    };
};

