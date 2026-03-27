/*
 * Function: FLO_fnc_virtualizationTryActivateGroup
 */

params ["_groupId", "_groupData"];

if (_groupData get "isActive") exitWith { true };

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
