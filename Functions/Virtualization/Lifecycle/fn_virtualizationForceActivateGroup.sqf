/*
 * Function: FLO_fnc_virtualizationForceActivateGroup
 * Author: Frontline Operations Development Group
 * Description:
 *   Activates a virtual group while bypassing the normal activation unit cap.
 *   This is reserved for always-on strategic assets that must exist as real
 *   entities regardless of the live-player activation budget.
 *
 * Arguments:
 * 0: Group ID <STRING>
 * 1: Group Data <HASHMAP>
 *
 * Return Value:
 * BOOL - True when activation succeeded
 */

params ["_groupId", "_groupData"];

if (_groupData get "isActive") exitWith {
    private _realGroup = _groupData get "realGroup";
    if (isNull _realGroup) then {
        ["VIRTUALIZATION", 2, format [
            "Force activation invariant violated for %1 (%2): active with null realGroup",
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
private _activated = [_groupId, _groupData] call FLO_fnc_activateVirtualGroup;

if (_activated) then {
    FLO_VirtUpdate set ["activeUnitCount", _activeUnitCount + _activationLoad];
};

_activated
