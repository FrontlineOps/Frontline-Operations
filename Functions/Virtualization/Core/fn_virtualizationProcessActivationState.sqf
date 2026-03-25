/*
 * Function: FLO_fnc_virtualizationProcessActivationState
 */

params ["_groupId", "_groupData", "_activationDist", "_nearestDist", "_forceVirtual", "_missionLock", "_replacementState", "_inCombat", "_virtStats"];

private _isActive = _groupData get "isActive";
private _activationDeferred = _groupData get "activationDeferred";
private _activationUnitCap = FLO_virtualGroups get "_activationUnitCap";
private _activationResumeCap = FLO_virtualGroups get "_activationResumeCap";
private _activeUnitCount = FLO_VirtUpdate get "activeUnitCount";
private _engagementActive = _groupData get "engagementActive";

if (_activationDeferred && {_nearestDist > (_activationDist + 10)}) then {
    _groupData set ["activationDeferred", false];
    _groupData set ["activationDeferredAt", -1];
    _groupData set ["activationDeferredPos", []];
    _activationDeferred = false;
};

if (!_forceVirtual && {_nearestDist <= _activationDist} && {!_isActive}) exitWith {
    private _bypassBudget = _inCombat || {_engagementActive} || {_missionLock != ""} || {_replacementState != ""};
    private _activationLoad = [_groupData, true] call FLO_fnc_virtualizationGetGroupUnitLoad;
    private _projectedUnitCount = _activeUnitCount + _activationLoad;
    private _blockActivation = false;

    if (!_bypassBudget) then {
        _blockActivation = _projectedUnitCount > _activationUnitCap;
        if (_activationDeferred && {_activeUnitCount >= _activationResumeCap}) then {
            _blockActivation = true;
        };
    };

    if (_blockActivation) then {
        private _deferredPos = [ _groupData get "position", _activationDist ] call FLO_fnc_virtualizationComputeDeferredActivationPos;
        [FLO_virtualGroups, _groupId, _deferredPos] call FLO_fnc_virtualizationUpdateGroupPosition;
        _groupData set ["activationDeferred", true];
        _groupData set ["activationDeferredAt", diag_tickTime];
        _groupData set ["activationDeferredPos", _deferredPos];
        _virtStats set ["activationBlocksTotal", (_virtStats get "activationBlocksTotal") + 1];
        _virtStats set ["activationBlocksThisBatch", (_virtStats get "activationBlocksThisBatch") + 1];
        _virtStats set ["deferredGroupsLast", (_virtStats get "deferredGroupsLast") + (if (_activationDeferred) then { 0 } else { 1 })];
        _virtStats set ["activeUnitsLast", _activeUnitCount];
    } else {
        ["VIRTUALIZATION", 3, format["Activating %1 (dist: %2m)", _groupId, round _nearestDist]] call FLO_fnc_log;
        [_groupId, _groupData] call FLO_fnc_activateVirtualGroup;
        FLO_VirtUpdate set ["activeUnitCount", _projectedUnitCount];
        _groupData set ["activationDeferred", false];
        _groupData set ["activationDeferredAt", -1];
        _groupData set ["activationDeferredPos", []];
        _virtStats set ["activationsTotal", (_virtStats get "activationsTotal") + 1];
        _virtStats set ["activationsThisBatch", (_virtStats get "activationsThisBatch") + 1];
        _virtStats set ["activeUnitsLast", FLO_VirtUpdate get "activeUnitCount"];
        _virtStats set ["deferredGroupsLast", ((_virtStats get "deferredGroupsLast") - (if (_activationDeferred) then { 1 } else { 0 })) max 0];
    };

    true
};

if (_nearestDist > _activationDist && {_isActive}) then {
    private _alwaysActive = _groupData get "alwaysActive";
    if ((_missionLock != "" && {_replacementState == ""}) || {_alwaysActive}) then {
        _virtStats set ["missionHoldSkipsTotal", (_virtStats get "missionHoldSkipsTotal") + 1];
        _virtStats set ["missionHoldSkipsThisBatch", (_virtStats get "missionHoldSkipsThisBatch") + 1];
    } else {
        private _deactivationLoad = [_groupData, true] call FLO_fnc_virtualizationGetGroupUnitLoad;
        ["VIRTUALIZATION", 3, format["Deactivating %1 (dist: %2m)", _groupId, round _nearestDist]] call FLO_fnc_log;
        [_groupId, _groupData] call FLO_fnc_deactivateVirtualGroup;
        FLO_VirtUpdate set ["activeUnitCount", ((_activeUnitCount - _deactivationLoad) max 0)];
        _virtStats set ["deactivationsTotal", (_virtStats get "deactivationsTotal") + 1];
        _virtStats set ["deactivationsThisBatch", (_virtStats get "deactivationsThisBatch") + 1];
        _virtStats set ["activeUnitsLast", FLO_VirtUpdate get "activeUnitCount"];
    };
};

true
