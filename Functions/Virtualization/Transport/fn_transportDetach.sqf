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

private _groups = FLO_virtualGroups get "_groups";
private _infData = [_infantryGroupId] call FLO_fnc_transportGetTrackedGroup;

private _transportId = [_infData] call FLO_fnc_virtualizationGetTransportAttachment;
if (_transportId == "") exitWith { false };

private _transData = [_transportId] call FLO_fnc_transportGetTrackedGroup;
[_transData, _infantryGroupId] call FLO_fnc_virtualizationRemoveTransportPassenger;

// Clear infantry attachment
[_infData] call FLO_fnc_virtualizationClearTransportAttachment;
if ((_infData get "missionLock") == "ORGANIC_PACKAGE") then {
    [_infData] call FLO_fnc_virtualizationClearMissionLock;
};
[true] call FLO_fnc_gtnCombatMarkClassificationDirty;

// Offset position from transport
private _pos = _infData get "position";
if (_offsetDir < 0) then { _offsetDir = random 360; };
private _newPos = _pos getPos [30, _offsetDir];
[FLO_virtualGroups, _infantryGroupId, _newPos] call FLO_fnc_virtualizationUpdateGroupPosition;

["TRANSPORT", 3, format["Detached %1 from transport %2", _infantryGroupId, _transportId]] call FLO_fnc_log;

true
