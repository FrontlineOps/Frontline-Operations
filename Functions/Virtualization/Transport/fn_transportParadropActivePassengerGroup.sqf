/*
 * Function: FLO_fnc_transportParadropActivePassengerGroup
 * Author: Frontline Operations Development Group
 * Description:
 *   Ejects an active mounted infantry group from a live helicopter carrier
 *   through the engine parachute flow while clearing the canonical transport
 *   linkage.
 *
 * Arguments:
 *   0: Passenger group ID <STRING>
 *   1: Drop zone position <ARRAY>
 *   2: Carrier vehicles <ARRAY> - Optional
 *
 * Return Value:
 *   BOOL - True when the paradrop release was issued
 */

params [
    ["_passengerGroupId", "", [""]],
    ["_dropPos", [0, 0, 0], [[]]],
    ["_carrierVehicles", [], [[]]]
];

if (_passengerGroupId == "") exitWith { false };
if !([_dropPos, true, format [
    "transportParadropActivePassengerGroup passenger=%1",
    _passengerGroupId
]] call FLO_fnc_validateGroupPosition) exitWith {
    false
};

private _passengerData = [_passengerGroupId] call FLO_fnc_transportGetTrackedGroup;
private _carrierGroupId = [_passengerData] call FLO_fnc_virtualizationGetTransportAttachment;
if (_carrierGroupId == "") exitWith { false };

private _carrierData = [_carrierGroupId] call FLO_fnc_transportGetTrackedGroup;
private _passengerRealGroup = _passengerData get "realGroup";
if (isNull _passengerRealGroup) exitWith {
    ["TRANSPORT", 2, format [
        "Paradrop failed for %1 because the passenger group has no live realGroup",
        _passengerGroupId
    ]] call FLO_fnc_log;
    false
};

if (count _carrierVehicles == 0) then {
    private _carrierRealGroup = _carrierData get "realGroup";
    if (!isNull _carrierRealGroup) then {
        _carrierVehicles = ([_carrierRealGroup] call FLO_fnc_virtualizationCollectRealGroupVehicles) select { !isNull _x && {alive _x} };
    };
};

private _aliveUnits = units _passengerRealGroup select { alive _x };
[_carrierData, _passengerGroupId] call FLO_fnc_virtualizationRemoveTransportPassenger;
[_passengerData] call FLO_fnc_virtualizationClearTransportAttachment;
if ((_passengerData get "missionLock") == "TRANSPORT") then {
    [_passengerData] call FLO_fnc_virtualizationClearMissionLock;
};
if ((_passengerData get "mountedIn") == _carrierGroupId) then {
    [_passengerData] call FLO_fnc_virtualizationClearMountedIn;
};
[true] call FLO_fnc_gtnCombatMarkClassificationDirty;

private _dropAltitude = FLO_Transport_AirDropAltitude;
if (count _carrierVehicles > 0) then {
    private _carrierAlt = getPosATL (_carrierVehicles select 0) select 2;
    if (_carrierAlt > _dropAltitude) then {
        _dropAltitude = _carrierAlt;
    };
};

private _releasedCount = 0;
{
    private _unit = _x;
    private _veh = vehicle _unit;
    if (_veh != _unit && {_veh in _carrierVehicles}) then {
        unassignVehicle _unit;
        _unit action ["Eject", _veh];
        _releasedCount = _releasedCount + 1;
    };
} forEach _aliveUnits;

[FLO_virtualGroups, _passengerGroupId, _dropPos] call FLO_fnc_virtualizationUpdateGroupPosition;

["TRANSPORT", 3, format [
    "Paradropped active passenger group %1 from carrier %2 at %3 (%4 units, release altitude %5m)",
    _passengerGroupId,
    _carrierGroupId,
    _dropPos,
    _releasedCount,
    round _dropAltitude
]] call FLO_fnc_log;

_releasedCount > 0
