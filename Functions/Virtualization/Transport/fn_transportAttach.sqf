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

if (isNil "FLO_virtualGroups") exitWith {
    ["TRANSPORT", 1, "Attach failed: virtualization not initialized"] call FLO_fnc_log;
    false
};

private _groups = FLO_virtualGroups get "_groups";
private _infData = _groups getOrDefault [_infantryGroupId, nil];
private _transData = _groups getOrDefault [_transportGroupId, nil];

if (isNil "_infData" || isNil "_transData") exitWith {
    ["TRANSPORT", 2, format["Attach failed: group not found (inf: %1, trans: %2)", 
        _infantryGroupId, _transportGroupId]] call FLO_fnc_log;
    false
};

// Check if already attached
private _currentAttach = _infData getOrDefault ["attachedTo", ""];
if (_currentAttach != "") exitWith {
    ["TRANSPORT", 2, format["Attach failed: %1 already attached to %2", 
        _infantryGroupId, _currentAttach]] call FLO_fnc_log;
    false
};

// Get transport capacity
private _vehicleType = _transData getOrDefault ["vehicleType", ""];
private _groupType = _transData get "groupType";
private _capacity = if (_vehicleType != "") then {
    [_vehicleType] call FLO_fnc_transportGetCapacity
} else {
    [_groupType] call FLO_fnc_transportGetCapacity
};

// Calculate current load
private _attachedGroups = _transData getOrDefault ["attachedGroups", []];
private _currentLoad = 0;
{
    private _gData = _groups getOrDefault [_x, nil];
    if (!isNil "_gData") then {
        _currentLoad = _currentLoad + (_gData getOrDefault ["unitCount", 0]);
    };
} forEach _attachedGroups;

// Check capacity
private _infUnitCount = _infData getOrDefault ["unitCount", 4];
if (_currentLoad + _infUnitCount > _capacity) exitWith {
    ["TRANSPORT", 2, format["Attach failed: capacity exceeded (%1+%2 > %3)", 
        _currentLoad, _infUnitCount, _capacity]] call FLO_fnc_log;
    false
};

// Perform attachment
_infData set ["attachedTo", _transportGroupId];
_infData set ["attachedType", if (_groupType in ["helicopter"]) then {"AIR"} else {"GROUND"}];
_infData set ["position", _transData get "position"];

_attachedGroups pushBack _infantryGroupId;
_transData set ["attachedGroups", _attachedGroups];
_transData set ["isTransport", true];

["TRANSPORT", 3, format["Attached %1 (%2 units) to transport %3 (load: %4/%5)", 
    _infantryGroupId, _infUnitCount, _transportGroupId, _currentLoad + _infUnitCount, _capacity]] call FLO_fnc_log;

true
