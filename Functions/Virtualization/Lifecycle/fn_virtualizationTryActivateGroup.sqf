/*
 * Function: FLO_fnc_virtualizationTryActivateGroup
 */

params ["_groupId", "_groupData"];

if (_groupData get "isActive") exitWith {
    private _realGroup = _groupData get "realGroup";
    if (isNull _realGroup) then {
        ["VIRTUALIZATION", 2, format [
            "Activation invariant violated for %1 (%2): group marked active with null realGroup",
            _groupId,
            _groupData get "groupType"
        ]] call FLO_fnc_log;
        false
    } else {
        true
    }
};

private _activeUnitCount = FLO_VirtUpdate get "activeUnitCount";
private _activationLoad = [_groupData, true] call FLO_fnc_virtualizationGetGroupUnitLoad;
private _activationUnitCap = FLO_virtualGroups get "_activationUnitCap";

if ((_activeUnitCount + _activationLoad) > _activationUnitCap) exitWith {
    ["VIRTUALIZATION", 3, format [
        "Activation blocked for %1 (%2): projected %3/%4",
        _groupId,
        _groupData get "groupType",
        _activeUnitCount + _activationLoad,
        _activationUnitCap
    ]] call FLO_fnc_log;
    false
};

private _activated = [_groupId, _groupData] call FLO_fnc_activateVirtualGroup;
if (_activated) then {
    FLO_VirtUpdate set ["activeUnitCount", _activeUnitCount + _activationLoad];
};

_activated
