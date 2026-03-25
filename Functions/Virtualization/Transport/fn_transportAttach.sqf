/*
 * Function: FLO_fnc_transportAttach
 * Author: Frontline Operations Development Group
 * Description:
 *   Attach an infantry group to a transport group.
 *   Validates capacity and updates both group data structures.
 *
 * Arguments:
 *   0: Infantry Group ID <STRING>
 *   1: Transport Group ID <STRING>
 *
 * Return Value:
 *   Success <BOOLEAN>
 *
 * Example:
 *   ["vgroup_123", "vgroup_456"] call FLO_fnc_transportAttach;
 */

params [
    ["_infantryGroupId", "", [""]],
    ["_transportGroupId", "", [""]]
];

if (_infantryGroupId == "" || _transportGroupId == "") exitWith { 
    ["TRANSPORT", 2, "Attach failed: empty group ID"] call FLO_fnc_log;
    false 
};

private _infData = [_infantryGroupId] call FLO_fnc_transportGetTrackedGroup;
private _transData = [_transportGroupId] call FLO_fnc_transportGetTrackedGroup;

// Check if already attached
private _currentAttach = [_infData] call FLO_fnc_virtualizationGetTransportAttachment;
if (_currentAttach != "") exitWith {
    ["TRANSPORT", 2, format["Attach failed: %1 already attached to %2", 
        _infantryGroupId, _currentAttach]] call FLO_fnc_log;
    false
};

private _groupType = _transData get "groupType";
private _capacity = [_transData] call FLO_fnc_transportGetGroupCapacity;
private _currentLoad = [_transData] call FLO_fnc_transportGetPassengerLoad;

private _infUnitCount = _infData get "unitCount";
if (_currentLoad + _infUnitCount > _capacity) exitWith {
    ["TRANSPORT", 2, format["Attach failed: capacity exceeded (%1+%2 > %3)", 
        _currentLoad, _infUnitCount, _capacity]] call FLO_fnc_log;
    false
};

// Perform attachment
[_infData, _transportGroupId, if (_groupType in ["helicopter"]) then {"AIR"} else {"GROUND"}] call FLO_fnc_virtualizationSetTransportAttachment;
[true] call FLO_fnc_gtnCombatMarkClassificationDirty;
[FLO_virtualGroups, _infantryGroupId, _transData get "position"] call FLO_fnc_virtualizationUpdateGroupPosition;

[_transData, _infantryGroupId] call FLO_fnc_virtualizationAddTransportPassenger;

["TRANSPORT", 3, format["Attached %1 (%2 units) to transport %3 (load: %4/%5)", 
    _infantryGroupId, _infUnitCount, _transportGroupId, _currentLoad + _infUnitCount, _capacity]] call FLO_fnc_log;

true
