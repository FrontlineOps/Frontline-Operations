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

if ((_infData get "isActive") && {isNull (_infData get "realGroup")}) then {
    [_infantryGroupId, _infData] call FLO_fnc_virtualizationRepairOrphanedActiveGroup;
    _infData = [_infantryGroupId] call FLO_fnc_transportGetTrackedGroup;
};

if ((_transData get "isActive") && {isNull (_transData get "realGroup")}) then {
    [_transportGroupId, _transData] call FLO_fnc_virtualizationRepairOrphanedActiveGroup;
    _transData = [_transportGroupId] call FLO_fnc_transportGetTrackedGroup;
};

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
private _infIsActive = _infData get "isActive";
private _transIsActive = _transData get "isActive";

if (_infIsActive != _transIsActive && {_transData get "transportRole"} && {_infIsActive}) then {
    if ([_transportGroupId, _transData, _infantryGroupId, _infData] call FLO_fnc_transportPrepareCarrierForPickup) then {
        _transData = [_transportGroupId] call FLO_fnc_transportGetTrackedGroup;
        _groupType = _transData get "groupType";
        _capacity = [_transData] call FLO_fnc_transportGetGroupCapacity;
        _currentLoad = [_transData] call FLO_fnc_transportGetPassengerLoad;
        _transIsActive = _transData get "isActive";
    };
};

private _infUnitCount = _infData get "unitCount";
if (_currentLoad + _infUnitCount > _capacity) exitWith {
    ["TRANSPORT", 2, format["Attach failed: capacity exceeded (%1+%2 > %3)", 
        _currentLoad, _infUnitCount, _capacity]] call FLO_fnc_log;
    false
};

private _transportPos = _transData get "position";
if !([_transportPos, true, format [
    "transportAttach infantry=%1 transport=%2 transportType=%3",
    _infantryGroupId,
    _transportGroupId,
    _groupType
]] call FLO_fnc_validateGroupPosition) exitWith {
    false
};

if (_infIsActive != _transIsActive) exitWith {
    ["TRANSPORT", 2, format [
        "Attach failed: activation state mismatch for %1 (active=%2) and %3 (active=%4)",
        _infantryGroupId,
        _infIsActive,
        _transportGroupId,
        _transIsActive
    ]] call FLO_fnc_log;
    false
};

if (_infIsActive && {!([_infantryGroupId, _infData, _transportGroupId, _transData] call FLO_fnc_transportMountActivePassengerGroup)}) exitWith {
    ["TRANSPORT", 2, format [
        "Attach failed: could not coherently mount active passenger %1 into active carrier %2",
        _infantryGroupId,
        _transportGroupId
    ]] call FLO_fnc_log;
    false
};

// Perform attachment
[_infData, _transportGroupId, if (_groupType in ["helicopter"]) then {"AIR"} else {"GROUND"}] call FLO_fnc_virtualizationSetTransportAttachment;
[true] call FLO_fnc_gtnCombatMarkClassificationDirty;
[FLO_virtualGroups, _infantryGroupId, _transportPos] call FLO_fnc_virtualizationUpdateGroupPosition;

[_transData, _infantryGroupId] call FLO_fnc_virtualizationAddTransportPassenger;

["TRANSPORT", 3, format["Attached %1 (%2 units) to transport %3 (load: %4/%5)", 
    _infantryGroupId, _infUnitCount, _transportGroupId, _currentLoad + _infUnitCount, _capacity]] call FLO_fnc_log;

true
