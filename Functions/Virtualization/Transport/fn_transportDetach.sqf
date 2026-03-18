/*
 * Function: FLO_fnc_transportDetach
 * Author: Frontline Operations Development Group
 * Description:
 *   Detach an infantry group from its transport.
 *   Offsets position to prevent unit stacking.
 *
 * Arguments:
 *   0: Infantry Group ID <STRING>
 *   1: Offset direction (degrees) <NUMBER> - Optional, default random
 *
 * Return Value:
 *   Success <BOOLEAN>
 *
 * Example:
 *   ["vgroup_123"] call FLO_fnc_transportDetach;
 *   ["vgroup_123", 90] call FLO_fnc_transportDetach;
 */

params [
    ["_infantryGroupId", "", [""]],
    ["_offsetDir", -1, [0]]
];

if (_infantryGroupId == "") exitWith { false };

if (isNil "FLO_virtualGroups") exitWith { false };

private _groups = FLO_virtualGroups get "_groups";
private _infData = _groups getOrDefault [_infantryGroupId, nil];

if (isNil "_infData") exitWith { false };

private _transportId = _infData getOrDefault ["attachedTo", ""];
if (_transportId == "") exitWith { false };

private _transData = _groups getOrDefault [_transportId, nil];

// Remove from transport's attached list
if (!isNil "_transData") then {
    private _attached = _transData getOrDefault ["attachedGroups", []];
    _attached = _attached - [_infantryGroupId];
    _transData set ["attachedGroups", _attached];
    
    if (count _attached == 0) then {
        _transData set ["isTransport", false];
    };
};

// Clear infantry attachment
_infData set ["attachedTo", ""];
_infData set ["attachedType", ""];

// Offset position from transport
private _pos = _infData get "position";
if (_offsetDir < 0) then { _offsetDir = random 360; };
private _newPos = _pos getPos [30, _offsetDir];
[FLO_virtualGroups, _infantryGroupId, _newPos] call (FLO_virtualGroups get "_updateGroupPosition");

["TRANSPORT", 3, format["Detached %1 from transport %2", _infantryGroupId, _transportId]] call FLO_fnc_log;

true
