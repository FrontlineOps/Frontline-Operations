/*
 * Function: FLO_fnc_transportParadropActivePassengerGroup
 * Author: Frontline Operations Development Group
 * Description:
 *   Ejects an active mounted infantry group from a live helicopter carrier by
 *   assigning each surviving soldier a parachute near the drop zone while
 *   clearing the canonical transport linkage.
 *
 * Arguments:
 *   0: Passenger group ID <STRING>
 *   1: Drop zone position <ARRAY>
 *   2: Carrier vehicles <ARRAY> - Optional
 *
 * Return Value:
 *   BOOL - True when the paradrop was executed
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

{
    private _unit = _x;
    private _veh = vehicle _unit;
    if (_veh != _unit && {_veh in _carrierVehicles}) then {
        unassignVehicle _unit;
        moveOut _unit;
    };

    private _spawnPos = [
        (_dropPos select 0) + (random 16) - 8,
        (_dropPos select 1) + (random 16) - 8,
        _dropAltitude
    ];

    private _parachute = createVehicle ["Steerable_Parachute_F", _spawnPos, [], 0, "FLY"];
    _parachute setPosATL _spawnPos;
    _parachute setDir random 360;
    _parachute setVelocity [0, 0, -2];
    _unit moveInDriver _parachute;
} forEach _aliveUnits;

[FLO_virtualGroups, _passengerGroupId, _dropPos] call FLO_fnc_virtualizationUpdateGroupPosition;

["TRANSPORT", 3, format [
    "Paradropped active passenger group %1 from carrier %2 at %3",
    _passengerGroupId,
    _carrierGroupId,
    _dropPos
]] call FLO_fnc_log;

true
