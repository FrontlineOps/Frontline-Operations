/*
 * Function: FLO_fnc_virtualizationCaptureRealGroupPosition
 */

params ["_groupId", "_groupData", "_realGroup"];

private _leader = leader _realGroup;
if (isNull _leader || {!alive _leader}) exitWith { false };

private _anchor = vehicle _leader;
if (isNull _anchor) then {
    _anchor = _leader;
};

private _currentPos = getPos _anchor;
if ((_currentPos select 0) <= 100 && (_currentPos select 1) <= 100) exitWith {
    ["VIRTUALIZATION", 2, format ["WARNING: Invalid position %1 for group %2 - keeping original", _currentPos, _groupId]] call FLO_fnc_log;
    false
};

[FLO_virtualGroups, _groupId, _currentPos] call FLO_fnc_virtualizationUpdateGroupPosition;
["VIRTUALIZATION", 4, format ["Saved position %1 for group %2", _currentPos, _groupId]] call FLO_fnc_log;

true
