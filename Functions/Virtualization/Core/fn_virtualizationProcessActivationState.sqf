/*
 * Function: FLO_fnc_virtualizationProcessActivationState
 */

params ["_groupId", "_groupData", "_activationDist", "_nearestDist", "_forceVirtual", "_missionLock", "_replacementState", "_virtStats"];

private _isActive = _groupData get "isActive";

if (!_forceVirtual && {_nearestDist <= _activationDist} && {!_isActive}) exitWith {
    ["VIRTUALIZATION", 3, format["Activating %1 (dist: %2m)", _groupId, round _nearestDist]] call FLO_fnc_log;
    [_groupId, _groupData] call FLO_fnc_activateVirtualGroup;
    _virtStats set ["activationsTotal", (_virtStats get "activationsTotal") + 1];
    _virtStats set ["activationsThisBatch", (_virtStats get "activationsThisBatch") + 1];
    true
};

if (_nearestDist > _activationDist && {_isActive}) then {
    private _alwaysActive = _groupData get "alwaysActive";
    if ((_missionLock != "" && {_replacementState == ""}) || {_alwaysActive}) then {
        _virtStats set ["missionHoldSkipsTotal", (_virtStats get "missionHoldSkipsTotal") + 1];
        _virtStats set ["missionHoldSkipsThisBatch", (_virtStats get "missionHoldSkipsThisBatch") + 1];
    } else {
        ["VIRTUALIZATION", 3, format["Deactivating %1 (dist: %2m)", _groupId, round _nearestDist]] call FLO_fnc_log;
        [_groupId, _groupData] call FLO_fnc_deactivateVirtualGroup;
        _virtStats set ["deactivationsTotal", (_virtStats get "deactivationsTotal") + 1];
        _virtStats set ["deactivationsThisBatch", (_virtStats get "deactivationsThisBatch") + 1];
    };
};

true
