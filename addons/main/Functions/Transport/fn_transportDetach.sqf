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

private _infData = [_infantryGroupId] call FLO_fnc_transportGetTrackedGroup;

private _transportId = [_infData] call FLO_fnc_virtualizationGetTransportAttachment;
if (_transportId == "") exitWith { false };

private _transData = [_transportId] call FLO_fnc_transportGetTrackedGroup;
private _infRealGroup = _infData get "realGroup";
private _transRealGroup = _transData get "realGroup";
private _transportVehicles = if (!isNull _transRealGroup) then {
    [_transRealGroup] call FLO_fnc_virtualizationCollectRealGroupVehicles
} else {
    []
};
[_infantryGroupId] call FLO_fnc_virtualizationUnlinkTransportGroups;

if ((_infData get "missionLock") in ["ORGANIC_PACKAGE", "TRANSPORT"]) then {
    [_infantryGroupId, createHashMapFromArray [
        ["missionLock", ""],
        ["missionType", ""]
    ]] call FLO_fnc_virtualizationPatchGroup;
};

private _basePos = _infData get "position";
if (!isNull _infRealGroup) then {
    {
        private _veh = vehicle _x;
        if (_veh != _x && {_veh in _transportVehicles}) then {
            // Forced detach is the fallback path when live staged unload did not
            // complete or when transport state must be repaired immediately.
            unassignVehicle _x;
            moveOut _x;
        };
    } forEach units _infRealGroup;

    private _leader = leader _infRealGroup;
    if (!isNull _leader && {alive _leader}) then {
        _basePos = getPosATL _leader;
    };
};

// Offset position from transport
if (_offsetDir < 0) then { _offsetDir = random 360; };
private _newPos = _basePos getPos [30, _offsetDir];
[_infantryGroupId, _newPos] call FLO_fnc_virtualizationUpdateGroupPosition;

["TRANSPORT", 3, format["Detached %1 from transport %2", _infantryGroupId, _transportId]] call FLO_fnc_log;

true
