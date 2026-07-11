/*
 * Function: FLO_fnc_transportPrepareCarrierForPickup
 * Author: Frontline Operations Development Group
 * Description:
 *   Aligns a dedicated reserve carrier's activation state with the requesting
 *   passenger group before attachment.
 *
 * Arguments:
 *   0: Carrier group ID <STRING>
 *   1: Carrier group data <HASHMAP>
 *   2: Passenger group ID <STRING>
 *   3: Passenger group data <HASHMAP>
 *
 * Return Value:
 *   BOOL - True when the carrier is ready for attachment
 */

params [
    ["_carrierGroupId", "", [""]],
    ["_carrierData", createHashMap, [createHashMap]],
    ["_passengerGroupId", "", [""]],
    ["_passengerData", createHashMap, [createHashMap]]
];

if (_carrierGroupId == "" || {_passengerGroupId == ""}) exitWith { false };

private _carrierActive = _carrierData get "isActive";
private _passengerActive = _passengerData get "isActive";

if (_carrierActive == _passengerActive) exitWith { true };

if !(_carrierData get "transportRole") exitWith {
    ["TRANSPORT", 2, format [
        "Carrier prep failed: %1 is not a dedicated reserve carrier for passenger %2",
        _carrierGroupId,
        _passengerGroupId
    ]] call FLO_fnc_log;
    false
};

if (!_passengerActive) exitWith {
    ["TRANSPORT", 2, format [
        "Carrier prep failed: virtual passenger %1 cannot use active reserve carrier %2 yet",
        _passengerGroupId,
        _carrierGroupId
    ]] call FLO_fnc_log;
    false
};

["TRANSPORT", 3, format [
    "Activating reserve carrier %1 for active passenger %2",
    _carrierGroupId,
    _passengerGroupId
]] call FLO_fnc_log;

if !([_carrierGroupId] call FLO_fnc_virtualizationTryActivateGroup) exitWith {
    ["TRANSPORT", 2, format [
        "Carrier prep failed: could not activate reserve carrier %1 for passenger %2",
        _carrierGroupId,
        _passengerGroupId
    ]] call FLO_fnc_log;
    false
};

_carrierData = [_carrierGroupId] call FLO_fnc_transportGetTrackedGroup;
private _requiredSeats = _passengerData get "unitCount";
private _passengerRealGroup = _passengerData get "realGroup";
if (!isNull _passengerRealGroup) then {
    _requiredSeats = ({alive _x} count units _passengerRealGroup) max 0;
};

private _pickupCapacity = [_carrierData] call FLO_fnc_transportGetPickupCapacity;
if (_pickupCapacity < _requiredSeats) exitWith {
    ["TRANSPORT", 2, format [
        "Carrier prep failed: reserve carrier %1 has %2 live pickup seats for passenger %3 requiring %4",
        _carrierGroupId,
        _pickupCapacity,
        _passengerGroupId,
        _requiredSeats
    ]] call FLO_fnc_log;
    false
};

true
